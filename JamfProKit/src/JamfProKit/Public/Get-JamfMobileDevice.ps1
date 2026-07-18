function Get-JamfMobileDevice {
    <#
    .SYNOPSIS
        Gets mobile device records from the Jamf Pro API.
    .DESCRIPTION
        Lists all mobile devices (paged automatically) or fetches one by -Id (full
        detail via /api/v2/mobile-devices/{id}/detail) or -SerialNumber.
    .EXAMPLE
        Get-JamfMobileDevice
    .EXAMPLE
        Get-JamfMobileDevice -SerialNumber F9FXH12ABC
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Serial', ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Mobile Device Serial', 'serial_number')]
        [string] $SerialNumber,

        [Parameter(ParameterSetName = 'List')]
        [string] $Filter,

        [Parameter(ParameterSetName = 'List')]
        [int] $First = 0,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v2/mobile-devices/$Id/detail"
            }
            'Serial' {
                $escaped = $SerialNumber -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v2/mobile-devices' `
                    -Filter ('serialNumber=="{0}"' -f $escaped)
            }
            default {
                $params = @{
                    Session = $resolved
                    Path    = 'api/v2/mobile-devices'
                    First   = $First
                }
                if ($Filter) { $params['Filter'] = $Filter }
                Get-JamfPagedResult @params
            }
        }
    }
}
