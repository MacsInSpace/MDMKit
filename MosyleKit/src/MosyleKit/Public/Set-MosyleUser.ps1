function Set-MosyleUser {
    <#
    .SYNOPSIS
        Updates users in Mosyle (POST /users, operation "update").
    .DESCRIPTION
        Only the fields you supply change. Pipelined input is batched into a single
        request. -Location replaces the user's location/grade assignment.
    .EXAMPLE
        Set-MosyleUser -Id student.1 -Email new.address@school.org
    .EXAMPLE
        Set-MosyleUser -Id student.1 -Location @{ name = 'Cityview Day School'; grade_level = 'Grade 1' }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('S', 'T', 'STAFF')]
        [string] $Type,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Email,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('managed_appleid')]
        [string] $ManagedAppleId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]] $Location,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('idaccount')]
        [int] $AccountId,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $element = New-MosyleUserElement -Operation 'update' -BoundParameters $PSBoundParameters `
            -Id $Id -Name $Name -Type $Type -Email $Email -ManagedAppleId $ManagedAppleId `
            -Location $Location -AccountId $AccountId
        [void]$elements.Add($element)
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) user(s)", 'Update Mosyle user')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'users' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'elements'
        }
    }
}
