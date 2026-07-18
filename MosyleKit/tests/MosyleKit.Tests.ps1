BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'MosyleKit' 'MosyleKit.psd1') -Force

    function New-TestMosyleSession {
        param([datetimeoffset] $TokenExpiry = [DateTimeOffset]::UtcNow.AddHours(20))
        [pscustomobject]@{
            PSTypeName  = 'MosyleKit.Session'
            BaseUri     = 'https://managerapi.mosyle.com/v2'
            AccessToken = (ConvertTo-SecureString 'access-token' -AsPlainText -Force)
            Credential  = [pscredential]::new('admin@school.org', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
            Token       = (ConvertTo-SecureString 'Bearer jwt-abc' -AsPlainText -Force)
            TokenExpiry = $TokenExpiry
        }
    }
}

Describe 'MosyleKit module' {
    It 'has a valid manifest and exports what it declares' {
        $manifestPath = Join-Path $PSScriptRoot '..' 'src' 'MosyleKit' 'MosyleKit.psd1'
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        (Get-Module MosyleKit).ExportedFunctions.Keys | Sort-Object | Should -Be ($manifest.FunctionsToExport | Sort-Object)
    }

    It 'has help with a synopsis on every public function' {
        foreach ($functionName in (Get-Module MosyleKit).ExportedFunctions.Keys) {
            (Get-Help $functionName).Synopsis | Should -Not -BeNullOrEmpty -Because "$functionName needs help"
        }
    }
}

Describe 'Login and token renewal' {
    It 'reads the bearer token from the login response header and sets a 24h expiry' {
        $session = New-TestMosyleSession -TokenExpiry ([DateTimeOffset]::UtcNow.AddMinutes(1))
        $session.Token = $null
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            [pscustomobject]@{
                StatusCode = 200
                Headers    = @{ Authorization = @('Bearer fresh-jwt') }
                Content    = [pscustomobject]@{ UserID = '1'; email = 'admin@school.org' }
            }
        }
        InModuleScope MosyleKit -Parameters @{ s = $session } {
            Update-MosyleSessionToken -Session $s
        }
        ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'Bearer fresh-jwt'
        $session.TokenExpiry | Should -BeGreaterThan ([DateTimeOffset]::UtcNow.AddHours(23))
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleHttp -Times 1 -Exactly -ParameterFilter {
            $Uri -like '*/login' -and $Body -like '*"password":"pw"*' -and $Body -like '*"email":"admin@school.org"*'
        }
    }

    It 'does not re-login when the token is still fresh' {
        $session = New-TestMosyleSession
        Mock -ModuleName MosyleKit Invoke-MosyleHttp { throw 'should not log in' }
        InModuleScope MosyleKit -Parameters @{ s = $session } {
            { Update-MosyleSessionToken -Session $s } | Should -Not -Throw
        }
    }

    It 'throws a clear error when login fails' {
        $session = New-TestMosyleSession -TokenExpiry ([DateTimeOffset]::UtcNow.AddMinutes(1))
        $session.Token = $null
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            [pscustomobject]@{ StatusCode = 401; Headers = $null; Content = $null }
        }
        {
            InModuleScope MosyleKit -Parameters @{ s = $session } { Update-MosyleSessionToken -Session $s }
        } | Should -Throw '*login failed*'
    }
}

Describe 'Request engine' {
    BeforeEach {
        $script:session = New-TestMosyleSession
        Mock -ModuleName MosyleKit Start-Sleep { }
    }

    It 'injects accessToken into the body and the bearer into the header' {
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            [pscustomobject]@{ StatusCode = 200; Headers = $null; Content = [pscustomobject]@{ status = 'OK'; users = @() } }
        }
        InModuleScope MosyleKit -Parameters @{ s = $script:session } {
            Invoke-MosyleRequest -Session $s -Endpoint 'listusers' | Out-Null
        }
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleHttp -Times 1 -Exactly -ParameterFilter {
            $Uri -like '*/v2/listusers' -and
            $Body -like '*"accessToken":"access-token"*' -and
            $Headers.Authorization -eq 'Bearer jwt-abc'
        }
    }

    It 'merges extra body fields alongside accessToken' {
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            [pscustomobject]@{ StatusCode = 200; Headers = $null; Content = [pscustomobject]@{ users = @() } }
        }
        InModuleScope MosyleKit -Parameters @{ s = $script:session } {
            Invoke-MosyleRequest -Session $s -Endpoint 'listusers' -Body @{ options = @{ specific_columns = @('id', 'name') } } | Out-Null
        }
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleHttp -Times 1 -Exactly -ParameterFilter {
            $Body -like '*specific_columns*' -and $Body -like '*"id"*' -and $Body -like '*accessToken*'
        }
    }

    It 'retries transient 500 then succeeds' {
        $script:calls = 0
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            $script:calls++
            if ($script:calls -eq 1) { return [pscustomobject]@{ StatusCode = 500; Headers = $null; Content = $null } }
            [pscustomobject]@{ StatusCode = 200; Headers = $null; Content = [pscustomobject]@{ status = 'OK' } }
        }
        InModuleScope MosyleKit -Parameters @{ s = $script:session } {
            Invoke-MosyleRequest -Session $s -Endpoint 'listusers'
        } | Out-Null
        $script:calls | Should -Be 2
    }

    It 're-logs in once and retries on 403' {
        $script:calls = 0
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            if ($Uri -like '*/login') {
                return [pscustomobject]@{ StatusCode = 200; Headers = @{ Authorization = @('Bearer renewed') }; Content = $null }
            }
            $script:calls++
            if ($script:calls -eq 1) { return [pscustomobject]@{ StatusCode = 403; Headers = $null; Content = $null } }
            [pscustomobject]@{ StatusCode = 200; Headers = $null; Content = [pscustomobject]@{ status = 'OK' } }
        }
        InModuleScope MosyleKit -Parameters @{ s = $script:session } {
            Invoke-MosyleRequest -Session $s -Endpoint 'listusers'
        } | Out-Null
        ConvertFrom-SecureString $script:session.Token -AsPlainText | Should -Be 'Bearer renewed'
    }

    It 'surfaces in-body ERROR status as a terminating error' {
        Mock -ModuleName MosyleKit Invoke-MosyleHttp {
            [pscustomobject]@{ StatusCode = 200; Headers = $null; Content = [pscustomobject]@{ status = 'ERROR'; message = 'Invalid access token' } }
        }
        {
            InModuleScope MosyleKit -Parameters @{ s = $script:session } {
                Invoke-MosyleRequest -Session $s -Endpoint 'listusers'
            }
        } | Should -Throw '*Invalid access token*'
    }
}

