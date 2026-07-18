function Remove-JamfBuilding {
    <#
    .SYNOPSIS
        Deletes a building from Jamf Pro.
    .EXAMPLE
        Remove-JamfBuilding -Id 3
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
        if ($PSCmdlet.ShouldProcess("Building id $Id", 'Delete Jamf Pro building')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "api/v1/buildings/$Id" | Out-Null
        }
    }
}
