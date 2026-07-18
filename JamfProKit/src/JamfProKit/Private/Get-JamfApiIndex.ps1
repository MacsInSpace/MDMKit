function Get-JamfApiIndex {
    <#
    .SYNOPSIS
        Returns the distilled API index for a session's Jamf Pro instance.
    .DESCRIPTION
        The index is built from the instance's own OpenAPI spec (GET /api/schema) and
        cached twice: in module memory for the session, and on disk keyed by host +
        Jamf Pro version — so it refreshes itself automatically when the instance is
        upgraded and costs one fetch per version, ever.
        -CacheOnly returns $null instead of fetching (used by tab completion).
        -Refresh forces a refetch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session,

        [switch] $CacheOnly,

        [switch] $Refresh
    )

    $versionTag = if ($Session.JamfProVersion) { $Session.JamfProVersion } else { 'unknown' }
    $memoryKey = "$($Session.BaseUri)|$versionTag"

    if (-not $Refresh -and $script:JamfApiIndexCache.ContainsKey($memoryKey)) {
        return $script:JamfApiIndexCache[$memoryKey]
    }

    $hostTag = $Session.BaseUri -replace '^https?://', '' -replace '[^\w\.-]', '_'
    $cacheFile = Join-Path $script:JamfProKitCacheDir "schema-index-$hostTag-$versionTag.json"

    if (-not $Refresh -and (Test-Path $cacheFile)) {
        try {
            $index = Get-Content -Path $cacheFile -Raw | ConvertFrom-Json -AsHashtable
            $script:JamfApiIndexCache[$memoryKey] = $index
            return $index
        }
        catch {
            Write-Verbose "Ignoring unreadable schema index cache ($cacheFile): $_"
        }
    }

    if ($CacheOnly) { return $null }

    Write-Verbose "Fetching the OpenAPI spec from $($Session.BaseUri)/api/schema (one-time per Jamf Pro version)..."
    $spec = Invoke-JamfRequest -Session $Session -Method GET -Path 'api/schema'
    $index = ConvertTo-JamfApiIndex -Spec $spec

    try {
        # Cache persistence is internal housekeeping — never subject to a caller's -WhatIf.
        New-Item -ItemType Directory -Path $script:JamfProKitCacheDir -Force -WhatIf:$false -Confirm:$false | Out-Null
        ConvertTo-Json -InputObject $index -Depth 32 -Compress |
            Set-Content -Path $cacheFile -Encoding utf8 -WhatIf:$false -Confirm:$false
    }
    catch {
        Write-Verbose "Could not persist the schema index cache: $_"
    }

    $script:JamfApiIndexCache[$memoryKey] = $index
    return $index
}

function Get-JamfSpecProperty {
    # Property access that works on both PSCustomObject (fresh spec) and hashtable
    # (cache round-trip), returning $null instead of throwing under strict mode.
    [CmdletBinding()]
    param($Object, [string] $Name)

    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $match = $Object.PSObject.Properties.Match($Name)
    if ($match.Count -gt 0) { return $match[0].Value }
    return $null
}

function Get-JamfSpecEntry {
    # Enumerates an object's properties as @{ Name; Value } pairs regardless of
    # whether it is a PSCustomObject or a dictionary.
    [CmdletBinding()]
    param($Object)

    if ($null -eq $Object) { return }
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            [pscustomobject]@{ Name = [string]$key; Value = $Object[$key] }
        }
        return
    }
    foreach ($property in $Object.PSObject.Properties) {
        [pscustomobject]@{ Name = $property.Name; Value = $property.Value }
    }
}

