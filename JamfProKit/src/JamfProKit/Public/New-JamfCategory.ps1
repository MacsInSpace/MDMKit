function New-JamfCategory {
    <#
    .SYNOPSIS
        Creates a category in Jamf Pro.
    .PARAMETER Priority
        Display priority 1-20 (lower shows first in Self Service); Jamf's default is 9.
    .EXAMPLE
        New-JamfCategory -Name 'Security Tools'
    .EXAMPLE
        'Browsers','Utilities','Security' | ForEach-Object { New-JamfCategory -Name $_ }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, 20)]
        [int] $Priority = 9,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Create Jamf Pro category')) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v1/categories' -Body @{
                name     = $Name
                priority = $Priority
            }
            Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/categories/$($response.id)"
        }
    }
}
