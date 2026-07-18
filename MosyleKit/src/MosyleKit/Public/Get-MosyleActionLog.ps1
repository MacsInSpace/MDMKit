function Get-MosyleActionLog {
    <#
    .SYNOPSIS
        Lists admin action logs from Mosyle (POST /adminlogs).
    .DESCRIPTION
        Note: this endpoint's filter object is named 'filter_options' (not 'options').
        Dates are Unix timestamps; -UserId filters to specific admin user IDs.
    .EXAMPLE
        Get-MosyleActionLog
    .EXAMPLE
        Get-MosyleActionLog -StartDate ([DateTimeOffset]::UtcNow.AddDays(-7).ToUnixTimeSeconds())
    #>
    [CmdletBinding()]
    param(
        [long] $StartDate,

        [long] $EndDate,

        [string[]] $UserId,

        [int] $Page,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    $filter = @{}
    if ($PSBoundParameters.ContainsKey('StartDate')) { $filter['start_date'] = $StartDate }
    if ($PSBoundParameters.ContainsKey('EndDate')) { $filter['end_date'] = $EndDate }
    if ($null -ne $UserId -and $UserId.Count -gt 0) { $filter['idusers'] = @($UserId) }

    $body = @{}
    if ($filter.Count -gt 0) { $body['filter_options'] = $filter }
    if ($PSBoundParameters.ContainsKey('Page')) { $body['page'] = $Page }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'adminlogs' -Body $body
    Select-MosyleResult -Response $response -Property 'logs'
}
