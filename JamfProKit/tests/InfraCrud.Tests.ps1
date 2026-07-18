BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Building and department CRUD' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'creates a building with full address fields' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [pscustomobject]@{ id = '3' } }
            [pscustomobject]@{ id = '3'; name = 'HQ' }
        }
        New-JamfBuilding -Session $script:session -Name 'HQ' -City 'Melbourne' -Country 'Australia' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v1/buildings' -and
            $Body.name -eq 'HQ' -and $Body.city -eq 'Melbourne' -and $Body.country -eq 'Australia' -and
            $Body.ContainsKey('streetAddress1')
        }
    }

    It 'overlays only supplied building fields on update' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') {
                return [pscustomobject]@{ id = '3'; name = 'HQ'; city = 'Melbourne'; country = 'Australia'; streetAddress1 = 'Old St' }
            }
            $null
        }
        Set-JamfBuilding -Session $script:session -Id 3 -StreetAddress1 '1 New Campus Way' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'api/v1/buildings/3' -and
            $Body.streetAddress1 -eq '1 New Campus Way' -and $Body.city -eq 'Melbourne'
        }
    }

    It 'renames a department' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Set-JamfDepartment -Session $script:session -Id 7 -Name 'Finance & Payroll' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'api/v1/departments/7' -and $Body.name -eq 'Finance & Payroll'
        }
    }
}

Describe 'Extension attribute CRUD' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'creates a computer script EA against the computer endpoint' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [pscustomobject]@{ id = '4' } }
            [pscustomobject]@{ id = '4'; name = 'Battery Cycle Count' }
        }
        New-JamfExtensionAttribute -Session $script:session -Name 'Battery Cycle Count' `
            -InputType SCRIPT -DataType INTEGER -ScriptContents '#!/bin/zsh' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v1/computer-extension-attributes' -and
            $Body.inputType -eq 'SCRIPT' -and $Body.dataType -eq 'INTEGER' -and
            $Body.scriptContents -eq '#!/bin/zsh' -and $Body.enabled -eq $true
        }
    }

    It 'routes -Type MobileDevice to the mobile endpoint with popup choices' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [pscustomobject]@{ id = '2' } }
            [pscustomobject]@{ id = '2' }
        }
        New-JamfExtensionAttribute -Session $script:session -Type MobileDevice -Name 'Cart Number' `
            -InputType POPUP -PopupChoices '1', '2', '3' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v1/mobile-device-extension-attributes' -and
            (@($Body.popupMenuChoices) -join ',') -eq '1,2,3'
        }
    }

    It 'overlays EA updates onto the current record' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') {
                return [pscustomobject]@{ id = '4'; name = 'Battery Cycle Count'; inputType = 'SCRIPT'; scriptContents = 'old'; enabled = $true }
            }
            $null
        }
        Set-JamfExtensionAttribute -Session $script:session -Id 4 -ScriptContents 'new' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'api/v1/computer-extension-attributes/4' -and
            $Body.scriptContents -eq 'new' -and $Body.name -eq 'Battery Cycle Count'
        }
    }
}

Describe 'MDM commands' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'resolves a serial to managementId and posts the command' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') {
                return [pscustomobject]@{
                    totalCount = 1
                    results    = @([pscustomobject]@{ id = '12'; general = [pscustomobject]@{ managementId = 'mgmt-uuid-1' } })
                }
            }
            [pscustomobject]@{ id = 'cmd-1' }
        }
        Send-JamfMdmCommand -Session $script:session -CommandType RESTART_DEVICE -ComputerSerial C02ABC123 -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v2/mdm/commands' -and
            $Body.clientData[0].managementId -eq 'mgmt-uuid-1' -and
            $Body.commandData.commandType -eq 'RESTART_DEVICE'
        }
    }

    It 'merges -CommandData into the command body' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { [pscustomobject]@{ id = 'cmd-2' } }
        Send-JamfMdmCommand -Session $script:session -CommandType SET_RECOVERY_LOCK `
            -ManagementId 'mgmt-uuid-9' -CommandData @{ newPassword = 'S3cret' } -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.commandData.commandType -eq 'SET_RECOVERY_LOCK' -and $Body.commandData.newPassword -eq 'S3cret'
        }
    }

    It 'throws when the serial resolves to an unmanaged computer' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            [pscustomobject]@{ totalCount = 1; results = @([pscustomobject]@{ id = '12'; general = [pscustomobject]@{ managementId = '' } }) }
        }
        { Send-JamfMdmCommand -Session $script:session -CommandType RESTART_DEVICE -ComputerSerial C02X -Confirm:$false } |
            Should -Throw '*no managementId*'
    }

    It 'redeploys the framework by serial' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') {
                return [pscustomobject]@{ totalCount = 1; results = @([pscustomobject]@{ id = '55'; general = [pscustomobject]@{ managementId = 'x' } }) }
            }
            [pscustomobject]@{ deviceId = '55' }
        }
        Invoke-JamfFrameworkRedeploy -Session $script:session -SerialNumber C02ABC123 -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v1/jamf-management-framework/redeploy/55'
        }
    }

    It 'makes no API call under -WhatIf' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Send-JamfMdmCommand -Session $script:session -CommandType ERASE_DEVICE -ManagementId 'mgmt-1' -WhatIf | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
}

Describe 'LAPS' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'lists accounts by managementId' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            [pscustomobject]@{ totalCount = 1; results = @([pscustomobject]@{ username = 'jamfadmin'; userSource = 'PRESTAGE' }) }
        }
        $accounts = Get-JamfLapsAccount -Session $script:session -ManagementId 'mgmt-uuid-1'
        @($accounts)[0].username | Should -Be 'jamfadmin'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'api/v2/local-admin-password/mgmt-uuid-1/accounts'
        }
    }

    It 'fetches a password by serial and returns a SecureString by default' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Path -like 'api/v1/computers-inventory*') {
                return [pscustomobject]@{ totalCount = 1; results = @([pscustomobject]@{ id = '12'; general = [pscustomobject]@{ managementId = 'mgmt-uuid-1' } }) }
            }
            [pscustomobject]@{ password = 'Hunter2!' }
        }
        $entry = Get-JamfLapsPassword -Session $script:session -SerialNumber C02ABC123 -Username jamfadmin
        $entry.Password | Should -BeOfType [securestring]
        ConvertFrom-SecureString $entry.Password -AsPlainText | Should -Be 'Hunter2!'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'api/v2/local-admin-password/mgmt-uuid-1/account/jamfadmin/password'
        }
    }

    It 'returns plain text with -AsPlainText' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { [pscustomobject]@{ password = 'Hunter2!' } }
        Get-JamfLapsPassword -Session $script:session -ManagementId 'mgmt-1' -Username jamfadmin -AsPlainText |
            Should -Be 'Hunter2!'
    }

    It 'overlays LAPS settings on update' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') {
                return [pscustomobject]@{ autoDeployEnabled = $false; passwordRotationTime = 3600; autoRotateEnabled = $false; autoRotateExpirationTime = 7776000 }
            }
            $null
        }
        Set-JamfLapsSetting -Session $script:session -AutoDeployEnabled $true -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'api/v2/local-admin-password/settings' -and
            $Body.autoDeployEnabled -eq $true -and $Body.passwordRotationTime -eq 3600
        }
    }
}
