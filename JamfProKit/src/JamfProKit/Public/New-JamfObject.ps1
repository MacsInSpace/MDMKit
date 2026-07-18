function New-JamfObject {
    <#
    .SYNOPSIS
        Creates any Jamf Pro API resource, driven by your instance's live OpenAPI spec.
    .DESCRIPTION
        Start from a schema-accurate skeleton with New-JamfObjectTemplate, fill it in,
        and pass it as -Body (hashtable, PSCustomObject or JSON string). The server
        validates the payload — this layer routes, it doesn't second-guess.
    .EXAMPLE
        $body = New-JamfObjectTemplate webhooks
        $body.name = 'Inventory updated'
        New-JamfObject webhooks -Body $body
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Resource,

        [Parameter(Mandatory, Position = 1)]
        [object] $Body,

        [string] $ApiVersion,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    $index = Get-JamfApiIndex -Session $resolved
    $operation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation create -ApiVersion $ApiVersion

    if ($PSCmdlet.ShouldProcess($Resource, "Create ($($operation['version']))")) {
        $response = Invoke-JamfRequest -Session $resolved -Method $operation['method'] -Path $operation['path'] -Body $Body

        # Creates usually return { id, href }; refetch the full object when we can.
        $newId = $null
        if ($null -ne $response -and $response.PSObject.Properties.Match('id').Count -gt 0) { $newId = [string]$response.id }
        if ($newId) {
            try {
                $getOperation = Resolve-JamfObjectOperation -Index $index -Resource $Resource -Operation get -ApiVersion $ApiVersion
                return Invoke-JamfRequest -Session $resolved -Method GET -Path (Set-JamfPathIdentifier -Path $getOperation['path'] -Id $newId)
            }
            catch {
                Write-Verbose "Created id $newId but could not refetch: $_"
            }
        }
        $response
    }
}
