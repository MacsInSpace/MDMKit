function Get-JamfPackage {
    <#
    .SYNOPSIS
        Gets package records from the Jamf Pro API (v1/packages, Jamf Pro 11.5+).
    .EXAMPLE
        Get-JamfPackage
    .EXAMPLE
        Get-JamfPackage -FileName 'Firefox-128.0.pkg'
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'FileName')]
        [string] $FileName,

        [Parameter(ParameterSetName = 'List')]
        [string] $Filter,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/packages/$Id"
            }
            'Name' {
                $escaped = $Name -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/packages' -Filter ('packageName=="{0}"' -f $escaped)
            }
            'FileName' {
                $escaped = $FileName -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/packages' -Filter ('fileName=="{0}"' -f $escaped)
            }
            default {
                $params = @{ Session = $resolved; Path = 'api/v1/packages' }
                if ($Filter) { $params['Filter'] = $Filter }
                Get-JamfPagedResult @params
            }
        }
    }
}
