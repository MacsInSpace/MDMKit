function Remove-MosyleCustomAttribute {
    <#
    .SYNOPSIS
        Deletes a custom device attribute entirely
        (POST /customdeviceattribute, operation "delete_custom_device_attribute").
    .DESCRIPTION
        Removes the attribute definition (and its values) across the platform. To only
        unassign it from specific devices, use Invoke-MosyleApi with the
        remove_custom_device_attributes operation.
    .EXAMPLE
        Remove-MosyleCustomAttribute -Os mac -UniqueId assetOwner
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ios', 'tvos', 'mac', 'visionos')]
        [string] $Os,

        [Parameter(Mandatory, Position = 0)]
        [Alias('unique_id')]
        [string] $UniqueId,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    if ($PSCmdlet.ShouldProcess("$UniqueId ($Os)", 'Delete custom device attribute')) {
        # Note: the delete operation is singular ("...attribute") unlike the plural
        # create/assign operations — a documented Mosyle quirk.
        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'customdeviceattribute' -Body @{
            elements = @([ordered]@{
                    operation = 'delete_custom_device_attribute'
                    os        = $Os
                    unique_id = $UniqueId
                })
        }
        Select-MosyleResult -Response $response -Property 'response'
    }
}
