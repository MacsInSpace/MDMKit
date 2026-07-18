@{
    RootModule           = 'MosyleKit.psm1'
    ModuleVersion        = '0.2.0'
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
        'Invoke-MosyleDeviceCommand'
        'Set-MosyleDeviceAttribute'
        'New-MosyleUser'
        'Set-MosyleUser'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Mosyle', 'MDM', 'Apple', 'macOS', 'iOS', 'Education', 'MacAdmins', 'REST', 'API')
            LicenseUri   = 'https://github.com/MacsInSpace/MDMKit/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/MacsInSpace/MDMKit'
            ReleaseNotes = 'Verified device and user operations: list devices (os/tag/serial/column filters), bulk device commands (restart/shutdown/wipe/lock/activation lock via /bulkops), device attribute updates, and bulk user create/update. Shapes confirmed from the Mosyle API docs.'
            Prerelease   = 'alpha'
        }
    }
}
