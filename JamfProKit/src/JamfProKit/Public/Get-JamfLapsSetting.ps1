function Get-JamfLapsSetting {
    <#
    .SYNOPSIS
        Gets the instance-wide LAPS settings (GET /api/v2/local-admin-password/settings).
    .EXAMPLE
        Get-JamfLapsSetting
    #>
    [CmdletBinding()]
    param(
        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    Invoke-JamfRequest -Session $resolved -Method GET -Path 'api/v2/local-admin-password/settings'
}
