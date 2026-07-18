BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Category CRUD' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'creates then refetches a category' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [pscustomobject]@{ id = '9'; href = '/v1/categories/9' } }
            [pscustomobject]@{ id = '9'; name = 'Security Tools'; priority = 9 }
        }
        $result = New-JamfCategory -Session $script:session -Name 'Security Tools' -Confirm:$false
        $result.name | Should -Be 'Security Tools'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq 'api/v1/categories' -and $Body.name -eq 'Security Tools' -and $Body.priority -eq 9
        }
    }

    It 'overlays only supplied fields on update' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'GET') { return [pscustomobject]@{ id = '5'; name = 'Old'; priority = 12 } }
            $null
        }
        Set-JamfCategory -Session $script:session -Id 5 -Name 'New' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and $Path -eq 'api/v1/categories/5' -and $Body.name -eq 'New' -and $Body.priority -eq 12
        }
    }

    It 'makes no API call removing under -WhatIf' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Remove-JamfCategory -Session $script:session -Id 5 -WhatIf
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }
}

Describe 'Group CRUD' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'lists groups from the type-specific property' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            [pscustomobject]@{ user_groups = @([pscustomobject]@{ id = 1; name = 'G1'; is_smart = $false }) }
        }
        $groups = Get-JamfGroup -Session $script:session -Type User
        @($groups)[0].name | Should -Be 'G1'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/usergroups'
        }
    }

    It 'creates a smart group with auto-numbered criteria and refetches it' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [xml]'<computer_group><id>21</id></computer_group>' }
            [pscustomobject]@{ computer_group = [pscustomobject]@{ id = 21; name = 'Pre-Sequoia' } }
        }
        $criteria = @(
            New-JamfCriterion -Name 'Operating System Version' -SearchType 'less than' -Value '15.0'
            New-JamfCriterion -Name 'Last Check-in' -SearchType 'less than x days ago' -Value '30'
        )
        $result = New-JamfGroup -Session $script:session -Name 'Pre-Sequoia' -Smart -Criteria $criteria -Confirm:$false
        $result.id | Should -Be 21
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -eq 'JSSResource/computergroups/id/0' -and
            $Body.OuterXml -like '*<is_smart>true</is_smart>*' -and
            $Body.OuterXml -like '*<criteria><criterion><name>Operating System Version</name><priority>0</priority>*' -and
            $Body.OuterXml -like '*<name>Last Check-in</name><priority>1</priority>*'
        }
    }

    It 'creates a static group with member entries using the id/serial heuristic' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [xml]'<computer_group><id>22</id></computer_group>' }
            [pscustomobject]@{ computer_group = [pscustomobject]@{ id = 22 } }
        }
        New-JamfGroup -Session $script:session -Name 'Wave 1' -Member 'C02AAA', '42' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $Body.OuterXml -like '*<is_smart>false</is_smart>*' -and
            $Body.OuterXml -like '*<computers><computer><serial_number>C02AAA</serial_number></computer><computer><id>42</id></computer></computers>*'
        }
    }

    It 'replaces criteria via Set-JamfGroup' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Set-JamfGroup -Session $script:session -Id 8 -Criteria (
            New-JamfCriterion -Name 'Application Title' -SearchType 'is' -Value 'Slack.app'
        ) -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and
            $Path -eq 'JSSResource/computergroups/id/8' -and
            $Body.OuterXml -like '*<criterion><name>Application Title</name>*'
        }
    }

    It 'deletes against the right endpoint per type' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
        Remove-JamfGroup -Session $script:session -Type MobileDevice -Id 3 -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Path -eq 'JSSResource/mobiledevicegroups/id/3'
        }
    }
}

