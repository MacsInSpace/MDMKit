function Remove-JamfGroup {
    <#
    .SYNOPSIS
        Deletes a computer, mobile device or user group.
    .EXAMPLE
        Remove-JamfGroup -Id 15
    .EXAMPLE
        Get-JamfGroup -Type User -Name 'Obsolete Pilot' | Remove-JamfGroup -Type User -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [int] $Id,

        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type = 'Computer',

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $config = Get-JamfGroupTypeConfig -Type $Type
    }

    process {
        if ($PSCmdlet.ShouldProcess("$Type group id $Id", 'Delete group')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "JSSResource/$($config.Endpoint)/id/$Id" `
                -Accept 'application/xml' | Out-Null
        }
    }
}
