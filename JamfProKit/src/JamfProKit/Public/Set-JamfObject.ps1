function Set-JamfObject {
    <#
    .SYNOPSIS
        Updates any Jamf Pro API resource, driven by your instance's live OpenAPI spec.
    .DESCRIPTION
        Uses whichever verb the endpoint documents (PUT or PATCH — e.g. v2
        mobile-devices updates via PATCH). For PUT endpoints Jamf replaces the object,
        so send the full body (fetch with Get-JamfObject, modify, send back).
    .EXAMPLE
        $webhook = Get-JamfObject webhooks -Id 5
        $webhook.enabled = $false
        Set-JamfObject webhooks -Id 5 -Body $webhook
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Resource,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, Position = 2)]
        [object] $Body,

        [string] $ApiVersion,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $index = Get-JamfApiIndex -Session $resolved
    }

    process {
        $operation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation update -ApiVersion $ApiVersion
        $path = Set-JamfPathIdentifier -Path $operation['path'] -Id $Id

        if ($PSCmdlet.ShouldProcess("$Resource id $Id", "Update ($($operation['method']) $($operation['version']))")) {
            Invoke-JamfRequest -Session $resolved -Method $operation['method'] -Path $path -Body $Body
        }
    }
}
