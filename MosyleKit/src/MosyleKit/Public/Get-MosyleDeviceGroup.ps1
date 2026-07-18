function Get-MosyleDeviceGroup {
    <#
    .SYNOPSIS
        Lists dynamic device groups from Mosyle (POST /listdevicegroups).
    .PARAMETER Os
        Platform: ios, mac, tvos or visionos. Required.
    .PARAMETER SecurityGroup
        List security groups instead of standard device groups.
    .EXAMPLE
        Get-MosyleDeviceGroup -Os ios
    .EXAMPLE
        Get-MosyleDeviceGroup -Os mac -SecurityGroup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('ios', 'mac', 'tvos', 'visionos')]
        [string] $Os,

        [int] $Page,

        [switch] $SecurityGroup,

        [hashtable] $Options,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    $requestOptions = @{}
    if ($null -ne $Options) { foreach ($k in $Options.Keys) { $requestOptions[$k] = $Options[$k] } }
    $requestOptions['os'] = $Os
    if ($PSBoundParameters.ContainsKey('Page')) { $requestOptions['page'] = $Page }
    if ($SecurityGroup) { $requestOptions['is_security_group'] = 1 }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listdevicegroups' -Body @{ options = $requestOptions }
    Select-MosyleResult -Response $response -Property 'groups'
}
