function Get-JamfComputer {
    <#
    .SYNOPSIS
        Gets computer inventory records from the Jamf Pro API.
    .DESCRIPTION
        Lists all computers (paged automatically, streamed to the pipeline), or fetches
        one by -Id (full detail), -SerialNumber or -Name. Supports RSQL -Filter and
        -Section to control which inventory sections are returned.
    .PARAMETER Section
        Inventory sections to include, e.g. GENERAL, HARDWARE, USER_AND_LOCATION,
        OPERATING_SYSTEM, EXTENSION_ATTRIBUTES, ALL. Defaults to the server default
        (GENERAL) for lists.
    .PARAMETER Filter
        RSQL filter, e.g. 'general.lastContactTime<2026-01-01' or
        'operatingSystem.version=ge=15.0'.
    .EXAMPLE
        Get-JamfComputer
    .EXAMPLE
        Get-JamfComputer -SerialNumber C02ABC123XYZ -Section ALL
    .EXAMPLE
        Get-JamfComputer -Filter 'operatingSystem.version=lt=15.0' -Section GENERAL,OPERATING_SYSTEM
    .EXAMPLE
        Import-Csv serials.csv | Get-JamfComputer
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Serial', ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Computer Serial', 'serial_number')]
        [string] $SerialNumber,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

        [Parameter(ParameterSetName = 'List')]
        [string] $Filter,

        [Parameter(ParameterSetName = 'List')]
        [string[]] $Sort,

        [Parameter(ParameterSetName = 'List')]
        [int] $First = 0,

        [string[]] $Section,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $sectionQuery = @{}
        if ($null -ne $Section -and $Section.Count -gt 0) {
            $sectionQuery['section'] = @($Section | ForEach-Object { $_.ToUpperInvariant() })
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/computers-inventory-detail/$Id"
            }
            'Serial' {
                $escaped = $SerialNumber -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/computers-inventory' `
                    -Filter ('hardware.serialNumber=="{0}"' -f $escaped) -Query $sectionQuery
            }
            'Name' {
                $escaped = $Name -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/computers-inventory' `
                    -Filter ('general.name=="{0}"' -f $escaped) -Query $sectionQuery
            }
            default {
                $params = @{
                    Session = $resolved
                    Path    = 'api/v1/computers-inventory'
                    Query   = $sectionQuery
                    First   = $First
                }
                if ($Filter) { $params['Filter'] = $Filter }
                if ($null -ne $Sort -and $Sort.Count -gt 0) { $params['Sort'] = $Sort }
                Get-JamfPagedResult @params
            }
        }
    }
}