Describe 'Package CRUD and upload' {
    BeforeEach {
        $script:session = New-TestJamfSession
    }

    It 'creates a package record with all required booleans present' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Method -eq 'POST') { return [pscustomobject]@{ id = '12' } }
            [pscustomobject]@{ id = '12'; packageName = 'Firefox 128'; fileName = 'Firefox-128.0.pkg' }
        }
        New-JamfPackage -Session $script:session -PackageName 'Firefox 128' -FileName 'Firefox-128.0.pkg' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $Path -eq 'api/v1/packages' -and
            $Body.packageName -eq 'Firefox 128' -and
            $Body.categoryId -eq '-1' -and
            $Body.ContainsKey('rebootRequired') -and
            $Body.ContainsKey('suppressEula') -and
            $Body.rebootRequired -eq $false
        }
    }

    Context 'Publish-JamfPackage' {
        BeforeEach {
            $script:pkgFile = Join-Path ([System.IO.Path]::GetTempPath()) 'JamfProKitTest-1.0.pkg'
            Set-Content -Path $script:pkgFile -Value 'fake package bytes'
        }

        AfterEach {
            Remove-Item $script:pkgFile -ErrorAction Ignore
        }

        It 'reuses an existing record matched by fileName and uploads via -Form' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                if ($Method -eq 'GET' -and $Path -eq 'api/v1/packages') {
                    return [pscustomobject]@{ totalCount = 1; results = @([pscustomobject]@{ id = '44'; fileName = 'JamfProKitTest-1.0.pkg' }) }
                }
                if ($Method -eq 'GET') { return [pscustomobject]@{ id = '44'; hashValue = 'abc123' } }
                $null
            }
            $result = Publish-JamfPackage -Session $script:session -Path $script:pkgFile -Confirm:$false
            $result.id | Should -Be '44'
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and
                $Path -eq 'api/v1/packages/44/upload' -and
                $null -ne $Form -and
                $Form['file'].Name -eq 'JamfProKitTest-1.0.pkg'
            }
        }

        It 'creates a record first when none matches the fileName' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                if ($Method -eq 'GET' -and $Path -eq 'api/v1/packages') {
                    return [pscustomobject]@{ totalCount = 0; results = @() }
                }
                if ($Method -eq 'POST' -and $Path -eq 'api/v1/packages') {
                    return [pscustomobject]@{ id = '45' }
                }
                if ($Method -eq 'GET') { return [pscustomobject]@{ id = '45'; packageName = 'JamfProKitTest-1.0' } }
                $null
            }
            Publish-JamfPackage -Session $script:session -Path $script:pkgFile -Confirm:$false | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'api/v1/packages' -and $Body.packageName -eq 'JamfProKitTest-1.0'
            }
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'api/v1/packages/45/upload'
            }
        }

        It 'throws when multiple records match and no -PackageId is given' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                [pscustomobject]@{ totalCount = 2; results = @(
                    [pscustomobject]@{ id = '1'; fileName = 'JamfProKitTest-1.0.pkg' }
                    [pscustomobject]@{ id = '2'; fileName = 'JamfProKitTest-1.0.pkg' }
                ) }
            }
            { Publish-JamfPackage -Session $script:session -Path $script:pkgFile -Confirm:$false -ErrorAction Stop } |
                Should -Throw '*Multiple package records*'
        }

        It 'makes no API call under -WhatIf beyond the record lookup' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                [pscustomobject]@{ totalCount = 0; results = @() }
            }
            Publish-JamfPackage -Session $script:session -Path $script:pkgFile -WhatIf
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly -ParameterFilter {
                $Method -eq 'POST'
            }
        }
    }
}

Describe 'Invoke-JamfRequest -Form passthrough' {
    It 'sends Form to the HTTP layer without body serialization' {
        $session = New-TestJamfSession
        Mock -ModuleName JamfProKit Invoke-JamfHttp { New-TestHttpResult -StatusCode 200 }
        InModuleScope JamfProKit -Parameters @{ s = $session } {
            Invoke-JamfRequest -Session $s -Method POST -Path 'api/v1/packages/1/upload' `
                -Form @{ file = 'placeholder' } | Out-Null
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfHttp -Times 1 -Exactly -ParameterFilter {
            $null -ne $Form -and $Form['file'] -eq 'placeholder' -and $null -eq $Body
        }
    }
}
