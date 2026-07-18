@{
    RootModule           = 'MosyleKit.psm1'
    ModuleVersion        = '0.3.0'
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
        'Remove-MosyleUser'
        'Set-MosyleDeviceOwner'
        'Invoke-MosyleLostMode'
        'Get-MosyleClass'
        'New-MosyleClass'
        'Remove-MosyleClass'
        'Get-MosyleDeviceGroup'
        'Get-MosyleDeviceGroupDevice'
        'Set-MosyleDeviceGroupMember'
        'Get-MosyleCustomAttribute'
        'New-MosyleCustomAttribute'
        'Set-MosyleCustomAttribute'
        'Remove-MosyleCustomAttribute'
        'Get-MosyleActionLog'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Mosyle', 'MDM', 'Apple', 'macOS', 'iOS', 'Education', 'MacAdmins', 'REST', 'API')
            LicenseUri   = 'https://github.com/MacsInSpace/MDMKit/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/MacsInSpace/MDMKit'
            ReleaseNotes = 'Broad coverage from the full Mosyle API docs: user delete + device assignment, Lost Mode, extended device commands (unassign/clear commands), classes, dynamic device groups, custom device attributes, and action logs. Robust response unwrapping for nested response envelopes.'
            Prerelease   = 'alpha'
        }
    }
}
