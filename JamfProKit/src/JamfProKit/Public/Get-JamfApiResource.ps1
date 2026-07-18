function Get-JamfApiResource {
    <#
    .SYNOPSIS
        Lists the Jamf Pro API resources your instance exposes to the spec-driven
        cmdlets (Get/New/Set/Remove-JamfObject).
    .DESCRIPTION
        Built from the instance's live /api/schema, so this is exactly what YOUR
        Jamf Pro version offers — including endpoints added after this module
        shipped. Refresh with -Refresh after a Jamf Pro upgrade mid-session.
    .EXAMPLE
        Get-JamfApiResource
    .EXAMPLE
        Get-JamfApiResource -Name '*enrollment*'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [string] $Name = '*',

        [switch] $Refresh,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    $index = Get-JamfApiIndex -Session $resolved -Refresh:$Refresh
    $resources = $index['resources']

    foreach ($resourceName in ($resources.Keys | Where-Object { $_ -like $Name } | Sort-Object)) {
        $versions = $resources[$resourceName]
        $operations = foreach ($version in ($versions.Keys | Sort-Object { [int]($_.Substring(1)) })) {
            foreach ($operationName in ($versions[$version].Keys | Sort-Object)) {
                $suffix = if ($versions[$version][$operationName]['deprecated']) { ' (deprecated)' } else { '' }
                "$operationName [$version]$suffix"
            }
        }
        [pscustomobject]@{
            PSTypeName = 'JamfProKit.ApiResource'
            Resource   = $resourceName
            Versions   = @($versions.Keys | Sort-Object { [int]($_.Substring(1)) })
            Operations = $operations -join ', '
        }
    }
}
