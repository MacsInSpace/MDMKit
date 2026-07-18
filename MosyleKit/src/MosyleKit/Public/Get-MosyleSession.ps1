function Get-MosyleSession {
    <#
    .SYNOPSIS
        Returns the current default Mosyle session, if connected.
    .EXAMPLE
        Get-MosyleSession
    #>
    [CmdletBinding()]
    param()

    $script:DefaultMosyleSession
}
