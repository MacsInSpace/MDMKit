function Set-JamfDepartment {
    <#
    .SYNOPSIS
        Renames a department in Jamf Pro.
    .EXAMPLE
        Set-JamfDepartment -Id 7 -Name 'Finance & Payroll'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, Position = 1)]
        [string] $Name,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess("Department id $Id", "Rename to '$Name'")) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "api/v1/departments/$Id" -Body @{ name = $Name }
        }
    }
}
