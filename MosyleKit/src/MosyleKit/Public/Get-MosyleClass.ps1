function Get-MosyleClass {
    <#
    .SYNOPSIS
        Lists classes from Mosyle (POST /listclasses).
    .PARAMETER Column
        Specific columns to return, e.g. id, class_name, course_name, location,
        teacher, students, coordinators, account.
    .EXAMPLE
        Get-MosyleClass
    .EXAMPLE
        Get-MosyleClass -Column id, class_name, teacher
    #>
    [CmdletBinding()]
    param(
        [int] $Page,

        [string[]] $Column,

        [hashtable] $Options,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    $requestOptions = @{}
    if ($null -ne $Options) { foreach ($k in $Options.Keys) { $requestOptions[$k] = $Options[$k] } }
    if ($PSBoundParameters.ContainsKey('Page')) { $requestOptions['page'] = $Page }
    if ($null -ne $Column -and $Column.Count -gt 0) { $requestOptions['specific_columns'] = @($Column) }

    $body = @{}
    if ($requestOptions.Count -gt 0) { $body['options'] = $requestOptions }

    $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listclasses' -Body $body
    Select-MosyleResult -Response $response -Property 'classes'
}
