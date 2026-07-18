function Set-JamfScript {
    <#
    .SYNOPSIS
        Updates an existing script in Jamf Pro.
    .DESCRIPTION
        Fetches the current script record, overlays only the properties you supply,
        and PUTs the merged object back — so unspecified fields are preserved.
    .EXAMPLE
        Set-JamfScript -Id 12 -ScriptContents (Get-Content ./reset-dock.sh -Raw)
    .EXAMPLE
        Get-JamfScript -Name 'Reset Dock' | Set-JamfScript -Priority BEFORE
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name,

        [string] $ScriptContents,

        [string] $Info,

        [string] $Notes,

        [ValidateSet('BEFORE', 'AFTER', 'AT_REBOOT')]
        [string] $Priority,

        [string] $CategoryId,

        [string] $OsRequirements,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $updatableParams = 'Name', 'ScriptContents', 'Info', 'Notes', 'Priority', 'CategoryId', 'OsRequirements'
    }

    process {
        $current = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/scripts/$Id"
        $body = @{}
        foreach ($property in $current.PSObject.Properties) {
            $body[$property.Name] = $property.Value
        }

        foreach ($paramName in $updatableParams) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                # API property names are camelCase versions of the parameter names.
                $apiName = $paramName.Substring(0, 1).ToLowerInvariant() + $paramName.Substring(1)
                $body[$apiName] = $PSBoundParameters[$paramName]
            }
        }

        if ($PSCmdlet.ShouldProcess("$($body['name']) (id $Id)", 'Update Jamf Pro script')) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "api/v1/scripts/$Id" -Body $body
        }
    }
}
