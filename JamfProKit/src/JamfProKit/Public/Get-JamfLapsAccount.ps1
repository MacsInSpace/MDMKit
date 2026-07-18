function Get-JamfLapsAccount {
    <#
    .SYNOPSIS
        Lists the LAPS-capable local admin accounts on a computer.
    .EXAMPLE
        Get-JamfLapsAccount -SerialNumber C02ABC123
    .EXAMPLE
        Get-JamfLapsAccount -ManagementId 1a2b3c4d-...
    #>
    [CmdletBinding(DefaultParameterSetName = 'Serial')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ManagementId', ValueFromPipelineByPropertyName)]
        [string] $ManagementId,

        [Parameter(Mandatory, ParameterSetName = 'Serial', Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Computer Serial')]
        [string] $SerialNumber,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $clientId = $ManagementId
        if ($PSCmdlet.ParameterSetName -eq 'Serial') {
            $computer = Resolve-JamfComputer -Session $resolved -SerialNumber $SerialNumber
            if (-not $computer.ManagementId) { throw "Computer '$SerialNumber' has no managementId." }
            $clientId = $computer.ManagementId
        }

        $response = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v2/local-admin-password/$clientId/accounts"
        if ($null -ne $response -and $response.PSObject.Properties.Match('results').Count -gt 0) {
            $response.results
        }
        else {
            $response
        }
    }
}
