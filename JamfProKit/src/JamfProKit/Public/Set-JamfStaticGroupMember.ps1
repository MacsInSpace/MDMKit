function Set-JamfStaticGroupMember {
    <#
    .SYNOPSIS
        Adds, removes or replaces members of a static group — The MUT's group mode.
    .DESCRIPTION
        Updates static computer, mobile device or user group membership via the
        Classic API's differential XML (additions/deletions), or replaces the entire
        membership. Identifiers follow MUT's heuristic: integers are treated as Jamf
        IDs, anything else as a serial number (computers/mobile devices) or username
        (user groups). Use -NumericIdentifiersAreNames when usernames are numeric.
    .EXAMPLE
        Set-JamfStaticGroupMember -GroupId 15 -Add C02ABC123, C02DEF456
    .EXAMPLE
        $serials = (Import-Csv ./GroupTemplate.csv).'Serial Numbers or Usernames'
        Set-JamfStaticGroupMember -GroupId 15 -Type MobileDevice -Remove $serials
    .EXAMPLE
        Set-JamfStaticGroupMember -GroupId 8 -Type User -Replace (Import-Csv users.csv).Username -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Delta')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NumericIdentifiersAreNames',
        Justification = 'Used inside the nested ConvertTo-MemberEntry helper; the analyzer cannot see through the closure.')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [int] $GroupId,

        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type = 'Computer',

        [Parameter(ParameterSetName = 'Delta')]
        [string[]] $Add,

        [Parameter(ParameterSetName = 'Delta')]
        [string[]] $Remove,

        [Parameter(Mandatory, ParameterSetName = 'Replace')]
        [AllowEmptyCollection()]
        [string[]] $Replace,

        # Treat all-digit identifiers as names/serials rather than Jamf IDs
        # (The MUT's "My Usernames are Ints" setting).
        [switch] $NumericIdentifiersAreNames,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session

    if ($PSCmdlet.ParameterSetName -eq 'Delta' -and -not $Add -and -not $Remove) {
        throw 'Supply -Add and/or -Remove, or use -Replace.'
    }

    $typeConfig = @{
        Computer     = @{ Endpoint = 'computergroups'; Root = 'computer_group'; List = 'computers'; Additions = 'computer_additions'; Deletions = 'computer_deletions'; IdentityElement = 'serial_number' }
        MobileDevice = @{ Endpoint = 'mobiledevicegroups'; Root = 'mobile_device_group'; List = 'mobile_devices'; Additions = 'mobile_device_additions'; Deletions = 'mobile_device_deletions'; IdentityElement = 'serial_number' }
        User         = @{ Endpoint = 'usergroups'; Root = 'user_group'; List = 'users'; Additions = 'user_additions'; Deletions = 'user_deletions'; IdentityElement = 'username' }
    }[$Type]

    function ConvertTo-MemberEntry {
        param([string] $Identifier)
        $numericId = 0
        if (-not $NumericIdentifiersAreNames -and [int]::TryParse($Identifier, [ref]$numericId)) {
            return [ordered]@{ id = $numericId }
        }
        return [ordered]@{ $typeConfig.IdentityElement = $Identifier }
    }

    $body = [ordered]@{ is_smart = $false }
    $actionLabel = ''
    if ($PSCmdlet.ParameterSetName -eq 'Replace') {
        $body[$typeConfig.List] = @(@($Replace) | ForEach-Object { ConvertTo-MemberEntry -Identifier $_ })
        $actionLabel = "Replace membership with $(@($Replace).Count) member(s)"
    }
    else {
        $counts = [System.Collections.Generic.List[string]]::new()
        if ($Add) {
            $body[$typeConfig.Additions] = @(@($Add) | ForEach-Object { ConvertTo-MemberEntry -Identifier $_ })
            [void]$counts.Add("add $(@($Add).Count)")
        }
        if ($Remove) {
            $body[$typeConfig.Deletions] = @(@($Remove) | ForEach-Object { ConvertTo-MemberEntry -Identifier $_ })
            [void]$counts.Add("remove $(@($Remove).Count)")
        }
        $actionLabel = "Update membership ($($counts -join ', '))"
    }

    $xml = ConvertTo-JamfXml -RootElement $typeConfig.Root -InputObject $body

    if ($PSCmdlet.ShouldProcess("$Type group id $GroupId", $actionLabel)) {
        Invoke-JamfRequest -Session $resolved -Method PUT -Path "JSSResource/$($typeConfig.Endpoint)/id/$GroupId" `
            -Body $xml -Accept 'application/xml' | Out-Null
        Write-Verbose "$actionLabel on $Type group $GroupId succeeded."
    }
}
