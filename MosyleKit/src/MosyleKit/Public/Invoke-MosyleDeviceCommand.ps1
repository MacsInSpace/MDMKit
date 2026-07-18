function Invoke-MosyleDeviceCommand {
    <#
    .SYNOPSIS
        Sends a bulk management command to Mosyle devices (POST /bulkops).
    .DESCRIPTION
        Targets devices by -Device (UDIDs) and/or -Group (device group IDs) — if a group
        is given, UDIDs are optional. Supported commands and their extra parameters:

          Restart, Shutdown, Unassign        (targeting only; Unassign = move to Limbo)
          ClearCommands,
          ClearPendingCommands,
          ClearFailedCommands                (targeting only; clear queued MDM commands)
          Lock                       -Pincode (6-digit, macOS), -PhoneNumber, -LockMessage
          Wipe                       -RevokeVppLicenses, -PreserveDataPlan,
                                     -DisallowProximitySetup, -EnableReturnToService,
                                     -ShouldRetryEnrollment, -WipePincode
          EnableActivationLock,
          DisableActivationLock      -LostMessage

        Mosyle returns per-request results (status COMMAND_SENT on success); UDIDs it
        couldn't match come back under devices_notfound, which this cmdlet surfaces as a
        warning.
    .EXAMPLE
        Invoke-MosyleDeviceCommand -Command Restart -Group 210
    .EXAMPLE
        Get-MosyleDevice -Os ios -Tag 'Retired' | Invoke-MosyleDeviceCommand -Command Wipe -RevokeVppLicenses -Confirm:$false
    .EXAMPLE
        Invoke-MosyleDeviceCommand -Command Lock -Device $udid -Pincode 123456 -LockMessage 'Return to IT'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Restart', 'Shutdown', 'Wipe', 'Lock', 'Unassign',
            'ClearCommands', 'ClearPendingCommands', 'ClearFailedCommands',
            'EnableActivationLock', 'DisableActivationLock')]
        [string] $Command,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UDID', 'deviceudid')]
        [string[]] $Device,

        [int[]] $Group,

        # --- Lock ---
        [int] $Pincode,
        [string] $PhoneNumber,
        [string] $LockMessage,

        # --- Wipe ---
        [switch] $RevokeVppLicenses,
        [switch] $PreserveDataPlan,
        [switch] $DisallowProximitySetup,
        [switch] $EnableReturnToService,
        [switch] $ShouldRetryEnrollment,
        [int] $WipePincode,

        # --- Activation Lock ---
        [string] $LostMessage,

        # Passthrough for any documented option not surfaced as a parameter.
        [hashtable] $Option,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $operationMap = @{
            Restart               = 'restart_devices'
            Shutdown              = 'shutdown_devices'
            Wipe                  = 'wipe_devices'
            Lock                  = 'lock_device'
            Unassign              = 'change_to_limbo'
            ClearCommands         = 'clear_commands'
            ClearPendingCommands  = 'clear_pending_commands'
            ClearFailedCommands   = 'clear_failed_commands'
            EnableActivationLock  = 'enable_activationlock'
            DisableActivationLock = 'disable_activationlock'
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

        $element = [ordered]@{ operation = $operationMap[$Command] }
        if ($devices.Count -gt 0) { $element['devices'] = @($devices) }
        if ($null -ne $Group -and $Group.Count -gt 0) { $element['groups'] = @($Group | ForEach-Object { [string]$_ }) }

        switch ($Command) {
            'Lock' {
                if ($PSBoundParameters.ContainsKey('Pincode')) { $element['pincode'] = "$Pincode" }
                if ($PhoneNumber) { $element['phonenumber'] = $PhoneNumber }
                if ($LockMessage) { $element['lockmessage'] = $LockMessage }
            }
            'Wipe' {
                $wipeOptions = @{}
                if ($null -ne $Option) { foreach ($k in $Option.Keys) { $wipeOptions[$k] = $Option[$k] } }
                if ($RevokeVppLicenses) { $wipeOptions['RevokeVPPLicenses'] = 'true' }
                if ($PreserveDataPlan) { $wipeOptions['PreserveDataPlan'] = 'true' }
                if ($DisallowProximitySetup) { $wipeOptions['DisallowProximitySetup'] = 'true' }
                if ($EnableReturnToService) { $wipeOptions['EnableReturnToService'] = 'true' }
                if ($ShouldRetryEnrollment) { $wipeOptions['ShouldRetryEnrollment'] = 'true' }
                if ($PSBoundParameters.ContainsKey('WipePincode')) { $wipeOptions['pin_code'] = "$WipePincode" }
                if ($wipeOptions.Count -gt 0) { $element['options'] = $wipeOptions }
            }
            { $_ -in 'EnableActivationLock', 'DisableActivationLock' } {
                if ($LostMessage) { $element['lost_message'] = $LostMessage }
            }
        }

        $targetLabel = @(
            if ($devices.Count -gt 0) { "$($devices.Count) device(s)" }
            if ($null -ne $Group -and $Group.Count -gt 0) { "group(s) $($Group -join ', ')" }
        ) -join ' + '

        if (-not $PSCmdlet.ShouldProcess($targetLabel, $Command)) { return }

        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'bulkops' -Body @{ elements = @($element) }

        $results = Select-MosyleResult -Response $response -Property 'response'
        foreach ($item in @($results)) {
            if ($null -eq $item -or $item -is [string]) { continue }
            $notFound = $item.PSObject.Properties.Match('devices_notfound')
            if ($notFound.Count -gt 0 -and $null -ne $notFound[0].Value -and @($notFound[0].Value).Count -gt 0) {
                Write-Warning "$Command — devices not found: $(@($notFound[0].Value) -join ', ')"
            }
            $statusProp = $item.PSObject.Properties.Match('status')
            if ($statusProp.Count -gt 0 -and $statusProp[0].Value -notin 'COMMAND_SENT', 'COMMAND_CLEARED', 'OK') {
                $infoProp = $item.PSObject.Properties.Match('info')
                $info = if ($infoProp.Count -gt 0) { $infoProp[0].Value } else { '' }
                Write-Warning "$Command — $($statusProp[0].Value): $info"
            }
        }
        $results
    }
}
