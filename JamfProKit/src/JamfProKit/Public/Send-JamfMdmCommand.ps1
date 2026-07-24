function Send-JamfMdmCommand {
    <#
    .SYNOPSIS
        Sends an MDM command via the modern Jamf Pro API (POST /api/v2/mdm/commands).
    .DESCRIPTION
        Address devices by -ManagementId directly, or by -ComputerSerial (resolved via
        inventory — must match exactly one computer). Extra command fields go in
        -CommandData, merged with the command type, e.g. for SET_RECOVERY_LOCK:
        -CommandData @{ newPassword = 'S3cret' }.

        Common command types: RESTART_DEVICE, SHUT_DOWN_DEVICE, DEVICE_LOCK,
        ERASE_DEVICE, SET_RECOVERY_LOCK, LOG_OUT_USER, SETTINGS,
        ENABLE_LOST_MODE, DISABLE_LOST_MODE, PLAY_LOST_MODE_SOUND, DEVICE_LOCATION,
        DEVICE_INFORMATION (asks the device to report inventory data - the API-side
        "update info"; REQUIRES -CommandData @{ queries = @('DeviceName', ...) } with at
        least one Apple DeviceInformation query, else the server returns HTTP 500).
        The server validates type and payload. For a blank push use Send-JamfBlankPush;
        to cancel queued commands use Clear-JamfMdmCommand.
    .EXAMPLE
        Send-JamfMdmCommand -ComputerSerial C02ABC123 -CommandType RESTART_DEVICE
    .EXAMPLE
        Send-JamfMdmCommand -ComputerSerial C02ABC123 -CommandType SET_RECOVERY_LOCK -CommandData @{ newPassword = $pw }
    .EXAMPLE
        Send-JamfMdmCommand -ManagementId $ids -CommandType DEVICE_LOCK -CommandData @{ pin = '123456'; message = 'Return to IT' }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $CommandType,

        [Parameter(Mandatory, ParameterSetName = 'ManagementId', ValueFromPipelineByPropertyName)]
        [string[]] $ManagementId,

        [Parameter(Mandatory, ParameterSetName = 'Serial')]
        [string[]] $ComputerSerial,

        [hashtable] $CommandData,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $targets = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ManagementId') {
            foreach ($mid in $ManagementId) { [void]$targets.Add($mid) }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Serial') {
            foreach ($serial in $ComputerSerial) {
                $computer = Resolve-JamfComputer -Session $resolved -SerialNumber $serial
                if (-not $computer.ManagementId) {
                    throw "Computer '$serial' has no managementId (not MDM-managed?)."
                }
                [void]$targets.Add($computer.ManagementId)
            }
        }

        if ($targets.Count -eq 0) {
            Write-Verbose 'No target devices; nothing to send.'
            return
        }

        $commandBody = @{ commandType = $CommandType.ToUpperInvariant() }
        if ($null -ne $CommandData) {
            foreach ($key in $CommandData.Keys) { $commandBody[$key] = $CommandData[$key] }
        }

        if ($PSCmdlet.ShouldProcess("$($targets.Count) device(s)", "Send MDM command $($commandBody['commandType'])")) {
            Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v2/mdm/commands' -Body @{
                clientData  = @($targets | ForEach-Object { @{ managementId = $_ } })
                commandData = $commandBody
            }
        }
    }
}
