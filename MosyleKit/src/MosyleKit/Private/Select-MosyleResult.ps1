function Select-MosyleResult {
    <#
    .SYNOPSIS
        Unwraps a Mosyle response to its data collection when present.
    .DESCRIPTION
        Mosyle list responses wrap the payload under a named key (e.g. 'users',
        'devices') alongside 'status'/'response'. Returns the first named property
        found, or the whole response when none match — so the raw shape is never lost.
    #>
    [CmdletBinding()]
    param(
        $Response,

        [Parameter(Mandatory)]
        [string[]] $Property
    )

    if ($null -eq $Response -or $Response -is [string]) { return $Response }
    foreach ($name in $Property) {
        $match = $Response.PSObject.Properties.Match($name)
        if ($match.Count -gt 0) { return $match[0].Value }
    }
    return $Response
}
