function Get-JamfObject {
    <#
    .SYNOPSIS
        Gets any Jamf Pro API resource, driven by your instance's live OpenAPI spec.
    .DESCRIPTION
        The spec-driven layer: on first use it fetches /api/schema from the connected
        instance, distills it into an index (cached on disk per host + Jamf Pro
        version), and routes requests from it. -Resource tab-completes once the index
        exists. The newest non-deprecated API version is used automatically; override
        with -ApiVersion. Paged list endpoints stream all results.

        Covers plain collection/item endpoints on the Jamf Pro API. Deeper
        sub-resources and the Classic API remain the domain of the typed cmdlets and
        Invoke-JamfApi.
    .EXAMPLE
        Get-JamfObject enrollment-customizations
    .EXAMPLE
        Get-JamfObject webhooks -Id 5
    .EXAMPLE
        Get-JamfObject app-installers -Filter 'name=="Chrome"' -ApiVersion v1
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Resource,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(ParameterSetName = 'List')]
        [string] $Filter,

        [Parameter(ParameterSetName = 'List')]
        [string[]] $Sort,

        [Parameter(ParameterSetName = 'List')]
        [int] $First = 0,

        [hashtable] $Query,

        [string] $ApiVersion,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $index = Get-JamfApiIndex -Session $resolved
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Id') {
            $operation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation get -ApiVersion $ApiVersion
            $path = Set-JamfPathIdentifier -Path $operation['path'] -Id $Id
            return Invoke-JamfRequest -Session $resolved -Method GET -Path $path -Query $Query
        }

        $operation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation list -ApiVersion $ApiVersion
        if ($operation['paged']) {
            $params = @{
                Session = $resolved
                Path    = $operation['path']
                First   = $First
            }
            if ($Filter) { $params['Filter'] = $Filter }
            if ($null -ne $Sort -and $Sort.Count -gt 0) { $params['Sort'] = $Sort }
            if ($null -ne $Query) { $params['Query'] = $Query }
            Get-JamfPagedResult @params
        }
        else {
            if ($Filter -or ($null -ne $Sort -and $Sort.Count -gt 0)) {
                Write-Warning "The $($operation['version']) $Resource endpoint is not paged; -Filter/-Sort are ignored."
            }
            Invoke-JamfRequest -Session $resolved -Method GET -Path $operation['path'] -Query $Query
        }
    }
}
