function Invoke-MosyleRequest {
    <#
    .SYNOPSIS
        Hardened request pipeline used by every cmdlet in the module.
    .DESCRIPTION
        Responsibilities:
          - Ensures the session JWT is fresh (re-logs in inside the expiry buffer).
          - Injects accessToken into the request body (Mosyle requires it in the body
            of every call) and the Authorization header on non-login endpoints.
          - Serializes the body to JSON; every Mosyle call is POST.
          - Retries 429 and transient 5xx with backoff, honoring Retry-After.
          - Refreshes the token once and retries on 401/403.
          - Surfaces Mosyle's {status:"ERROR", ...} bodies as errors even on HTTP 200.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('MosyleKit.Session')]
        [object] $Session,

        # Endpoint under /v2, e.g. 'listusers' or 'listdevices'.
        [Parameter(Mandatory)]
        [string] $Endpoint,

        # Extra body fields merged with accessToken (e.g. @{ options = @{ ... } }).
        [hashtable] $Body,

        [int] $TimeoutSec = 300,

        [int] $MaxRetries = 4
    )

    $uri = [uri]"$($Session.BaseUri)/$($Endpoint.TrimStart('/'))"
    $accessTokenPlain = ConvertFrom-SecureString -SecureString $Session.AccessToken -AsPlainText

    $attempt = 0
    $authRetried = $false
    try {
        while ($true) {
            Update-MosyleSessionToken -Session $Session
            $tokenHeader = ConvertFrom-SecureString -SecureString $Session.Token -AsPlainText

            $payload = @{ accessToken = $accessTokenPlain }
            if ($null -ne $Body) {
                foreach ($key in $Body.Keys) { $payload[$key] = $Body[$key] }
            }
            $json = ConvertTo-Json -InputObject $payload -Depth 32 -Compress

            Write-Verbose "POST $uri (attempt $($attempt + 1))"
            $result = Invoke-MosyleHttp -Uri $uri -Headers @{ Authorization = $tokenHeader } -Body $json -TimeoutSec $TimeoutSec

            if ($result.StatusCode -ge 200 -and $result.StatusCode -le 299) {
                return (Assert-MosyleResponse -Response $result.Content -Context "$Endpoint")
            }

            if ($result.StatusCode -in 401, 403 -and -not $authRetried) {
                $authRetried = $true
                Write-Verbose "HTTP $($result.StatusCode); forcing token renewal and retrying once."
                Update-MosyleSessionToken -Session $Session -Force
                continue
            }

            $retryable = $result.StatusCode -in 429, 500, 502, 503, 504
            if ($retryable -and $attempt -lt $MaxRetries) {
                $delaySeconds = [math]::Min([math]::Pow(2, $attempt), 30) + (Get-Random -Minimum 0.0 -Maximum 1.0)
                if ($null -ne $result.Headers -and $result.Headers.ContainsKey('Retry-After')) {
                    $retryAfter = 0
                    if ([int]::TryParse(@($result.Headers['Retry-After'])[0], [ref]$retryAfter)) {
                        $delaySeconds = [math]::Max($retryAfter, 1)
                    }
                }
                $attempt++
                Write-Verbose "HTTP $($result.StatusCode) from Mosyle; retrying in $([math]::Round($delaySeconds, 1))s ($attempt/$MaxRetries)."
                Start-Sleep -Seconds $delaySeconds
                continue
            }

            throw "Mosyle API request failed: POST $uri returned HTTP $($result.StatusCode)."
        }
    }
    finally {
        $accessTokenPlain = $null
    }
}

function Assert-MosyleResponse {
    <#
    .SYNOPSIS
        Surfaces Mosyle's in-body error responses (status ERROR) as terminating errors.
    #>
    [CmdletBinding()]
    param($Response, [string] $Context = 'Request')

    if ($null -ne $Response -and $Response -isnot [string]) {
        $statusMatch = $Response.PSObject.Properties.Match('status')
        if ($statusMatch.Count -gt 0 -and "$($statusMatch[0].Value)".ToUpperInvariant() -eq 'ERROR') {
            $msgParts = foreach ($name in 'message', 'error', 'errorCode') {
                $m = $Response.PSObject.Properties.Match($name)
                if ($m.Count -gt 0 -and $m[0].Value) { [string]$m[0].Value }
            }
            $detail = if ($msgParts) { ": $($msgParts -join ' — ')" } else { '' }
            throw "$Context returned an error$detail"
        }
    }
    return $Response
}
