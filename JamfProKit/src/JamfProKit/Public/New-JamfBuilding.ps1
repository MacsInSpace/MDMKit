function New-JamfBuilding {
    <#
    .SYNOPSIS
        Creates a building in Jamf Pro.
    .EXAMPLE
        New-JamfBuilding -Name 'HQ' -City 'Melbourne' -Country 'Australia'
    .EXAMPLE
        Import-Csv buildings.csv | New-JamfBuilding
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $StreetAddress1 = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $StreetAddress2 = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $City = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $StateProvince = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ZipPostalCode = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Country = '',

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Create Jamf Pro building')) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v1/buildings' -Body @{
                name           = $Name
                streetAddress1 = $StreetAddress1
                streetAddress2 = $StreetAddress2
                city           = $City
                stateProvince  = $StateProvince
                zipPostalCode  = $ZipPostalCode
                country        = $Country
            }
            Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/buildings/$($response.id)"
        }
    }
}
