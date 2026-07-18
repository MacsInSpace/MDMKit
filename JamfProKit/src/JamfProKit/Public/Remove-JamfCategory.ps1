function Remove-JamfCategory {
    <#
    .SYNOPSIS
        Deletes a category from Jamf Pro.
    .EXAMPLE
        Remove-JamfCategory -Id 5
    .EXAMPLE
        Get-JamfCategory -Name 'Obsolete' | Remove-JamfCategory -Confirm:$false
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
        if ($PSCmdlet.ShouldProcess("Category id $Id", 'Delete Jamf Pro category')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "api/v1/categories/$Id" | Out-Null
        }
    }
}