Describe 'Typed cmdlets' {
    BeforeEach {
        $script:session = New-TestMosyleSession
    }

    It 'Get-MosyleUser sends listusers with specific_columns and unwraps users' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest {
            [pscustomobject]@{ status = 'OK'; users = @([pscustomobject]@{ id = 1; name = 'A' }) }
        }
        $users = Get-MosyleUser -Session $script:session -Column id, name
        @($users)[0].name | Should -Be 'A'
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'listusers' -and (@($Body.options.specific_columns) -join ',') -eq 'id,name'
        }
    }

    It 'Get-MosyleDevice passes the os option and unwraps devices' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest {
            [pscustomobject]@{ status = 'OK'; devices = @([pscustomobject]@{ serial_number = 'S1' }) }
        }
        (Get-MosyleDevice -Session $script:session -Os ios)[0].serial_number | Should -Be 'S1'
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'listdevices' -and $Body.options.os -eq 'ios'
        }
    }

    It 'Invoke-MosyleApi reaches any endpoint and runs reads without confirmation' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest { [pscustomobject]@{ status = 'OK'; groups = @() } }
        Invoke-MosyleApi -Session $script:session -Endpoint listdynamicgroups | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'listdynamicgroups'
        }
    }

    It 'Invoke-MosyleApi honors -WhatIf for non-read endpoints' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest { $null }
        Invoke-MosyleApi -Session $script:session -Endpoint wipe -Body @{ devices = @('u1') } -WhatIf
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 0 -Exactly
    }

    It 'Get-MosyleDevice passes the full filter set under options' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest { [pscustomobject]@{ status = 'OK'; devices = @() } }
        Get-MosyleDevice -Session $script:session -Os mac -SerialNumber S1, S2 -Column serial_number -Page 2 | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.options.os -eq 'mac' -and
            (@($Body.options.serial_numbers) -join ',') -eq 'S1,S2' -and
            $Body.options.page -eq 2 -and
            (@($Body.options.specific_columns) -join ',') -eq 'serial_number'
        }
    }
}

