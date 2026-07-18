function Invoke-MosyleLostMode {
    <#
    .SYNOPSIS
        Controls Lost Mode on Mosyle devices (POST /lostmode).
    .DESCRIPTION
        Lost Mode is its own endpoint (not /bulkops). Target by -Device (UDIDs) and/or
        -Group (device group IDs). Actions:
          Enable           -Message (shown on the lock screen; required), -PhoneNumber, -Footnote
          Disable
          PlaySound        (make the device play a sound to help locate it)
          RequestLocation  (ask the device to report its location)
    .EXAMPLE
        Invoke-MosyleLostMode -Action Enable -Device $udid -Message 'This iPad is lost — call the office' -PhoneNumber '03 1234 5678'
    .EXAMPLE
        Invoke-MosyleLostMode -Action RequestLocation -Device $udid
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Enable', 'Disable', 'PlaySound', 'RequestLocation')]
        [string] $Action,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UDID', 'deviceudid')]
        [string[]] $Device,

        [int[]] $Group,

        [string] $Message,

        [string] $PhoneNumber,

        [string] $Footnote,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $operationMap = @{
            Enable          = 'enable'
            Disable         = 'disable'
            PlaySound       = 'play_sound'
            RequestLocation = 'request_location'
        }
        $devices = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($null -ne $Device) {
            foreach ($d in $Device) { if ($d) { [void]$devices.Add($d) } }
        }
    }

    end {
        if ($devices.Count -eq 0 -and (-not $Group -or $Group.Count -eq 0)) {
            throw 'Supply -Device (UDIDs) and/or -Group (device group IDs).'
        }
        if ($Action -eq 'Enable' -and -not $Message) {
            throw '-Message is required when enabling Lost Mode.'
        }

        $element = [ordered]@{ operation = $operationMap[$Action] }
        if ($devices.Count -gt 0) { $element['devices'] = @($devices) }
        if ($null -ne $Group -and $Group.Count -gt 0) { $element['groups'] = @($Group | ForEach-Object { [string]$_ }) }
        if ($Message) { $element['message'] = $Message }
        if ($PhoneNumber) { $element['phone_number'] = $PhoneNumber }
        if ($Footnote) { $element['footnote'] = $Footnote }

        $targetLabel = @(
            if ($devices.Count -gt 0) { "$($devices.Count) device(s)" }
            if ($null -ne $Group -and $Group.Count -gt 0) { "group(s) $($Group -join ', ')" }
        ) -join ' + '

        if (-not $PSCmdlet.ShouldProcess($targetLabel, "Lost Mode: $Action")) { return }

        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'lostmode' -Body @{ elements = @($element) }
        Select-MosyleResult -Response $response -Property 'response'
    }
}
