function Set-JamfPackage {
    <#
    .SYNOPSIS
        Updates a package record in Jamf Pro. Only the properties you supply change.
    .EXAMPLE
        Set-JamfPackage -Id 12 -CategoryId 5 -Notes 'Deployed via wave 2'
    .EXAMPLE
        Get-JamfPackage -FileName 'Firefox-128.0.pkg' | Set-JamfPackage -Priority 5
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [string] $PackageName,

        [string] $FileName,

        [string] $CategoryId,

        [string] $Info,

        [string] $Notes,

        [ValidateRange(1, 20)]
        [int] $Priority,

        [string] $OsRequirements,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $updatableParams = 'PackageName', 'FileName', 'CategoryId', 'Info', 'Notes', 'Priority', 'OsRequirements'
    }

    process {
        $current = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/packages/$Id"
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

        if ($PSCmdlet.ShouldProcess("$($body['packageName']) (id $Id)", 'Update Jamf Pro package record')) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "api/v1/packages/$Id" -Body $body
        }
    }
}
