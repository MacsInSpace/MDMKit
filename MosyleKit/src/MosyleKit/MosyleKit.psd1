@{
    RootModule           = 'MosyleKit.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'e2d6b1f4-73a8-4c19-9f52-6a4b8c0d3e71'
    Author               = 'Craig Hair'
    CompanyName          = 'Unknown'
    Copyright            = '(c) 2026 Craig Hair. MIT License.'
    Description          = 'A modern, cross-platform PowerShell 7 module for the Mosyle Manager API. JWT auth with automatic renewal, a generic request cmdlet covering the whole API, and typed cmdlets for the common operations. Sibling of JamfProKit / JamfSchoolKit.'
    PowerShellVersion    = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport    = @(
        'Connect-Mosyle'
        'Disconnect-Mosyle'
        'Get-MosyleSession'
        'Invoke-MosyleApi'
        'Get-MosyleUser'
        'Get-MosyleDevice'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Mosyle', 'MDM', 'Apple', 'macOS', 'iOS', 'Education', 'MacAdmins', 'REST', 'API')
            LicenseUri   = 'https://github.com/MacsInSpace/MDMKit/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/MacsInSpace/MDMKit'
            ReleaseNotes = 'Initial release: JWT session core (accessToken + admin email/password) with 24h auto-renewal, generic Invoke-MosyleApi covering the whole API, and typed cmdlets for listing users and devices.'
            Prerelease   = 'alpha'
        }
    }
}
