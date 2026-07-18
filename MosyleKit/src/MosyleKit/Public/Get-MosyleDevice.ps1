function Get-MosyleDevice {
    <#
    .SYNOPSIS
        Lists devices from Mosyle (POST /listdevices).
    .DESCRIPTION
        Returns the device list. -Os narrows to a platform, -Column restricts returned
        fields, and -Options passes any other documented list options straight through.

        Note: the exact set of documented list options for /listdevices was not
        confirmed against the API docs when this cmdlet was written; -Options is the
        pass-through for anything beyond -Os/-Column.
    .PARAMETER Os
        Platform filter: ios, mac, tvos.
    .PARAMETER Column
        Specific columns to return.
    .EXAMPLE
        Get-MosyleDevice
    .EXAMPLE
        Get-MosyleDevice -Os ios -Column serial_number, device_name, total_disk
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('ios', 'mac', 'tvos')]
        [string] $Os,

        [string[]] $Column,

        [hashtable] $Options,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    $requestOptions = @{}
    if ($null -ne $Options) {
        foreach ($key in $Options.Keys) { $requestOptions[$key] = $Options[$key] }
    }
    if ($Os) { $requestOptions['os'] = $Os }
    if ($null -ne $Column -and $Column.Count -gt 0) { $requestOptions['specific_columns'] = @($Column) }

    $body = @{}
    if ($requestOptions.Count -gt 0) { $body['options'] = $requestOptions }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listdevices' -Body $body
    Select-MosyleResult -Response $response -Property 'devices'
}
