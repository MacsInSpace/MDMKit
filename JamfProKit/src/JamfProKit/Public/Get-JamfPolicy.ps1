function Get-JamfPolicy {
    <#
    .SYNOPSIS
        Gets policies from the Classic API.
    .DESCRIPTION
        Policies live only on the Classic API. Reads request JSON (the Classic API
        serves both); writes elsewhere in this module use XML as required.
    .EXAMPLE
        Get-JamfPolicy
    .EXAMPLE
        Get-JamfPolicy -Id 42
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [int] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path "JSSResource/policies/id/$Id").policy
            }
            'Name' {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path "JSSResource/policies/name/$([uri]::EscapeDataString($Name))").policy
            }
            default {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path 'JSSResource/policies').policies
            }
        }
    }
}
