function Remove-JamfDepartment {
    <#
    .SYNOPSIS
        Deletes a department from Jamf Pro.
    .EXAMPLE
        Remove-JamfDepartment -Id 7
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
        if ($PSCmdlet.ShouldProcess("Department id $Id", 'Delete Jamf Pro department')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "api/v1/departments/$Id" | Out-Null
        }
    }
}
