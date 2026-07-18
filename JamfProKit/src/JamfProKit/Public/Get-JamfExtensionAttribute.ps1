function Get-JamfExtensionAttribute {
    <#
    .SYNOPSIS
        Gets computer or mobile device extension attributes from the Jamf Pro API.
    .EXAMPLE
        Get-JamfExtensionAttribute
    .EXAMPLE
        Get-JamfExtensionAttribute -Type MobileDevice -Name 'Battery Health'
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string] $Name,

        [ValidateSet('Computer', 'MobileDevice')]
        [string] $Type = 'Computer',

        [Parameter(ParameterSetName = 'List')]
        [string] $Filter,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $endpoint = if ($Type -eq 'Computer') { 'api/v1/computer-extension-attributes' } else { 'api/v1/mobile-device-extension-attributes' }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Id' {
                Invoke-JamfRequest -Session $resolved -Method GET -Path "$endpoint/$Id"
            }
            'Name' {
                $escaped = $Name -replace '"', ''
                Get-JamfPagedResult -Session $resolved -Path $endpoint -Filter ('name=="{0}"' -f $escaped)
            }
            default {
                $params = @{ Session = $resolved; Path = $endpoint }
                if ($Filter) { $params['Filter'] = $Filter }
                Get-JamfPagedResult @params
            }
        }
    }
}
