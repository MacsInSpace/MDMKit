function Set-JamfCategory {
    <#
    .SYNOPSIS
        Updates a category in Jamf Pro. Only the properties you supply change.
    .EXAMPLE
        Set-JamfCategory -Id 5 -Name 'Security & Privacy'
    .EXAMPLE
        Get-JamfCategory -Name 'Old Name' | Set-JamfCategory -Name 'New Name'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [string] $Name,

        [ValidateRange(1, 20)]
        [int] $Priority,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $current = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/categories/$Id"
        $body = @{
            name     = $current.name
            priority = $current.priority
        }
        if ($PSBoundParameters.ContainsKey('Name')) { $body['name'] = $Name }
        if ($PSBoundParameters.ContainsKey('Priority')) { $body['priority'] = $Priority }

        if ($PSCmdlet.ShouldProcess("$($body['name']) (id $Id)", 'Update Jamf Pro category')) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "api/v1/categories/$Id" -Body $body
        }
    }
}
