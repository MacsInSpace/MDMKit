function Invoke-JamfHttp {
    <#
    .SYNOPSIS
        The single HTTP seam for the module. Every network call goes through here.
    .DESCRIPTION
        Thin wrapper around Invoke-RestMethod that never throws on HTTP error status
        codes; instead it returns a normalized result object with StatusCode, Headers
        and Content. All retry, auth-refresh and error-shaping logic lives in
        Invoke-JamfRequest, which keeps this function trivially mockable in tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri] $Uri,

        [Parameter(Mandatory)]
        [string] $Method,

        [hashtable] $Headers,

        [object] $Body,

        [string] $ContentType,

        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [pscredential] $Credential,

        [int] $TimeoutSec = 300
    )

    $statusCode = 0
    $responseHeaders = $null

    $params = @{
        Uri                     = $Uri
        Method                  = $Method
        SkipHttpErrorCheck      = $true
        StatusCodeVariable      = 'statusCode'
        ResponseHeadersVariable = 'responseHeaders'
        TimeoutSec              = $TimeoutSec
        ErrorAction             = 'Stop'
    }
    if ($null -ne $Headers -and $Headers.Count -gt 0) { $params['Headers'] = $Headers }
    if ($null -ne $Body) { $params['Body'] = $Body }
    if ($ContentType) { $params['ContentType'] = $ContentType }
    if ($null -ne $WebSession) { $params['WebSession'] = $WebSession }
    if ($null -ne $Credential) {
        $params['Credential'] = $Credential
        $params['Authentication'] = 'Basic'
    }

    $content = Invoke-RestMethod @params

    [pscustomobject]@{
        StatusCode = [int]$statusCode
        Headers    = $responseHeaders
        Content    = $content
    }
}
