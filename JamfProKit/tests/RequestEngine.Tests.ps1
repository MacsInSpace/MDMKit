BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Invoke-JamfRequest' {
    BeforeEach {
        $script:session = New-TestJamfSession
        Mock -ModuleName JamfProKit Start-Sleep { }
    }

    It 'returns the response content on success' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            New-TestHttpResult -StatusCode 200 -Content ([pscustomobject]@{ hello = 'world' })
        }
        $result = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything'
        }
        $result.hello | Should -Be 'world'
    }

    It 'sends a bearer Authorization header' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 200 }
        InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything' | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfHttp -Times 1 -Exactly -ParameterFilter {
            $Headers.Authorization -eq 'Bearer current-token'
        }
    }

    It 'builds query strings with proper escaping' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 200 }
        InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/computers-inventory' `
                -Query @{ filter = 'general.name=="Mac Studio"' } | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfHttp -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsoluteUri -like '*filter=general.name%3D%3D%22Mac%20Studio%22*'
        }
    }

    It 'retries on 429 honoring Retry-After, then succeeds' {
        $script:callCount = 0
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            $script:callCount++
            if ($script:callCount -eq 1) {
                return New-TestHttpResult -StatusCode 429 -Headers @{ 'Retry-After' = @('3') }
            }
            New-TestHttpResult -StatusCode 200 -Content ([pscustomobject]@{ ok = $true })
        }
        $result = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything'
        }
        $result.ok | Should -BeTrue
        $script:callCount | Should -Be 2
        Should -Invoke -ModuleName JamfProKit Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 3 }
    }

    It 'retries transient 503 with backoff' {
        $script:callCount = 0
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            $script:callCount++
            if ($script:callCount -le 2) { return New-TestHttpResult -StatusCode 503 }
            New-TestHttpResult -StatusCode 200 -Content 'recovered'
        }
        $result = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything'
        }
        $result | Should -Be 'recovered'
        $script:callCount | Should -Be 3
    }

    It 'gives up after MaxRetries and throws' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 503 }
        {
            InModuleScope JamfProKit -Parameters @{ s = $script:session } {
                Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything' -MaxRetries 2
            }
        } | Should -Throw '*HTTP 503*'
    }

    It 'renews the token once and retries on 401' {
        $script:callCount = 0
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            if ("$Uri" -like '*oauth/token') {
                return New-TestHttpResult -StatusCode 200 -Content ([pscustomobject]@{
                    access_token = 'renewed-token'; expires_in = 1199
                })
            }
            $script:callCount++
            if ($script:callCount -eq 1) { return New-TestHttpResult -StatusCode 401 }
            New-TestHttpResult -StatusCode 200 -Content 'authorized'
        }
        $result = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything'
        }
        $result | Should -Be 'authorized'
        ConvertFrom-SecureString $script:session.Token -AsPlainText | Should -Be 'renewed-token'
    }

    It 'does not loop on repeated 401' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            if ("$Uri" -like '*oauth/token') {
                return New-TestHttpResult -StatusCode 200 -Content ([pscustomobject]@{
                    access_token = 'renewed-token'; expires_in = 1199
                })
            }
            New-TestHttpResult -StatusCode 401
        }
        {
            InModuleScope JamfProKit -Parameters @{ s = $script:session } {
                Invoke-JamfRequest -Session $s -Method GET -Path 'api/v1/anything'
            }
        } | Should -Throw '*HTTP 401*'
    }

    It 'surfaces Jamf Pro API error details in the exception message' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp {
            New-TestHttpResult -StatusCode 400 -Content ([pscustomobject]@{
                httpStatus = 400
                errors     = @([pscustomobject]@{ code = 'INVALID_FIELD'; field = 'name'; description = 'Name is required' })
            })
        }
        {
            InModuleScope JamfProKit -Parameters @{ s = $script:session } {
                Invoke-JamfRequest -Session $s -Method POST -Path 'api/v1/things' -Body @{ x = 1 }
            }
        } | Should -Throw '*INVALID_FIELD*Name is required*'
    }

    It 'serializes hashtable bodies to JSON' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 201 -Content ([pscustomobject]@{ id = 1 }) }
        InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Invoke-JamfRequest -Session $s -Method POST -Path 'api/v1/things' -Body @{ name = 'x' } | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfHttp -Times 1 -Exactly -ParameterFilter {
            $Body -is [string] -and $Body -like '*"name":"x"*' -and $ContentType -eq 'application/json'
        }
    }

    It 'sends XmlDocument bodies as XML' {
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 201 }
        InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            $xml = [xml]'<computer><general><asset_tag>A1</asset_tag></general></computer>'
            Invoke-JamfRequest -Session $s -Method PUT -Path 'JSSResource/computers/id/1' -Body $xml | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfHttp -Times 1 -Exactly -ParameterFilter {
            $Body -like '*<asset_tag>A1</asset_tag>*' -and $ContentType -eq 'application/xml'
        }
    }
}

Describe 'Get-JamfPagedResult' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'aggregates all pages' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            $page = [int]$Query['page']
            switch ($page) {
                0 { [pscustomobject]@{ totalCount = 5; results = @(1, 2) } }
                1 { [pscustomobject]@{ totalCount = 5; results = @(3, 4) } }
                2 { [pscustomobject]@{ totalCount = 5; results = @(5) } }
                default { [pscustomobject]@{ totalCount = 5; results = @() } }
            }
        }
        $results = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Get-JamfPagedResult -Session $s -Path 'api/v1/things' -PageSize 2
        }
        $results | Should -Be @(1, 2, 3, 4, 5)
    }

    It 'stops at -First' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            [pscustomobject]@{ totalCount = 100; results = @(1..50) }
        }
        $results = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Get-JamfPagedResult -Session $s -Path 'api/v1/things' -PageSize 50 -First 3
        }
        $results.Count | Should -Be 3
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly
    }

    It 'terminates when the server returns an empty page even if totalCount lies' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            $page = [int]$Query['page']
            if ($page -eq 0) { return [pscustomobject]@{ totalCount = 10; results = @(1, 2) } }
            [pscustomobject]@{ totalCount = 10; results = @() }
        }
        $results = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Get-JamfPagedResult -Session $s -Path 'api/v1/things' -PageSize 2
        }
        $results | Should -Be @(1, 2)
    }

    It 'passes the RSQL filter through' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            [pscustomobject]@{ totalCount = 0; results = @() }
        }
        InModuleScope JamfProKit -Parameters @{ s = $script:session } {
            Get-JamfPagedResult -Session $s -Path 'api/v1/things' -Filter 'name=="x"' | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Query['filter'] -eq 'name=="x"'
        }
    }
}
