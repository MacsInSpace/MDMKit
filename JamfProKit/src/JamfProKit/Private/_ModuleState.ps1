function Initialize-JamfProKitState {
    <#
    .SYNOPSIS
        Initializes module-scoped state and argument completers. Runs at import.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification = 'The completer scriptblock signature is fixed by Register-ArgumentCompleter; not all parameters are used.')]
    param()

    $script:JamfApiIndexCache = @{}
    $script:JamfProKitCacheDir = Join-Path ([Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)) '.jamfprokit' 'cache'

    # Tab completion for -Resource on the spec-driven generic cmdlets. Cache-only:
    # a completer must never hit the network, so it offers nothing until an index
    # has been built (first generic-cmdlet call) or loaded from disk.
    $resourceCompleter = {
        param($commandName, $parameterName, $wordToComplete)
        try {
            $session = $script:DefaultJamfSession
            if ($null -eq $session) { return }
            $index = Get-JamfApiIndex -Session $session -CacheOnly
            if ($null -eq $index) { return }
            $index['resources'].Keys |
                Where-Object { $_ -like "$wordToComplete*" } |
                Sort-Object |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
        catch {
            Write-Debug "Resource completion skipped: $_"  # completion must never throw
        }
    }
    Register-ArgumentCompleter -ParameterName 'Resource' -ScriptBlock $resourceCompleter -CommandName @(
        'Get-JamfObject', 'New-JamfObject', 'Set-JamfObject', 'Remove-JamfObject',
        'New-JamfObjectTemplate', 'Get-JamfApiResource'
    )
}

Initialize-JamfProKitState
