function New-MosyleUser {
    <#
    .SYNOPSIS
        Creates users in Mosyle (POST /users, operation "save").
    .DESCRIPTION
        Pipelined input is batched into a single request (the API takes an elements
        array), so provisioning a roster is one round-trip. -Location takes one or more
        @{ name = 'School'; grade_level = 'Kindergarten' } entries (grade_level is
        required for students, omit it for staff/teachers).
    .PARAMETER Type
        S (Student), T (Teacher) or STAFF.
    .PARAMETER WelcomeEmail
        Send the Mosyle welcome/login email (only works when Email is set).
    .PARAMETER AccountId
        School account ID (idaccount) — required on District accounts.
    .EXAMPLE
        New-MosyleUser -Id student.1 -Name 'Example Student' -Type S -Email s1@school.org `
            -Location @{ name = 'Cityview Day School'; grade_level = 'Kindergarten' }
    .EXAMPLE
        Import-Csv roster.csv | New-MosyleUser -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

        [switch] $WelcomeEmail,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $element = New-MosyleUserElement -Operation 'save' -BoundParameters $PSBoundParameters `
            -Id $Id -Name $Name -Type $Type -Email $Email -ManagedAppleId $ManagedAppleId `
            -Location $Location -AccountId $AccountId
        # welcome_email is required on create (1 or 0).
        $element['welcome_email'] = [int][bool]$WelcomeEmail
        [void]$elements.Add($element)
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) user(s)", 'Create Mosyle user')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'users' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'elements'
        }
    }
}
