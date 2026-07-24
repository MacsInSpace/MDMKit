BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Send-JamfBlankPush' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'posts all management ids to v2/mdm/blank-push in one call' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { [pscustomobject]@{ errorUuids = @() } }
        Send-JamfBlankPush -Session $script:session -ManagementId 'aaa', 'bbb' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v2/mdm/blank-push' -and
            @($Body.clientManagementIds).Count -eq 2 -and
            @($Body.clientManagementIds)[0] -eq 'aaa' -and @($Body.clientManagementIds)[1] -eq 'bbb'
        }
    }

    It 'collects piped management ids into a single request' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { [pscustomobject]@{ errorUuids = @() } }
        @(
            [pscustomobject]@{ managementId = 'aaa' }
            [pscustomobject]@{ managementId = 'bbb' }
            [pscustomobject]@{ managementId = 'ccc' }
        ) | Send-JamfBlankPush -Session $script:session -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            @($Body.clientManagementIds).Count -eq 3
        }
    }

    It 'sends nothing when the target list is empty' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        @() | Send-JamfBlankPush -Session $script:session -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }
}

Describe 'Clear-JamfMdmCommand' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'flushes failed computer commands via the Classic commandflush path' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Clear-JamfMdmCommand -Session $script:session -ComputerId 8, 10 -Status Failed -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Path -eq 'JSSResource/commandflush/computers/id/8,10/status/Failed'
        }
    }

    It 'splits computers and mobile devices into separate flush calls' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Clear-JamfMdmCommand -Session $script:session -ComputerId 8 -MobileDeviceId 42 -Status Pending -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/commandflush/computers/id/8/status/Pending'
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/commandflush/mobiledevices/id/42/status/Pending'
        }
    }

    It 'accepts the combined Pending+Failed status' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Clear-JamfMdmCommand -Session $script:session -MobileDeviceId 42 -Status 'Pending+Failed' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/commandflush/mobiledevices/id/42/status/Pending+Failed'
        }
    }

    It 'sends nothing when no ids are given' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Clear-JamfMdmCommand -Session $script:session -Status Failed -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }
}
