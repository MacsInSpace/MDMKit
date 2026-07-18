function New-JamfObjectTemplate {
    <#
    .SYNOPSIS
        Emits a ready-to-edit body skeleton for a resource, built from your instance's
        own OpenAPI schema.
    .DESCRIPTION
        Every field the endpoint accepts, with type-appropriate placeholder values
        (strings empty, numbers 0, booleans false, enums set to their first allowed
        value, read-only fields omitted). Fill it in and pass to New-JamfObject or
        Set-JamfObject — no trip to developer.jamf.com required.
    .PARAMETER Operation
        Which request schema to template: Create (default) or Update.
    .EXAMPLE
        $body = New-JamfObjectTemplate webhooks
        $body.name = 'Inventory updated'
        $body.event = 'ComputerInventoryCompleted'
        New-JamfObject webhooks -Body $body
    .EXAMPLE
        New-JamfObjectTemplate app-installers -AsJson
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Builds an in-memory template; changes no state.')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Resource,

        [ValidateSet('Create', 'Update')]
        [string] $Operation = 'Create',

        [string] $ApiVersion,

        [switch] $AsJson,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    $index = Get-JamfApiIndex -Session $resolved
    $operationRecord = Resolve-JamfObjectOperation -Index $index -Resource $Resource `
        -Operation $Operation.ToLowerInvariant() -ApiVersion $ApiVersion

    if (-not $operationRecord.ContainsKey('example') -or $null -eq $operationRecord['example']) {
        throw "The $($operationRecord['version']) $Resource $($Operation.ToLowerInvariant()) endpoint documents no JSON request schema to template."
    }

    # Deep-copy via JSON round-trip so callers can't mutate the cached index.
    $json = ConvertTo-Json -InputObject $operationRecord['example'] -Depth 32
    if ($AsJson) { return $json }
    ConvertFrom-Json -InputObject $json -AsHashtable
}
