function Get-JamfDepartment {
    <#
    .SYNOPSIS
        Gets departments from the Jamf Pro API.
    .EXAMPLE
        Get-JamfDepartment
    .EXAMPLE
        Get-JamfDepartment -Name 'Finance'
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
                Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/departments/$Id"
            }
            'Name' {
                $escaped = $Name -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path 'api/v1/departments' -Filter ('name=="{0}"' -f $escaped)
            }
            default {
                $params = @{ Session = $resolved; Path = 'api/v1/departments' }
                if ($Filter) { $params['Filter'] = $Filter }
                Get-JamfPagedResult @params
            }
        }
    }
}