Describe 'Invoke-MosyleDeviceCommand' {
    BeforeEach {
        $script:session = New-TestMosyleSession
        Mock -ModuleName MosyleKit Invoke-MosyleRequest {
            [pscustomobject]@{ status = 'OK'; response = @([pscustomobject]@{ status = 'COMMAND_SENT'; info = 'Command sent successfully.' }) }
        }
    }

    It 'restarts a device group via /bulkops with string group IDs' {
        Invoke-MosyleDeviceCommand -Session $script:session -Command Restart -Group 210 -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'bulkops' -and
            $Body.elements[0].operation -eq 'restart_devices' -and
            $Body.elements[0].groups[0] -eq '210'
        }
    }

    It 'accumulates piped UDIDs into one wipe element with options' {
        $devices = @([pscustomobject]@{ deviceudid = 'U1' }, [pscustomobject]@{ deviceudid = 'U2' })
        $devices | Invoke-MosyleDeviceCommand -Session $script:session -Command Wipe -RevokeVppLicenses -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.elements[0].operation -eq 'wipe_devices' -and
            (@($Body.elements[0].devices) -join ',') -eq 'U1,U2' -and
            $Body.elements[0].options.RevokeVPPLicenses -eq 'true'
        }
    }

    It 'builds a lock element with pincode and message at element level' {
        Invoke-MosyleDeviceCommand -Session $script:session -Command Lock -Device U1 `
            -Pincode 123456 -LockMessage 'Return to IT' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.elements[0].operation -eq 'lock_device' -and
            $Body.elements[0].pincode -eq '123456' -and
            $Body.elements[0].lockmessage -eq 'Return to IT'
        }
    }

    It 'sends lost_message for activation lock' {
        Invoke-MosyleDeviceCommand -Session $script:session -Command EnableActivationLock -Device U1 `
            -LostMessage 'Lost device' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.elements[0].operation -eq 'enable_activationlock' -and
            $Body.elements[0].lost_message -eq 'Lost device'
        }
    }

    It 'warns on devices_notfound in the response' {
        Mock -ModuleName MosyleKit Invoke-MosyleRequest {
            [pscustomobject]@{ status = 'OK'; response = @([pscustomobject]@{ devices_notfound = @('U9'); status = 'COMMAND_SENT'; info = 'ok' }) }
        }
        Invoke-MosyleDeviceCommand -Session $script:session -Command Restart -Device U9 -Confirm:$false `
            -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        $warnings | Should -Not -BeNullOrEmpty
    }

    It 'throws when no target is supplied' {
        { Invoke-MosyleDeviceCommand -Session $script:session -Command Restart -Confirm:$false } |
            Should -Throw '*-Device*-Group*'
    }

    It 'makes no API call under -WhatIf' {
        Invoke-MosyleDeviceCommand -Session $script:session -Command Wipe -Device U1 -WhatIf | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 0 -Exactly
    }
}

Describe 'Set-MosyleDeviceAttribute' {
    BeforeEach {
        $script:session = New-TestMosyleSession
        Mock -ModuleName MosyleKit Invoke-MosyleRequest { [pscustomobject]@{ status = 'OK'; elements = @() } }
    }

    It 'sends serialnumber-keyed elements with comma-joined tags to /devices' {
        Set-MosyleDeviceAttribute -Session $script:session -SerialNumber XABC -Tag 'Lab', '1:1' -Name 'iPad 7' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'devices' -and
            $Body.elements[0].serialnumber -eq 'XABC' -and
            $Body.elements[0].tags -eq 'Lab,1:1' -and
            $Body.elements[0].name -eq 'iPad 7'
        }
    }

    It 'batches piped rows into a single request' {
        $rows = @(
            [pscustomobject]@{ SerialNumber = 'S1'; AssetTag = 'A1' }
            [pscustomobject]@{ SerialNumber = 'S2'; AssetTag = 'A2' }
        )
        $rows | Set-MosyleDeviceAttribute -Session $script:session -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            @($Body.elements).Count -eq 2 -and $Body.elements[1].asset_tag -eq 'A2'
        }
    }
}

Describe 'User create/update' {
    BeforeEach {
        $script:session = New-TestMosyleSession
        Mock -ModuleName MosyleKit Invoke-MosyleRequest {
            [pscustomobject]@{ status = 'OK'; elements = @([pscustomobject]@{ id = 'student.1'; status = 'OK' }) }
        }
    }

    It 'creates a user with operation save, welcome_email flag and normalized locations' {
        New-MosyleUser -Session $script:session -Id student.1 -Name 'Example Student' -Type S -Email s1@school.org `
            -Location @{ name = 'Cityview Day School'; grade_level = 'Kindergarten' } -WelcomeEmail -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Endpoint -eq 'users' -and
            $Body.elements[0].operation -eq 'save' -and
            $Body.elements[0].id -eq 'student.1' -and
            $Body.elements[0].type -eq 'S' -and
            $Body.elements[0].welcome_email -eq 1 -and
            $Body.elements[0].locations[0].grade_level -eq 'Kindergarten'
        }
    }

    It 'defaults welcome_email to 0 on create' {
        New-MosyleUser -Session $script:session -Id staff.1 -Name 'Staff' -Type STAFF -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.elements[0].welcome_email -eq 0
        }
    }

    It 'updates only supplied fields with operation update' {
        Set-MosyleUser -Session $script:session -Id student.1 -Email new@school.org -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            $Body.elements[0].operation -eq 'update' -and
            $Body.elements[0].id -eq 'student.1' -and
            $Body.elements[0].email -eq 'new@school.org' -and
            -not $Body.elements[0].Contains('name') -and
            -not $Body.elements[0].Contains('welcome_email')
        }
    }

    It 'batches a piped roster into one create call' {
        $roster = @(
            [pscustomobject]@{ Id = 's1'; Name = 'One'; Type = 'S' }
            [pscustomobject]@{ Id = 's2'; Name = 'Two'; Type = 'S' }
        )
        $roster | New-MosyleUser -Session $script:session -Confirm:$false | Out-Null
        Should -Invoke -ModuleName MosyleKit Invoke-MosyleRequest -Times 1 -Exactly -ParameterFilter {
            @($Body.elements).Count -eq 2 -and $Body.elements[1].id -eq 's2'
        }
    }
}
