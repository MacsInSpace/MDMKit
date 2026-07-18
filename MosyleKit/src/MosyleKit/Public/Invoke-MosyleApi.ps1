function Invoke-MosyleApi {
    <#
    .SYNOPSIS
        Calls any Mosyle Manager API endpoint directly.
    .DESCRIPTION
        The escape hatch — and, because every Mosyle operation is a POST to
        /v2/<endpoint> with accessToken in the body, this single cmdlet reaches the
        WHOLE API. accessToken injection, the bearer header, 24h token renewal,
        retry/backoff and in-body error handling are all applied for you; you supply
        the endpoint name and any operation-specific body fields.

        Endpoint names (from the Mosyle API docs) include: listusers, listdevices,
        savedevices (update attributes), lostmode, wipe, restart, shutdown, restart,
        listclasses, save_class, delete_class, listdynamicgroups, and more.
    .EXAMPLE
        Invoke-MosyleApi -Endpoint listusers -Body @{ options = @{ specific_columns = @('id','name') } }
    .EXAMPLE
        Invoke-MosyleApi -Endpoint listdevices
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Endpoint,

        [hashtable] $Body,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    # Read-oriented list/get endpoints run without confirmation; everything else prompts.
    $isRead = $Endpoint -match '^(list|get)'
    if ($isRead -or $PSCmdlet.ShouldProcess("$($resolved.BaseUri)/$Endpoint", 'POST')) {
        $params = @{ Session = $resolved; Endpoint = $Endpoint }
        if ($null -ne $Body) { $params['Body'] = $Body }
        Invoke-MosyleRequest @params
    }
}
