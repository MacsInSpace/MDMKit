function Set-JamfBuilding {
    <#
    .SYNOPSIS
        Updates a building in Jamf Pro. Only the properties you supply change.
    .EXAMPLE
        Set-JamfBuilding -Id 3 -StreetAddress1 '1 New Campus Way'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [string] $Name,

        [string] $StreetAddress1,

        [string] $StreetAddress2,

        [string] $City,

        [string] $StateProvince,

        [string] $ZipPostalCode,

        [string] $Country,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $updatableParams = 'Name', 'StreetAddress1', 'StreetAddress2', 'City', 'StateProvince', 'ZipPostalCode', 'Country'
    }

    process {
        $current = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/buildings/$Id"
        $body = @{}
        foreach ($property in $current.PSObject.Properties) {
            $body[$property.Name] = $property.Value
        }
        foreach ($paramName in $updatableParams) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                $apiName = $paramName.Substring(0, 1).ToLowerInvariant() + $paramName.Substring(1)
                $body[$apiName] = $PSBoundParameters[$paramName]
            }
        }

        if ($PSCmdlet.ShouldProcess("$($body['name']) (id $Id)", 'Update Jamf Pro building')) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "api/v1/buildings/$Id" -Body $body
        }
    }
}
