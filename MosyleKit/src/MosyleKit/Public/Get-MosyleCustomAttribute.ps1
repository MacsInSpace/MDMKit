function Get-MosyleCustomAttribute {
    <#
    .SYNOPSIS
        Lists custom device attributes for a platform
        (POST /customdeviceattribute, operation "list_custom_device_attributes").
    .PARAMETER Os
        Platform: ios, tvos, mac or visionos. Required.
    .EXAMPLE
        Get-MosyleCustomAttribute -Os mac
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('ios', 'tvos', 'mac', 'visionos')]
        [string] $Os,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session
    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'customdeviceattribute' -Body @{
        elements = @([ordered]@{ operation = 'list_custom_device_attributes'; os = $Os })
    }
    Select-MosyleResult -Response $response -Property 'info'
}
