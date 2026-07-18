function Set-MosyleCustomAttribute {
    <#
    .SYNOPSIS
        Sets (assigns) a custom device attribute value on devices
        (POST /customdeviceattribute, operation "assign_custom_device_attributes").
    .DESCRIPTION
        Updates the value of an existing custom device attribute for the given devices.
        (To rename an attribute's unique_id, or delete it entirely, use Invoke-MosyleApi
        with the update_/delete_ operations.)
    .EXAMPLE
        Set-MosyleCustomAttribute -Os mac -UniqueId assetOwner -Value 'Science Dept' -Device $udid1, $udid2
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ios', 'tvos', 'mac', 'visionos')]
        [string] $Os,

        [Parameter(Mandatory, Position = 0)]
        [Alias('unique_id')]
        [string] $UniqueId,

        [Parameter(Mandatory)]
        [string] $Value,

        [Parameter(Mandatory)]
        [Alias('UDID', 'devices')]
        [string[]] $Device,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    if ($PSCmdlet.ShouldProcess("$UniqueId on $(@($Device).Count) device(s)", 'Assign custom device attribute value')) {
        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'customdeviceattribute' -Body @{
            elements = @([ordered]@{
                    operation = 'assign_custom_device_attributes'
                    os        = $Os
                    unique_id = $UniqueId
                    value     = $Value
                    devices   = @($Device)
                })
        }
        Select-MosyleResult -Response $response -Property 'response'
    }
}
