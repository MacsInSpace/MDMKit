function ConvertTo-JamfCriterionList {
    <#
    .SYNOPSIS
        Normalizes a criteria array: accepts hashtables or PSCustomObjects and
        auto-numbers priorities (by array position) where unset or negative.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $Criteria
    )

    $index = 0
    $normalized = foreach ($criterion in $Criteria) {
        $entry = [ordered]@{}
        if ($criterion -is [System.Collections.IDictionary]) {
            foreach ($key in $criterion.Keys) { $entry[[string]$key] = $criterion[$key] }
        }
        else {
            foreach ($property in $criterion.PSObject.Properties) { $entry[$property.Name] = $property.Value }
        }
        if (-not $entry.Contains('priority') -or [int]$entry['priority'] -lt 0) {
            $entry['priority'] = $index
        }
        $index++
        $entry
    }
    , @($normalized)
}
