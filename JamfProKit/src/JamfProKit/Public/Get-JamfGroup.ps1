function Get-JamfGroup {
    <#
    .SYNOPSIS
        Gets computer, mobile device or user groups (smart and static) from the
        Classic API.
    .DESCRIPTION
        Without -Id/-Name, returns the group list (id, name, is_smart). With -Id or
        -Name, returns the full group including criteria and membership.
    .EXAMPLE
        Get-JamfGroup
    .EXAMPLE
        Get-JamfGroup -Type MobileDevice -Id 12
    .EXAMPLE
        Get-JamfGroup -Name 'All Managed Laptops'
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [int] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type = 'Computer',

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $config = Get-JamfGroupTypeConfig -Type $Type
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path "JSSResource/$($config.Endpoint)/id/$Id").($config.Root)
            }
            'Name' {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path "JSSResource/$($config.Endpoint)/name/$([uri]::EscapeDataString($Name))").($config.Root)
            }
            default {
                (Invoke-JamfRequest -Session $resolved -Method GET -Path "JSSResource/$($config.Endpoint)").($config.ListProperty)
            }
        }
    }
}
