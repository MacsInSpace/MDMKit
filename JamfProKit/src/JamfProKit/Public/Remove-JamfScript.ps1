function Remove-JamfScript {
    <#
    .SYNOPSIS
        Deletes a script from Jamf Pro.
    .EXAMPLE
        Remove-JamfScript -Id 12
    .EXAMPLE
        Get-JamfScript -Name 'Obsolete Script' | Remove-JamfScript -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess("Script id $Id", 'Delete Jamf Pro script')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "api/v1/scripts/$Id" | Out-Null
        }
    }
}
