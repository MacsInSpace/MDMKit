function Remove-JamfObject {
    <#
    .SYNOPSIS
        Deletes any Jamf Pro API resource, driven by your instance's live OpenAPI spec.
    .EXAMPLE
        Remove-JamfObject webhooks -Id 5
    .EXAMPLE
        Get-JamfObject webhooks -Filter 'enabled==false' | Remove-JamfObject webhooks -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Resource,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [string] $ApiVersion,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $index = Get-JamfApiIndex -Session $resolved
    }

    process {
        $operation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation delete -ApiVersion $ApiVersion
        $path = Set-JamfPathIdentifier -Path $operation['path'] -Id $Id

        if ($PSCmdlet.ShouldProcess("$Resource id $Id", "Delete ($($operation['version']))")) {
            Invoke-JamfRequest -Session $resolved -Method DELETE -Path $path | Out-Null
        }
    }
}
