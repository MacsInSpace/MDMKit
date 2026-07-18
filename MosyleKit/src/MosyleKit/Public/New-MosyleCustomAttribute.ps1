function New-MosyleCustomAttribute {
    <#
    .SYNOPSIS
        Creates a custom device attribute and sets it on devices
        (POST /customdeviceattribute, operation "create_custom_device_attributes").
    .PARAMETER UniqueId
        The attribute's unique identifier.
    .PARAMETER Device
        UDIDs the attribute value applies to.
    .EXAMPLE
        New-MosyleCustomAttribute -Os mac -UniqueId assetOwner -Name 'Asset Owner' -Value 'IT Dept' -Device $udid
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ios', 'tvos', 'mac', 'visionos')]
        [string] $Os,

        [Parameter(Mandatory, Position = 0)]
        [Alias('unique_id')]
        [string] $UniqueId,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value,

        [Parameter(Mandatory)]
        [Alias('UDID', 'devices')]
        [string[]] $Device,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    if ($PSCmdlet.ShouldProcess("$UniqueId ($Os)", 'Create custom device attribute')) {
        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'customdeviceattribute' -Body @{
            elements = @([ordered]@{
                    operation = 'create_custom_device_attributes'
                    os        = $Os
                    unique_id = $UniqueId
                    name      = $Name
                    value     = $Value
                    devices   = @($Device)
                })
        }
        Select-MosyleResult -Response $response -Property 'response'
    }
}
