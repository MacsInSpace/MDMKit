function Set-MosyleDeviceAttribute {
    <#
    .SYNOPSIS
        Updates editable device attributes in Mosyle (POST /devices).
    .DESCRIPTION
        Updates asset tag, tags, device name and lock message on one or more devices,
        keyed by serial number. Pipelined input is batched into a single request (the
        API takes an elements array), so bulk updates are one round-trip.
    .PARAMETER Tag
        Device tags. Multiple tags are sent comma-separated, as the API expects.
    .EXAMPLE
        Set-MosyleDeviceAttribute -SerialNumber F9FXH12ABC -AssetTag 'IPAD-042' -Name 'Library iPad 7'
    .EXAMPLE
        Import-Csv retag.csv | Set-MosyleDeviceAttribute -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('serial_number')]
        [string] $SerialNumber,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('asset_tag')]
        [string] $AssetTag,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Tag,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('lock')]
        [string] $LockMessage,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $element = [ordered]@{ serialnumber = $SerialNumber }
        if ($PSBoundParameters.ContainsKey('AssetTag')) { $element['asset_tag'] = $AssetTag }
        if ($PSBoundParameters.ContainsKey('Tag')) { $element['tags'] = ($Tag -join ',') }
        if ($PSBoundParameters.ContainsKey('Name')) { $element['name'] = $Name }
        if ($PSBoundParameters.ContainsKey('LockMessage')) { $element['lock'] = $LockMessage }

        if ($element.Count -eq 1) {
            Write-Verbose "[$SerialNumber] No attributes to update; skipping."
            return
        }
        [void]$elements.Add($element)
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) device(s)", 'Update attributes')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'devices' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'devices', 'elements'
        }
    }
}
