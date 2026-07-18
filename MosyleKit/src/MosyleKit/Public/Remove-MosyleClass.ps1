function Remove-MosyleClass {
    <#
    .SYNOPSIS
        Deletes a class from Mosyle (POST /classes, operation "delete").
    .EXAMPLE
        Remove-MosyleClass -Id sci8
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
        if ($PSCmdlet.ShouldProcess("$($elements.Count) class(es)", 'Delete Mosyle class')) {
            Invoke-MosyleRequest -Session $resolved -Endpoint 'classes' -Body @{ elements = @($elements) } | Out-Null
        }
    }
}
