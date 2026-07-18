function Get-MosyleDevice {
    <#
    .SYNOPSIS
        Lists devices from Mosyle (POST /listdevices).
    .DESCRIPTION
        -Os is required (the API lists one platform at a time). Optional filters narrow
        by tag, OS version and serial number; -Column restricts the returned attributes
        (fewer fields = lighter responses) and -Page walks large result sets (0-based).
        Any other documented list option can be passed through with -Options.
    .PARAMETER Os
        Platform to list: ios, mac, tvos or visionos. Required.
    .PARAMETER Column
        Specific attributes to return, e.g. serial_number, device_name, os, total_disk,
        battery, is_supervised. Omit for the full record.
    .PARAMETER Page
        0-based page number for paginated results.
    .EXAMPLE
        Get-MosyleDevice -Os ios
    .EXAMPLE
        Get-MosyleDevice -Os mac -Column serial_number, device_name, osversion -Tag '1:1'
    .EXAMPLE
        Get-MosyleDevice -Os ios -SerialNumber F9FXH12ABC
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('ios', 'mac', 'tvos', 'visionos')]
        [string] $Os,

        [string[]] $Tag,

        [string[]] $OsVersion,

        [string[]] $SerialNumber,

        [int] $Page,

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
    $requestOptions['os'] = $Os
    if ($null -ne $Tag -and $Tag.Count -gt 0) { $requestOptions['tags'] = @($Tag) }
    if ($null -ne $OsVersion -and $OsVersion.Count -gt 0) { $requestOptions['osversions'] = @($OsVersion) }
    if ($null -ne $SerialNumber -and $SerialNumber.Count -gt 0) { $requestOptions['serial_numbers'] = @($SerialNumber) }
    if ($PSBoundParameters.ContainsKey('Page')) { $requestOptions['page'] = $Page }
    if ($null -ne $Column -and $Column.Count -gt 0) { $requestOptions['specific_columns'] = @($Column) }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listdevices' -Body @{ options = $requestOptions }
    Select-MosyleResult -Response $response -Property 'devices', 'response'
}
