function Remove-MosyleUser {
    <#
    .SYNOPSIS
        Deletes users from Mosyle (POST /users, operation "delete").
    .DESCRIPTION
        Only the user ID is needed. Piped IDs are batched into a single request.
    .EXAMPLE
        Remove-MosyleUser -Id student.1
    .EXAMPLE
        Get-MosyleUser | Where-Object status -eq 'Inactive' | Remove-MosyleUser -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        [void]$elements.Add([ordered]@{ operation = 'delete'; id = $Id })
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) user(s)", 'Delete Mosyle user')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'users' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'elements'
        }
    }
}
