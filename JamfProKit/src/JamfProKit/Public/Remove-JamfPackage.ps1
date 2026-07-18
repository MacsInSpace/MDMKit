function Remove-JamfPackage {
    <#
    .SYNOPSIS
        Deletes a package record from Jamf Pro (and its file from cloud distribution).
    .EXAMPLE
        Remove-JamfPackage -Id 12
    .EXAMPLE
        Get-JamfPackage -FileName 'Firefox-127.0.pkg' | Remove-JamfPackage -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        if ($PSCmdlet.ShouldProcess("Package id $Id", 'Delete Jamf Pro package')) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path "api/v1/packages/$Id" | Out-Null
        }
    }
}
