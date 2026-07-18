function ConvertTo-JamfMemberEntry {
    <#
    .SYNOPSIS
        Maps a group-member identifier to its Classic API XML entry.
    .DESCRIPTION
        The MUT heuristic: an all-digit identifier is a Jamf ID unless
        -NumericIdentifiersAreNames is set; anything else is a serial number
        (computers/mobile devices) or username (users).
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)]
        [string] $Identifier,

        # 'serial_number' or 'username'
        [Parameter(Mandatory)]
        [string] $IdentityElement,

        [switch] $NumericIdentifiersAreNames
    )

    $numericId = 0
    if (-not $NumericIdentifiersAreNames -and [int]::TryParse($Identifier, [ref]$numericId)) {
        return [ordered]@{ id = $numericId }
    }
    [ordered]@{ $IdentityElement = $Identifier }
}