function ConvertTo-JamfApiIndex {
    <#
    .SYNOPSIS
        Distills a Jamf Pro OpenAPI spec into the compact resource index.
    .DESCRIPTION
        Index shape:
          resources.<name>.<vN>.<list|get|create|update|delete> =
            @{ path; method; deprecated; paged (list only); example (create/update only) }
        Only plain collection (/vN/resource) and item (/vN/resource/{id}) paths are
        indexed; deeper sub-resource paths remain the domain of typed cmdlets and
        Invoke-JamfApi.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object] $Spec
    )

    $paths = Get-JamfSpecProperty -Object $Spec -Name 'paths'
    $componentSchemas = Get-JamfSpecProperty -Object (Get-JamfSpecProperty -Object $Spec -Name 'components') -Name 'schemas'
    $resources = @{}

    foreach ($pathEntry in (Get-JamfSpecEntry -Object $paths)) {
        $segments = $pathEntry.Name.Trim('/') -split '/'
        if ($segments.Count -lt 2 -or $segments[0] -notmatch '^v\d+$') { continue }
        $version = $segments[0]
        $resource = $segments[1]

        $pathKind = $null
        if ($segments.Count -eq 2) { $pathKind = 'collection' }
        elseif ($segments.Count -eq 3 -and $segments[2] -match '^\{.+\}$') { $pathKind = 'item' }
        else { continue }

        foreach ($methodEntry in (Get-JamfSpecEntry -Object $pathEntry.Value)) {
            $method = $methodEntry.Name.ToUpperInvariant()
            if ($method -notin 'GET', 'POST', 'PUT', 'PATCH', 'DELETE') { continue }

            $operationName = switch ($true) {
                ($pathKind -eq 'collection' -and $method -eq 'GET') { 'list'; break }
                ($pathKind -eq 'collection' -and $method -eq 'POST') { 'create'; break }
                ($pathKind -eq 'item' -and $method -eq 'GET') { 'get'; break }
                ($pathKind -eq 'item' -and $method -in 'PUT', 'PATCH') { 'update'; break }
                ($pathKind -eq 'item' -and $method -eq 'DELETE') { 'delete'; break }
                default { $null }
            }
            if (-not $operationName) { continue }

            $operation = $methodEntry.Value
            $record = @{
                path       = "api$($pathEntry.Name)"
                method     = $method
                deprecated = [bool](Get-JamfSpecProperty -Object $operation -Name 'deprecated')
            }

            if ($operationName -eq 'list') {
                $record['paged'] = Test-JamfListPaged -Operation $operation -ComponentSchemas $componentSchemas
            }
            if ($operationName -in 'create', 'update') {
                $requestSchema = Get-JamfSpecProperty -Object (
                    Get-JamfSpecProperty -Object (
                        Get-JamfSpecProperty -Object (
                            Get-JamfSpecProperty -Object $operation -Name 'requestBody'
                        ) -Name 'content'
                    ) -Name 'application/json'
                ) -Name 'schema'
                if ($null -ne $requestSchema) {
                    $record['example'] = Build-JamfSchemaExample -Schema $requestSchema -ComponentSchemas $componentSchemas
                }
            }

            if (-not $resources.ContainsKey($resource)) { $resources[$resource] = @{} }
            if (-not $resources[$resource].ContainsKey($version)) { $resources[$resource][$version] = @{} }

            $existing = $resources[$resource][$version]
            if ($operationName -eq 'update' -and $existing.ContainsKey('update')) {
                # Prefer PUT when a version documents both PUT and PATCH.
                if ($existing['update']['method'] -eq 'PUT') { continue }
            }
            $existing[$operationName] = $record
        }
    }

    @{ resources = $resources }
}

function Test-JamfListPaged {
    # A list endpoint is "paged" when its 200 response schema has the standard
    # totalCount/results shape.
    [CmdletBinding()]
    [OutputType([bool])]
    param($Operation, $ComponentSchemas)

    $schema = Get-JamfSpecProperty -Object (
        Get-JamfSpecProperty -Object (
            Get-JamfSpecProperty -Object (
                Get-JamfSpecProperty -Object (
                    Get-JamfSpecProperty -Object $Operation -Name 'responses'
                ) -Name '200'
            ) -Name 'content'
        ) -Name 'application/json'
    ) -Name 'schema'
    if ($null -eq $schema) { return $false }

    $ref = Get-JamfSpecProperty -Object $schema -Name '$ref'
    if ($ref) {
        $schema = Get-JamfSpecProperty -Object $ComponentSchemas -Name (([string]$ref) -split '/')[-1]
    }
    $properties = Get-JamfSpecProperty -Object $schema -Name 'properties'
    if ($null -eq $properties) { return $false }
    return ($null -ne (Get-JamfSpecProperty -Object $properties -Name 'results'))
}

