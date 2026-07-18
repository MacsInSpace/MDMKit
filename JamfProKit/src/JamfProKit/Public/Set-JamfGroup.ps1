function Set-JamfGroup {
    <#
    .SYNOPSIS
        Renames a group and/or replaces a smart group's criteria.
    .DESCRIPTION
        Only what you supply changes. To modify static group membership, use
        Set-JamfStaticGroupMember (add/remove/replace with MUT semantics).
    .EXAMPLE
        Set-JamfGroup -Id 15 -NewName 'Deploy Wave 1 (paused)'
    .EXAMPLE
        Set-JamfGroup -Id 8 -Criteria (
            New-JamfCriterion -Name 'Operating System Version' -SearchType 'less than' -Value '16.0'
        )
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [int] $Id,

        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type = 'Computer',

        [string] $NewName,

        [object[]] $Criteria,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $config = Get-JamfGroupTypeConfig -Type $Type
    }

    process {
        $body = [ordered]@{}
        $changes = [System.Collections.Generic.List[string]]::new()

        if ($PSBoundParameters.ContainsKey('NewName') -and $NewName -ne '') {
            $body['name'] = $NewName
            [void]$changes.Add('name')
        }

        if ($PSBoundParameters.ContainsKey('Criteria')) {
            $body['criteria'] = ConvertTo-JamfCriterionList -Criteria @($Criteria)
            [void]$changes.Add('criteria')
        }

        if ($body.Count -eq 0) {
            Write-Verbose "No changes supplied for $Type group $Id; skipping."
            return
        }

        $xml = ConvertTo-JamfXml -RootElement $config.Root -InputObject $body

        if ($PSCmdlet.ShouldProcess("$Type group id $Id", "Update group ($($changes -join ', '))")) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "JSSResource/$($config.Endpoint)/id/$Id" `
                -Body $xml -Accept 'application/xml' | Out-Null
        }
    }
}
