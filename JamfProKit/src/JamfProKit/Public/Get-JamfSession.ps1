function Get-JamfSession {
    <#
    .SYNOPSIS
        Returns the current default Jamf Pro session, if connected.
    .EXAMPLE
        Get-JamfSession
    #>
    [CmdletBinding()]
    param()

    $script:DefaultJamfSession
}
