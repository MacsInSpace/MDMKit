function Resolve-JamfComputer {
    <#
    .SYNOPSIS
        Resolves a computer serial number to its Jamf ID and managementId.
    .DESCRIPTION
        MDM commands and LAPS address devices by managementId, not inventory ID.
        Throws unless exactly one computer matches the serial.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session,

        [Parameter(Mandatory)]
        [string] $SerialNumber
    )

    $escaped = $SerialNumber -replace '"', ''
    $found = @(Get-JamfPagedResult -Session $Session -Path 'api/v1/computers-inventory' `
        -Filter ('hardware.serialNumber=="{0}"' -f $escaped) -Query @{ section = 'GENERAL' })

    if ($found.Count -ne 1) {
        throw "Expected exactly one computer with serial '$SerialNumber' but found $($found.Count)."
    }

    $record = $found[0]
    $managementId = $null
    if ($record.PSObject.Properties.Match('general').Count -gt 0 -and
        $null -ne $record.general -and
        $record.general.PSObject.Properties.Match('managementId').Count -gt 0) {
        $managementId = $record.general.managementId
    }

    [pscustomobject]@{
        Id           = [string]$record.id
        ManagementId = [string]$managementId
        SerialNumber = $SerialNumber
    }
}
