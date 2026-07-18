function New-MosyleUserElement {
    <#
    .SYNOPSIS
        Builds a /users elements[] entry shared by New-MosyleUser and Set-MosyleUser.
    .DESCRIPTION
        id and operation are always set. Every other field is included only when the
        caller actually bound it (checked via the passed $BoundParameters), so an
        update touches only what was supplied. Location entries are normalized to the
        API's { name, grade_level } shape.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Private helper; builds an in-memory hashtable and changes no state.')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('save', 'update')]
        [string] $Operation,

        [Parameter(Mandatory)]
        [object] $BoundParameters,

        [string] $Id,
        [string] $Name,
        [string] $Type,
        [string] $Email,
        [string] $ManagedAppleId,
        [object[]] $Location,
        [int] $AccountId
    )

    $element = [ordered]@{
        operation = $Operation
        id        = $Id
    }
    if ($BoundParameters.ContainsKey('Name')) { $element['name'] = $Name }
    if ($BoundParameters.ContainsKey('Type')) { $element['type'] = $Type }
    if ($BoundParameters.ContainsKey('Email')) { $element['email'] = $Email }
    if ($BoundParameters.ContainsKey('ManagedAppleId')) { $element['managed_appleid'] = $ManagedAppleId }
    if ($BoundParameters.ContainsKey('AccountId')) { $element['idaccount'] = $AccountId }

    if ($BoundParameters.ContainsKey('Location')) {
        $element['locations'] = @(
            foreach ($loc in $Location) {
                if ($loc -is [System.Collections.IDictionary]) {
                    $entry = [ordered]@{}
                    foreach ($key in $loc.Keys) { $entry[[string]$key] = $loc[$key] }
                    $entry
                }
                else {
                    $loc
                }
            }
        )
    }

    return $element
}
