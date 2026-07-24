function Send-JamfBlankPush {
    <#
    .SYNOPSIS
        Sends a blank push (APNs wake-up) via POST /api/v2/mdm/blank-push.
    .DESCRIPTION
        Nudges devices to check in with MDM now. Computers and mobile devices share the
        endpoint; address them by -ManagementId (the same ids Send-JamfMdmCommand uses).

        Since Jamf Pro 10.48 the server sends a DeclarativeManagement request in place
        of a bare blank push, so the device also returns a DDM status report with its
        check-in - still harmless, still the standard "kick the queue" tool.

        Returns the server response: errorUuids lists the management ids that could not
        be pushed (empty = all accepted).
    .PARAMETER ManagementId
        One or more device management ids (computers or mobile devices).
    .EXAMPLE
        Send-JamfBlankPush -ManagementId $ids
    .EXAMPLE
        Get-JamfComputer | Select-Object -ExpandProperty general | Send-JamfBlankPush
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]] $ManagementId,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $targets = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($mid in $ManagementId) { [void]$targets.Add($mid) }
    }

    end {
        if ($targets.Count -eq 0) {
            Write-Verbose 'No target devices; nothing to send.'
            return
        }

        if ($PSCmdlet.ShouldProcess("$($targets.Count) device(s)", 'Send blank push')) {
            Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v2/mdm/blank-push' -Body @{
                clientManagementIds = @($targets)
            }
        }
    }
}
