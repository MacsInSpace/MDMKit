function Get-MosyleUser {
    <#
    .SYNOPSIS
        Lists users from Mosyle (POST /listusers).
    .DESCRIPTION
        Returns the user list. -Column restricts the returned fields via the API's
        options.specific_columns (fewer fields = faster, lighter responses). Any other
        documented list options can be passed through with -Options.
    .PARAMETER Column
        Specific columns to return, e.g. id, name, email. Omit for the full record.
    .PARAMETER Options
        Additional documented options merged into the request (e.g. page controls).
    .EXAMPLE
        Get-MosyleUser
    .EXAMPLE
        Get-MosyleUser -Column id, name, email
    #>
    [CmdletBinding()]
    param(
        [string[]] $Column,

        [hashtable] $Options,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    $requestOptions = @{}
    if ($null -ne $Options) {
        foreach ($key in $Options.Keys) { $requestOptions[$key] = $Options[$key] }
    }
    if ($null -ne $Column -and $Column.Count -gt 0) {
        $requestOptions['specific_columns'] = @($Column)
    }

    $body = @{}
    if ($requestOptions.Count -gt 0) { $body['options'] = $requestOptions }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listusers' -Body $body
    Select-MosyleResult -Response $response -Property 'users'
}
