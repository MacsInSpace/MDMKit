function New-JamfCriterion {
    <#
    .SYNOPSIS
        Builds a smart group criterion for New-JamfGroup / Set-JamfGroup.
    .DESCRIPTION
        Returns the criterion structure the Classic API expects. Priority defaults to
        -1, meaning "number me by my position in the array" — New-JamfGroup and
        Set-JamfGroup assign 0, 1, 2… automatically, so you rarely set it yourself.
    .PARAMETER Name
        The criterion field, exactly as shown in the Jamf smart group UI,
        e.g. 'Operating System Version', 'Last Check-in', 'Application Title'.
    .PARAMETER SearchType
        e.g. 'is', 'is not', 'like', 'not like', 'greater than', 'less than',
        'more than x days ago', 'member of'.
    .EXAMPLE
        New-JamfCriterion -Name 'Operating System Version' -SearchType 'less than' -Value '15.0'
    .EXAMPLE
        $criteria = @(
            New-JamfCriterion -Name 'Application Title' -SearchType 'is' -Value 'Slack.app'
            New-JamfCriterion -Name 'Last Check-in' -SearchType 'less than x days ago' -Value '30' -AndOr and
        )
        New-JamfGroup -Name 'Active Slack Macs' -Smart -Criteria $criteria
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Builds an in-memory structure; changes no state.')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, Position = 1)]
        [string] $SearchType,

        [Parameter(Position = 2)]
        [AllowEmptyString()]
        [string] $Value = '',

        [ValidateSet('and', 'or')]
        [string] $AndOr = 'and',

        [int] $Priority = -1,

        [switch] $OpeningParen,

        [switch] $ClosingParen
    )

    [ordered]@{
        name          = $Name
        priority      = $Priority
        and_or        = $AndOr
        search_type   = $SearchType
        value         = $Value
        opening_paren = [bool]$OpeningParen
        closing_paren = [bool]$ClosingParen
    }
}
