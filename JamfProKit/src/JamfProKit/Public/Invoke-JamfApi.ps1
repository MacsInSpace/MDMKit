function Invoke-JamfApi {
    <#
    .SYNOPSIS
        Calls any Jamf Pro API or Classic API endpoint directly.
    .DESCRIPTION
        The escape hatch: full API surface with all the module's plumbing (token
        renewal, retry/backoff, sticky sessions, error normalization) but none of the
        typed cmdlet ergonomics. Use it for endpoints that don't have a typed cmdlet yet.

        Hashtable/PSCustomObject bodies are serialized to JSON automatically; pass an
        XML string or XmlDocument for Classic API writes.
    .PARAMETER Path
        Relative path, e.g. 'api/v1/computers-inventory' or 'JSSResource/policies/id/12'.
    .PARAMETER Query
        Optional query parameters as a hashtable, e.g. @{ 'page-size' = 50 }.
    .EXAMPLE
        Invoke-JamfApi -Path 'api/v1/buildings'
    .EXAMPLE
        Invoke-JamfApi -Method POST -Path 'api/v1/buildings' -Body @{ name = 'HQ' }
    .EXAMPLE
        Invoke-JamfApi -Method PUT -Path 'JSSResource/departments/id/3' -Body '<department><name>IT</name></department>'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [Parameter(Position = 1)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string] $Method = 'GET',

        [object] $Body,

        [hashtable] $Query,

        [string] $ContentType,

        [string] $Accept = 'application/json',

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session

    if ($Method -eq 'GET' -or $PSCmdlet.ShouldProcess("$($resolved.BaseUri)/$($Path.TrimStart('/'))", $Method)) {
        $params = @{
            Session = $resolved
            Method  = $Method
            Path    = $Path
            Accept  = $Accept
        }
        if ($null -ne $Body) { $params['Body'] = $Body }
        if ($null -ne $Query) { $params['Query'] = $Query }
        if ($ContentType) { $params['ContentType'] = $ContentType }
        Invoke-JamfRequest @params
    }
}
