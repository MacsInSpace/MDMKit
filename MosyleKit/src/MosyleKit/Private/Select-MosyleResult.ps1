function Select-MosyleResult {
    <#
    .SYNOPSIS
        Unwraps a Mosyle response to its data collection when present.
    .DESCRIPTION
        Mosyle responses are inconsistent: some put the payload at the top level
        (e.g. { status, elements } for /users, { status, devices } for /devices update),
        while list endpoints nest it under a 'response' object or array
        (e.g. { status, response: { devices, rows, page } } for /listdevices,
        { status, response: [ { groups, rows, page } ] } for /listdevicegroups).

        This checks, in order: the named property at the top level, then inside a
        'response' object, then inside the first element of a 'response' array — and
        falls back to the whole response so nothing is ever lost.
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

    $responseMatch = $Response.PSObject.Properties.Match('response')
    if ($responseMatch.Count -gt 0 -and $null -ne $responseMatch[0].Value) {
        $inner = $responseMatch[0].Value
        $probe = if ($inner -is [System.Collections.IEnumerable] -and $inner -isnot [string]) { @($inner)[0] } else { $inner }
        if ($null -ne $probe -and $probe -isnot [string]) {
            foreach ($name in $Property) {
                $match = $probe.PSObject.Properties.Match($name)
                if ($match.Count -gt 0) { return $match[0].Value }
            }
        }
        return $inner
    }

    return $Response
}
