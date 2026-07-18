function Disconnect-Mosyle {
    <#
    .SYNOPSIS
        Clears the module's default Mosyle session and its cached credential.
    .DESCRIPTION
        Mosyle JWTs cannot be actively invalidated (they simply expire in 24h); this
        drops the cached token, access token and credential from the PowerShell session.
    .EXAMPLE
        Disconnect-Mosyle
    #>
    [CmdletBinding()]
    param(
        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $target = if ($null -ne $Session) { $Session } else { $script:DefaultMosyleSession }
    if ($null -eq $target) {
        Write-Verbose 'No active Mosyle session to disconnect.'
        return
    }

    $target.Token = $null
    $target.TokenExpiry = [DateTimeOffset]::MinValue
    $target.Credential = $null
    $target.AccessToken = $null

    if ($script:DefaultMosyleSession -eq $target) {
        $script:DefaultMosyleSession = $null
    }
}
