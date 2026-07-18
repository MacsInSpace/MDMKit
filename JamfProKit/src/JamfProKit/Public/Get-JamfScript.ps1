function Get-JamfScript {
    <#
    .SYNOPSIS
        Gets scripts from the Jamf Pro API.
    .EXAMPLE
        Get-JamfScript
    .EXAMPLE
        Get-JamfScript -Name 'Reset Dock'
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

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
                Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/scripts/$Id"
            }
            'Name' {
                $escaped = $Name -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/scripts' -Filter ('name=="{0}"' -f $escaped)
            }
            default {
                $params = @{ Session = $resolved; Path = 'api/v1/scripts' }
                if ($Filter) { $params['Filter'] = $Filter }
                Get-JamfPagedResult @params
            }
        }
    }
}
