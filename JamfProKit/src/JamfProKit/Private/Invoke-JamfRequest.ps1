function Invoke-JamfRequest {
    <#
    .SYNOPSIS
        Hardened request pipeline used by every cmdlet in the module.
    .DESCRIPTION
        Responsibilities:
          - Ensures the session token is fresh (renews inside the expiry buffer).
          - Builds the URI from the session base + relative path + query parameters.
          - Serializes hashtable/PSCustomObject bodies to JSON for Jamf Pro API calls;
            strings and XmlDocuments pass through for Classic API XML writes.
          - Retries on 429 and transient 5xx (502/503/504), honoring Retry-After and
            otherwise using exponential backoff with jitter.
          - Refreshes the token once and retries on 401.
          - Throws a normalized error (Jamf Pro API JSON error bodies parsed) on failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session,

        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string] $Method = 'GET',

        # Relative path, e.g. 'api/v1/computers-inventory' or 'JSSResource/policies/id/12'.
        [Parameter(Mandatory)]
        [string] $Path,

        [hashtable] $Query,

        [object] $Body,

        [string] $ContentType,

        [string] $Accept = 'application/json',

        [int] $MaxRetries = 4
    )

    $uriBuilder = [System.Text.StringBuilder]::new()
    [void]$uriBuilder.Append($Session.BaseUri).Append('/').Append($Path.TrimStart('/'))
    if ($null -ne $Query -and $Query.Count -gt 0) {
        $pairs = foreach ($key in $Query.Keys) {
            foreach ($value in @($Query[$key])) {
                '{0}={1}' -f [uri]::EscapeDataString([string]$key), [uri]::EscapeDataString([string]$value)
            }
        }
        [void]$uriBuilder.Append('?').Append($pairs -join '&')
    }
    $uri = [uri]$uriBuilder.ToString()

    # Serialize structured bodies for JSON endpoints. Strings/XmlDocuments pass through.
    $requestBody = $Body
    if ($null -ne $Body -and $Body -isnot [string] -and $Body -isnot [System.Xml.XmlDocument] -and $Body -isnot [byte[]]) {
        $requestBody = ConvertTo-Json -InputObject $Body -Depth 32 -Compress
        if (-not $ContentType) { $ContentType = 'application/json' }
    }
    elseif ($Body -is [System.Xml.XmlDocument]) {
        $requestBody = $Body.OuterXml
        if (-not $ContentType) { $ContentType = 'application/xml' }
    }

    $attempt = 0
    $authRetried = $false
    while ($true) {
        Update-JamfSessionToken -Session $Session
        $tokenPlain = ConvertFrom-SecureString -SecureString $Session.Token -AsPlainText
        try {
            $headers = @{
                Authorization = "Bearer $tokenPlain"
                Accept        = $Accept
            }
            Write-Verbose "$Method $uri (attempt $($attempt + 1))"
            $result = Invoke-JamfHttp -Uri $uri -Method $Method -Headers $headers `
                -Body $requestBody -ContentType $ContentType -WebSession $Session.WebSession
        }
        finally {
            $tokenPlain = $null
        }

        if ($result.StatusCode -ge 200 -and $result.StatusCode -le 299) {
            return $result.Content
        }

        if ($result.StatusCode -eq 401 -and -not $authRetried) {
            $authRetried = $true
            Write-Verbose 'Received 401; forcing a token renewal and retrying once.'
            Update-JamfSessionToken -Session $Session -Force
            continue
        }

        $retryable = $result.StatusCode -in 429, 502, 503, 504
        if ($retryable -and $attempt -lt $MaxRetries) {
            $delaySeconds = [math]::Min([math]::Pow(2, $attempt), 30) + (Get-Random -Minimum 0.0 -Maximum 1.0)
            if ($null -ne $result.Headers -and $result.Headers.ContainsKey('Retry-After')) {
                $retryAfter = 0
                if ([int]::TryParse(@($result.Headers['Retry-After'])[0], [ref]$retryAfter)) {
                    $delaySeconds = [math]::Max($retryAfter, 1)
                }
            }
            $attempt++
            Write-Verbose "HTTP $($result.StatusCode) from Jamf; retrying in $([math]::Round($delaySeconds, 1))s ($attempt/$MaxRetries)."
            Start-Sleep -Seconds $delaySeconds
            continue
        }

        throw (New-JamfApiError -Method $Method -Uri $uri -Result $result)
    }
}

function New-JamfApiError {
    <#
    .SYNOPSIS
        Builds a readable error message from a failed Jamf API response.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Builds an error message string; changes no state.')]
    param(
        [string] $Method,
        [uri] $Uri,
        [object] $Result
    )

    $detail = ''
    $content = $Result.Content
    if ($null -ne $content) {
        # Jamf Pro API errors: { httpStatus, errors: [ { code, description, field, id } ] }
        if ($content -is [System.Management.Automation.PSObject] -and $content.PSObject.Properties.Match('errors').Count -gt 0) {
            $parts = foreach ($apiError in @($content.errors)) {
                $fields = foreach ($name in 'code', 'field', 'description') {
                    if ($apiError.PSObject.Properties.Match($name).Count -gt 0 -and $null -ne $apiError.$name) {
                        [string]$apiError.$name
                    }
                }
                $fields -join ': '
            }
            $detail = $parts -join '; '
        }
        else {
            # Classic API failures come back as HTML; strip tags and keep it short.
            $text = ([string]$content) -replace '<[^>]+>', ' ' -replace '\s+', ' '
            $detail = $text.Trim()
            if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) + '…' }
        }
    }

    $message = "Jamf API request failed: $Method $Uri returned HTTP $($Result.StatusCode)."
    if ($detail) { $message += " $detail" }
    return $message
}
