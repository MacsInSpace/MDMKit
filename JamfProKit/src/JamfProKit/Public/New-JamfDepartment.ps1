function New-JamfDepartment {
    <#
    .SYNOPSIS
        Creates a department in Jamf Pro.
    .EXAMPLE
        New-JamfDepartment -Name 'Finance'
    .EXAMPLE
        (Import-Csv departments.csv).Name | ForEach-Object { New-JamfDepartment -Name $_ }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Create Jamf Pro department')) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v1/departments' -Body @{ name = $Name }
            Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/departments/$($response.id)"
        }
    }
}
