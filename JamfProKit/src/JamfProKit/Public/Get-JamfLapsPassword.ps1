function Get-JamfLapsPassword {
    <#
    .SYNOPSIS
        Retrieves the current LAPS password for a local admin account on a computer.
    .DESCRIPTION
        Calls GET /api/v2/local-admin-password/{managementId}/account/{username}/password.

        NOTE: viewing a LAPS password is recorded in the Jamf Pro audit log, and Jamf
        rotates the password after the configured view-timeout. Treat every call as a
        deliberate, audited action.
    .PARAMETER AsPlainText
        Return the bare password string instead of a result object with a SecureString.
    .EXAMPLE
        Get-JamfLapsPassword -SerialNumber C02ABC123 -Username jamfadmin -AsPlainText
    .EXAMPLE
        $entry = Get-JamfLapsPassword -SerialNumber C02ABC123 -Username jamfadmin
        # $entry.Password is a SecureString
    #>
    [CmdletBinding(DefaultParameterSetName = 'Serial')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'The LAPS password arrives in plaintext from the API; wrapping it in a SecureString for the default output is the safer option.')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ManagementId', ValueFromPipelineByPropertyName)]
        [string] $ManagementId,

        [Parameter(Mandatory, ParameterSetName = 'Serial', Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Computer Serial')]
        [string] $SerialNumber,

        [Parameter(Mandatory, Position = 1)]
        [string] $Username,

        [switch] $AsPlainText,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $clientId = $ManagementId
        $label = $ManagementId
        if ($PSCmdlet.ParameterSetName -eq 'Serial') {
            $computer = Resolve-JamfComputer -Session $resolved -SerialNumber $SerialNumber
            if (-not $computer.ManagementId) { throw "Computer '$SerialNumber' has no managementId." }
            $clientId = $computer.ManagementId
            $label = $SerialNumber
        }

        Write-Verbose "Viewing the LAPS password for '$Username' on $label (audited; triggers rotation per your LAPS settings)."
        $response = Invoke-JamfRequest -Session $resolved -Method GET `
            -Path "api/v2/local-admin-password/$clientId/account/$([uri]::EscapeDataString($Username))/password"

        if ($AsPlainText) {
            return $response.password
        }
        [pscustomobject]@{
            PSTypeName   = 'JamfProKit.LapsPassword'
            Device       = $label
            ManagementId = $clientId
            Username     = $Username
            Password     = (ConvertTo-SecureString -String $response.password -AsPlainText -Force)
        }
    }
}
