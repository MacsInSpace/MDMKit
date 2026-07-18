function Get-JamfProVersion {
    <#
    .SYNOPSIS
        Returns the Jamf Pro server version. Also a handy connectivity smoke test.
    .EXAMPLE
        Get-JamfProVersion
    #>
    [CmdletBinding()]
    param(
        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    (Invoke-JamfRequest -Session $resolved -Method GET -Path 'api/v1/jamf-pro-version').version
}
