BeforeAll {
    $script:ModuleRoot = Join-Path $PSScriptRoot '..' 'src' 'JamfProKit'
    $script:ManifestPath = Join-Path $script:ModuleRoot 'JamfProKit.psd1'
    Import-Module $script:ManifestPath -Force
}

Describe 'JamfProKit module' {
    It 'has a valid manifest' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'imports cleanly' {
        Get-Module JamfProKit | Should -Not -BeNullOrEmpty
    }

    It 'exports exactly the functions declared in the manifest' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath
        $exported = (Get-Module JamfProKit).ExportedFunctions.Keys | Sort-Object
        $declared = $manifest.FunctionsToExport | Sort-Object
        $exported | Should -Be $declared
    }

    It 'has a source file for every exported function' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath
        foreach ($functionName in $manifest.FunctionsToExport) {
            Join-Path $script:ModuleRoot 'Public' "$functionName.ps1" | Should -Exist
        }
    }

    It 'does not export private functions' {
        (Get-Module JamfProKit).ExportedFunctions.Keys | Should -Not -Contain 'Invoke-JamfHttp'
        (Get-Module JamfProKit).ExportedFunctions.Keys | Should -Not -Contain 'Invoke-JamfRequest'
    }

    It 'declares comment-based help with examples on every public function' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath
        foreach ($functionName in $manifest.FunctionsToExport) {
            $help = Get-Help $functionName
            $help.Synopsis | Should -Not -BeNullOrEmpty -Because "$functionName needs a synopsis"
        }
    }
}
