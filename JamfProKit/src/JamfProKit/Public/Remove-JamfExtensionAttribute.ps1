function Remove-JamfExtensionAttribute {
    <#
    .SYNOPSIS
        Deletes a computer or mobile device extension attribute (and its collected
        values on every device record).
    .EXAMPLE
        Remove-JamfExtensionAttribute -Id 4
    .EXAMPLE
        Get-JamfExtensionAttribute -Name 'Obsolete EA' | Remove-JamfExtensionAttribute -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [ValidateSet('Computer', 'MobileDevice')]
        [string] $Type = 'Computer',

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $endpoint = if ($Type -eq 'Computer') { 'api/v1/computer-extension-attributes' } else { 'api/v1/mobile-device-extension-attributes' }
    }

    process {
        if ($PSCmdlet.ShouldProcess("$Type extension attribute id $Id", 'Delete extension attribute and all collected values')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "$endpoint/$Id" | Out-Null
        }
    }
}
