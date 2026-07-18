BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Connect-JamfPro' {
    Context 'OAuth client credentials flow' {
        BeforeEach {
            Mock -ModuleName JamfProKit Invoke-JamfHttp {
                if ("$Uri" -like '*api/oauth/token') {
                    return [pscustomobject]@{
                        StatusCode = 200
                        Headers    = $null
                        Content    = [pscustomobject]@{ access_token = 'oauth-token-value'; expires_in = 1199 }
                    }
                }
                if ("$Uri" -like '*api/v1/jamf-pro-version') {
                    return [pscustomobject]@{
                        StatusCode = 200
                        Headers    = $null
                        Content    = [pscustomobject]@{ version = '11.30.0-t1234' }
                    }
                }
                throw "Unexpected URI in test: $Uri"
            }
        }

        It 'creates a session, mints a token and reads the server version' {
            $session = Connect-JamfPro -Url 'https://test.jamfcloud.com' -ClientId 'abc' `
                -ClientSecret (ConvertTo-SecureString 'shh' -AsPlainText -Force) -PassThru

            $session.AuthType | Should -Be 'OAuth'
            $session.JamfProVersion | Should -Be '11.30.0-t1234'
            ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'oauth-token-value'
            $session.TokenExpiry | Should -BeGreaterThan ([DateTimeOffset]::UtcNow.AddMinutes(15))
        }

        It 'sets the module default session' {
            Connect-JamfPro -Url 'https://test.jamfcloud.com' -ClientId 'abc' `
                -ClientSecret (ConvertTo-SecureString 'shh' -AsPlainText -Force)
            Get-JamfSession | Should -Not -BeNullOrEmpty
            (Get-JamfSession).BaseUri | Should -Be 'https://test.jamfcloud.com'
        }

        It 'strips a trailing slash from the URL' {
            $session = Connect-JamfPro -Url 'https://test.jamfcloud.com/' -ClientId 'abc' `
                -ClientSecret (ConvertTo-SecureString 'shh' -AsPlainText -Force) -PassThru
            $session.BaseUri | Should -Be 'https://test.jamfcloud.com'
        }

        It 'throws a useful error when the client credentials are rejected' {
            Mock -ModuleName JamfProKit Invoke-JamfHttp {
                [pscustomobject]@{ StatusCode = 401; Headers = $null; Content = $null }
            }
            { Connect-JamfPro -Url 'https://test.jamfcloud.com' -ClientId 'bad' `
                    -ClientSecret (ConvertTo-SecureString 'nope' -AsPlainText -Force) } |
                Should -Throw '*client ID*'
        }
    }

    Context 'user credential flow' {
        BeforeEach {
            Mock -ModuleName JamfProKit Invoke-JamfHttp {
                if ("$Uri" -like '*api/v1/auth/token') {
                    return [pscustomobject]@{
                        StatusCode = 200
                        Headers    = $null
                        Content    = [pscustomobject]@{
                            token   = 'user-bearer-token'
                            expires = [DateTimeOffset]::UtcNow.AddMinutes(30).ToString('o')
                        }
                    }
                }
                if ("$Uri" -like '*api/v1/jamf-pro-version') {
                    return [pscustomobject]@{
                        StatusCode = 200
                        Headers    = $null
                        Content    = [pscustomobject]@{ version = '11.30.0' }
                    }
                }
                throw "Unexpected URI in test: $Uri"
            }
        }

        It 'mints a bearer token from a credential' {
            $cred = [pscredential]::new('admin', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
            $session = Connect-JamfPro -Url 'https://test.jamfcloud.com' -Credential $cred -PassThru

            $session.AuthType | Should -Be 'Credential'
            ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'user-bearer-token'
            $session.Credential | Should -Not -BeNullOrEmpty
        }

        It 'discards the credential when -DoNotCacheCredential is used' {
            $cred = [pscredential]::new('admin', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
            $session = Connect-JamfPro -Url 'https://test.jamfcloud.com' -Credential $cred `
                -DoNotCacheCredential -PassThru

            $session.Credential | Should -BeNullOrEmpty
            ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'user-bearer-token'
        }
    }
}

Describe 'Update-JamfSessionToken' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    }

    It 'does nothing when the token has plenty of life left' {
        $session = New-TestJamfSession
        Mock -ModuleName JamfProKit Invoke-JamfHttp { throw 'should not be called' }
        InModuleScope JamfProKit -Parameters @{ s = $session } {
            { Update-JamfSessionToken -Session $s } | Should -Not -Throw
        }
    }

    It 're-mints an OAuth token when inside the expiry buffer' {
        $session = New-TestJamfSession -TokenExpiry ([DateTimeOffset]::UtcNow.AddSeconds(10))
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            [pscustomobject]@{
                StatusCode = 200; Headers = $null
                Content    = [pscustomobject]@{ access_token = 'fresh-token'; expires_in = 1199 }
            }
        }
        InModuleScope JamfProKit -Parameters @{ s = $session } {
            Update-JamfSessionToken -Session $s
        }
        ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'fresh-token'
    }

    It 'uses keep-alive for user sessions with a live token' {
        $session = New-TestJamfSession -AuthType 'Credential' -TokenExpiry ([DateTimeOffset]::UtcNow.AddSeconds(30))
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            if ("$Uri" -like '*keep-alive') {
                return [pscustomobject]@{
                    StatusCode = 200; Headers = $null
                    Content    = [pscustomobject]@{
                        token   = 'kept-alive-token'
                        expires = [DateTimeOffset]::UtcNow.AddMinutes(30).ToString('o')
                    }
                }
            }
            throw "Unexpected URI in test: $Uri"
        }
        InModuleScope JamfProKit -Parameters @{ s = $session } {
            Update-JamfSessionToken -Session $s
        }
        ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'kept-alive-token'
    }

    It 'falls back to re-minting when keep-alive fails' {
        $session = New-TestJamfSession -AuthType 'Credential' -TokenExpiry ([DateTimeOffset]::UtcNow.AddSeconds(30))
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            if ("$Uri" -like '*keep-alive') {
                return [pscustomobject]@{ StatusCode = 401; Headers = $null; Content = $null }
            }
            if ("$Uri" -like '*api/v1/auth/token') {
                return [pscustomobject]@{
                    StatusCode = 200; Headers = $null
                    Content    = [pscustomobject]@{
                        token   = 'reminted-token'
                        expires = [DateTimeOffset]::UtcNow.AddMinutes(30).ToString('o')
                    }
                }
            }
            throw "Unexpected URI in test: $Uri"
        }
        InModuleScope JamfProKit -Parameters @{ s = $session } {
            Update-JamfSessionToken -Session $s
        }
        ConvertFrom-SecureString $session.Token -AsPlainText | Should -Be 'reminted-token'
    }
}
