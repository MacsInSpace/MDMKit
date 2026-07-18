function New-JamfGroup {
    <#
    .SYNOPSIS
        Creates a smart or static computer, mobile device or user group.
    .DESCRIPTION
        Smart groups take -Criteria (build them with New-JamfCriterion); criteria
        priorities are auto-numbered by array position unless you set them explicitly.
        Static groups can be seeded with -Member (serials/usernames or Jamf IDs,
        auto-detected with the MUT heuristic).
    .EXAMPLE
        New-JamfGroup -Name 'Deploy Wave 1' -Member C02AAA111, C02BBB222
    .EXAMPLE
        New-JamfGroup -Name 'Pre-Sequoia Macs' -Smart -Criteria (
            New-JamfCriterion -Name 'Operating System Version' -SearchType 'less than' -Value '15.0'
        )
    .EXAMPLE
        New-JamfGroup -Type User -Name 'Pilot Users' -Member alice, bob
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low', DefaultParameterSetName = 'Static')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,

        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type = 'Computer',

        [Parameter(Mandatory, ParameterSetName = 'Smart')]
        [switch] $Smart,

        [Parameter(ParameterSetName = 'Smart')]
        [object[]] $Criteria,

        [Parameter(ParameterSetName = 'Static')]
        [string[]] $Member,

        [Parameter(ParameterSetName = 'Static')]
        [switch] $NumericIdentifiersAreNames,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    $config = Get-JamfGroupTypeConfig -Type $Type

    $body = [ordered]@{
        name     = $Name
        is_smart = [bool]$Smart
    }

    if ($Smart -and $null -ne $Criteria -and $Criteria.Count -gt 0) {
        $body['criteria'] = ConvertTo-JamfCriterionList -Criteria $Criteria
    }

    if (-not $Smart -and $null -ne $Member -and $Member.Count -gt 0) {
        $body[$config.List] = @($Member | ForEach-Object {
            ConvertTo-JamfMemberEntry -Identifier $_ -IdentityElement $config.IdentityElement `
                -NumericIdentifiersAreNames:$NumericIdentifiersAreNames
        })
    }

    $xml = ConvertTo-JamfXml -RootElement $config.Root -InputObject $body

    $kind = if ($Smart) { 'smart' } else { 'static' }
    if ($PSCmdlet.ShouldProcess($Name, "Create $kind $Type group")) {
        $response = Invoke-JamfRequest -Session $resolved -Method POST `
            -Path "JSSResource/$($config.Endpoint)/id/0" -Body $xml -Accept 'application/xml'

        $newId = $null
        if ($response -is [xml]) {
            try { $newId = [int]$response.($config.Root).id } catch { $newId = $null }
        }
        if ($null -ne $newId) {
            Get-JamfGroup -Session $resolved -Type $Type -Id $newId
        }
        else {
            Write-Verbose 'Group created, but the new ID could not be parsed from the response.'
            $response
        }
    }
}
