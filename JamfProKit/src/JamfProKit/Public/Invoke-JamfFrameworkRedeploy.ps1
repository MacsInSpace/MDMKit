function Invoke-JamfFrameworkRedeploy {
    <#
    .SYNOPSIS
        Redeploys the Jamf management framework to a computer via MDM
        (POST /api/v1/jamf-management-framework/redeploy/{id}).
    .DESCRIPTION
        The standard fix for a Mac whose jamf binary is broken or not checking in but
        which still has a working MDM channel.
    .EXAMPLE
        Invoke-JamfFrameworkRedeploy -Id 123
    .EXAMPLE
        Invoke-JamfFrameworkRedeploy -SerialNumber C02ABC123
    .EXAMPLE
        Import-Csv broken-macs.csv | Invoke-JamfFrameworkRedeploy
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Id')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id', Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ParameterSetName = 'Serial', ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Computer Serial')]
        [string] $SerialNumber,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $targetId = $Id
        $label = "computer id $Id"
        if ($PSCmdlet.ParameterSetName -eq 'Serial') {
            $computer = Resolve-JamfComputer -Session $resolved -SerialNumber $SerialNumber
            $targetId = $computer.Id
            $label = $SerialNumber
        }

        if ($PSCmdlet.ShouldProcess($label, 'Redeploy Jamf management framework')) {
            Invoke-JamfRequest -Session $resolved -Method POST -Path "api/v1/jamf-management-framework/redeploy/$targetId"
        }
    }
}
