function Get-JamfPagedResult {
    <#
    .SYNOPSIS
        Streams all results from a paged Jamf Pro API list endpoint.
    .DESCRIPTION
        Iterates page/page-size until totalCount is satisfied, emitting each result to
        the pipeline as it arrives. Supports RSQL -Filter, -Sort and an optional -First
        cap. Uses ceiling-based termination (totalCount) plus an empty-page guard so a
        server that under-reports can never loop forever.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session,

        [Parameter(Mandatory)]
        [string] $Path,

        [string] $Filter,

        [string[]] $Sort,

        [ValidateRange(1, 2000)]
        [int] $PageSize = 200,

        # 0 = no cap.
        [int] $First = 0,

        [hashtable] $Query
    )

    $page = 0
    $emitted = 0
    do {
        $pageQuery = @{}
        if ($null -ne $Query) {
            foreach ($key in $Query.Keys) { $pageQuery[$key] = $Query[$key] }
        }
        $pageQuery['page'] = $page
        $pageQuery['page-size'] = $PageSize
        if ($Filter) { $pageQuery['filter'] = $Filter }
        if ($null -ne $Sort -and $Sort.Count -gt 0) { $pageQuery['sort'] = $Sort -join ',' }

        $response = Invoke-JamfRequest -Session $Session -Method GET -Path $Path -Query $pageQuery

        $results = @()
        $totalCount = 0
        if ($null -ne $response) {
            if ($response.PSObject.Properties.Match('results').Count -gt 0 -and $null -ne $response.results) {
                $results = @($response.results)
            }
            if ($response.PSObject.Properties.Match('totalCount').Count -gt 0 -and $null -ne $response.totalCount) {
                $totalCount = [int]$response.totalCount
            }
        }

        foreach ($item in $results) {
            $item
            $emitted++
            if ($First -gt 0 -and $emitted -ge $First) { return }
        }
        $page++
    } while ($emitted -lt $totalCount -and $results.Count -gt 0)
}
