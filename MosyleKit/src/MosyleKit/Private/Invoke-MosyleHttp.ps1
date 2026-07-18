function Invoke-MosyleHttp {
    <#
    .SYNOPSIS
        The single HTTP seam for the module. Every network call goes through here.
    .DESCRIPTION
        Thin wrapper around Invoke-WebRequest that returns a normalized result with
        StatusCode, Headers and Content. Uses Invoke-WebRequest (not -RestMethod)
        because Mosyle's /login returns the Bearer token in a RESPONSE HEADER, which
        we must read. Never throws on HTTP error status; retry/error-shaping live in
        Invoke-MosyleRequest, keeping this trivially mockable in tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri] $Uri,

        [hashtable] $Headers,

        [Parameter(Mandatory)]
        [string] $Body,

        [int] $TimeoutSec = 300
    )

    $params = @{
        Uri                = $Uri
        Method             = 'POST'
        Body               = $Body
        ContentType        = 'application/json'
        SkipHttpErrorCheck = $true
        TimeoutSec         = $TimeoutSec
        ErrorAction        = 'Stop'
    }
    if ($null -ne $Headers -and $Headers.Count -gt 0) { $params['Headers'] = $Headers }

    $response = Invoke-WebRequest @params

    $content = $null
    if ($response.Content) {
        try { $content = $response.Content | ConvertFrom-Json }
        catch { $content = $response.Content }
    }

    [pscustomobject]@{
        StatusCode = [int]$response.StatusCode
        Headers    = $response.Headers
        Content    = $content
    }
}