function Build-JamfSchemaExample {
    <#
    .SYNOPSIS
        Builds an example body (ordered hashtable) from an OpenAPI schema.
    .DESCRIPTION
        Strings -> '' (or the schema's example/first enum value), integers/numbers -> 0,
        booleans -> $false, arrays -> one example item, objects -> recurse. readOnly
        properties (id, href, ...) are omitted. Depth-capped and cycle-guarded.
    #>
    [CmdletBinding()]
    param(
        $Schema,

        $ComponentSchemas,

        [int] $Depth = 0,

        [string[]] $VisitedRefs = @()
    )

    if ($null -eq $Schema -or $Depth -gt 8) { return $null }

    $ref = Get-JamfSpecProperty -Object $Schema -Name '$ref'
    if ($ref) {
        $refName = (([string]$ref) -split '/')[-1]
        if ($refName -in $VisitedRefs) { return $null }
        $resolved = Get-JamfSpecProperty -Object $ComponentSchemas -Name $refName
        return Build-JamfSchemaExample -Schema $resolved -ComponentSchemas $ComponentSchemas `
            -Depth ($Depth + 1) -VisitedRefs ($VisitedRefs + $refName)
    }

    $example = Get-JamfSpecProperty -Object $Schema -Name 'example'
    $enum = Get-JamfSpecProperty -Object $Schema -Name 'enum'
    $type = Get-JamfSpecProperty -Object $Schema -Name 'type'
    $properties = Get-JamfSpecProperty -Object $Schema -Name 'properties'
    if (-not $type -and $null -ne $properties) { $type = 'object' }

    if ($null -ne $enum) { return @($enum)[0] }

    switch ([string]$type) {
        'object' {
            $result = [ordered]@{}
            foreach ($propertyEntry in (Get-JamfSpecEntry -Object $properties)) {
                if ([bool](Get-JamfSpecProperty -Object $propertyEntry.Value -Name 'readOnly')) { continue }
                $result[$propertyEntry.Name] = Build-JamfSchemaExample -Schema $propertyEntry.Value `
                    -ComponentSchemas $ComponentSchemas -Depth ($Depth + 1) -VisitedRefs $VisitedRefs
            }
            return $result
        }
        'array' {
            $item = Build-JamfSchemaExample -Schema (Get-JamfSpecProperty -Object $Schema -Name 'items') `
                -ComponentSchemas $ComponentSchemas -Depth ($Depth + 1) -VisitedRefs $VisitedRefs
            if ($null -eq $item) { return , @() }
            return , @($item)
        }
        'string' {
            if ($null -ne $example) { return [string]$example }
            if ((Get-JamfSpecProperty -Object $Schema -Name 'format') -eq 'date-time') { return '2026-01-01T00:00:00Z' }
            return ''
        }
        'integer' { return 0 }
        'number' { return 0 }
        'boolean' { return $false }
        default { return $null }
    }
}

function Resolve-JamfObjectOperation {
    <#
    .SYNOPSIS
        Picks the concrete endpoint for a resource + operation, preferring the newest
        non-deprecated API version.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Index,

        [Parameter(Mandatory)]
        [string] $Resource,

        [Parameter(Mandatory)]
        [ValidateSet('list', 'get', 'create', 'update', 'delete')]
        [string] $Operation,

        [string] $ApiVersion
    )

    $resources = $Index['resources']
    if (-not $resources.ContainsKey($Resource)) {
        $suggestions = @($resources.Keys | Where-Object { $_ -like "*$Resource*" } | Sort-Object | Select-Object -First 6)
        $hint = if ($suggestions.Count -gt 0) { " Did you mean: $($suggestions -join ', ')?" } else { '' }
        throw "Unknown resource '$Resource'.$hint Use Get-JamfApiResource to explore what this instance offers."
    }

    $versions = $resources[$Resource]
    $candidates = if ($ApiVersion) {
        if (-not $versions.ContainsKey($ApiVersion)) {
            throw "Resource '$Resource' has no '$ApiVersion' endpoints (available: $(@($versions.Keys) -join ', '))."
        }
        @($ApiVersion)
    }
    else {
        @($versions.Keys | Sort-Object { [int]($_.Substring(1)) } -Descending)
    }

    foreach ($candidate in $candidates) {
        $operations = $versions[$candidate]
        if ($operations.ContainsKey($Operation) -and -not $operations[$Operation]['deprecated']) {
            return $operations[$Operation] + @{ version = $candidate }
        }
    }
    foreach ($candidate in $candidates) {
        $operations = $versions[$candidate]
        if ($operations.ContainsKey($Operation)) {
            Write-Warning "Using deprecated $candidate endpoint for $Resource ($Operation) — no newer version offers it."
            return $operations[$Operation] + @{ version = $candidate }
        }
    }

    $available = @($versions.Keys | ForEach-Object { $v = $_; @($versions[$v].Keys | ForEach-Object { "$_ ($v)" }) }) -join ', '
    throw "Resource '$Resource' does not support '$Operation'. Available operations: $available."
}

function Set-JamfPathIdentifier {
    # Replaces the single {placeholder} in an indexed path with an escaped id.
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'String transformation; changes no state.')]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Id
    )

    $placeholder = [regex]::Match($Path, '\{[^}]+\}')
    if (-not $placeholder.Success) {
        throw "The endpoint path '$Path' has no id placeholder."
    }
    return $Path.Replace($placeholder.Value, [uri]::EscapeDataString($Id))
}
