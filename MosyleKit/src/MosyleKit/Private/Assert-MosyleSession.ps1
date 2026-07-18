function Assert-MosyleSession {
    <#
    .SYNOPSIS
        Resolves the session a cmdlet should use, or throws a friendly error.
    #>
    [CmdletBinding()]
    param(
        [object] $Session
    )

    if ($null -ne $Session) {
        if ($Session.PSObject.TypeNames -notcontains 'MosyleKit.Session') {
            throw 'The supplied -Session object is not a MosyleKit session. Use Connect-Mosyle to create one.'
        }
        return $Session
    }
    if ($null -ne $script:DefaultMosyleSession) {
        return $script:DefaultMosyleSession
    }
    throw 'Not connected to Mosyle. Run Connect-Mosyle first.'
}
