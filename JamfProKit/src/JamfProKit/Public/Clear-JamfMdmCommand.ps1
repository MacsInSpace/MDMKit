function Clear-JamfMdmCommand {
    <#
    .SYNOPSIS
        Flushes pending and/or failed MDM commands (Classic API commandflush).
    .DESCRIPTION
        Cancels queued MDM commands so they stop blocking new ones:
        DELETE JSSResource/commandflush/{computers|mobiledevices}/id/{ids}/status/{status}.

        Unlike the v2 command endpoints this addresses devices by their inventory id
        (Get-JamfComputer/Get-JamfMobileDevice 'id'), not managementId. Requires the
        'Flush MDM Commands' privilege (Jamf Pro Server Actions).
    .PARAMETER ComputerId
        Computer inventory ids to flush.
    .PARAMETER MobileDeviceId
        Mobile device inventory ids to flush.
    .PARAMETER Status
        Which queue to flush: Pending, Failed, or Pending+Failed.
    .EXAMPLE
        Clear-JamfMdmCommand -ComputerId 8, 10 -Status Failed
    .EXAMPLE
        Clear-JamfMdmCommand -MobileDeviceId 42 -Status 'Pending+Failed'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [string[]] $ComputerId,

        [string[]] $MobileDeviceId,

        [Parameter(Mandatory)]
        [ValidateSet('Pending', 'Failed', 'Pending+Failed')]
        [string] $Status,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session

    $buckets = @(
        @{ Kind = 'computers'; Ids = @($ComputerId | Where-Object { $_ }) }
        @{ Kind = 'mobiledevices'; Ids = @($MobileDeviceId | Where-Object { $_ }) }
    ) | Where-Object { $_.Ids.Count -gt 0 }

    if (-not $buckets) {
        Write-Verbose 'No target devices; nothing to flush.'
        return
    }

    foreach ($bucket in $buckets) {
        $idList = $bucket.Ids -join ','
        $path = "JSSResource/commandflush/$($bucket.Kind)/id/$idList/status/$Status"
        if ($PSCmdlet.ShouldProcess("$($bucket.Kind) $idList", "Flush $Status MDM commands")) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path $path -Accept 'application/xml'
        }
    }
}
