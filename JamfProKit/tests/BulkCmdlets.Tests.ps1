BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Update-JamfComputer' {
    BeforeEach {
        $script:session = New-TestJamfSession
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
    }

    It 'PUTs only the supplied fields to the Classic API by serial number' {
        Update-JamfComputer -Session $script:session -SerialNumber 'C02ABC123' -AssetTag 'A-1' -Building 'HQ' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and
            $Path -eq 'JSSResource/computers/serialnumber/C02ABC123' -and
            $Body.OuterXml -like '*<asset_tag>A-1</asset_tag>*' -and
            $Body.OuterXml -like '*<building>HQ</building>*' -and
            $Body.OuterXml -notlike '*<name>*'
        }
    }

    It 'binds directly from a MUT computer template CSV row' {
        $mutRow = [pscustomobject]@{
            'Computer Serial' = 'C02MUT001'
            'Display Name'    = 'Kiosk-01'
            'Asset Tag'       = ''
            'Username'        = 'jappleseed'
            'Site (ID or Name)' = '3'
        }
        $result = $mutRow | Update-JamfComputer -Session $script:session -Confirm:$false
        $result.Status | Should -Be 'Updated'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/computers/serialnumber/C02MUT001' -and
            $Body.OuterXml -like '*<name>Kiosk-01</name>*' -and
            $Body.OuterXml -like '*<username>jappleseed</username>*' -and
            $Body.OuterXml -like '*<site><id>3</id></site>*' -and
            $Body.OuterXml -notlike '*asset_tag*'
        }
    }

    It 'treats blank as unchanged and CLEAR! as wipe (MUT semantics)' {
        Update-JamfComputer -Session $script:session -SerialNumber 'C02ABC123' `
            -AssetTag 'CLEAR!' -Room '' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<asset_tag></asset_tag>*' -or $Body.OuterXml -like '*<asset_tag />*'
        }
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<room>*'
        }
    }

    It 'unassigns the site with id -1 on CLEAR!' {
        Update-JamfComputer -Session $script:session -SerialNumber 'C02ABC123' -Site 'CLEAR!' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<site><id>-1</id></site>*'
        }
    }

    It 'maps site names vs ids correctly' {
        Update-JamfComputer -Session $script:session -SerialNumber 'X' -Site 'Head Office' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<site><name>Head Office</name></site>*'
        }
    }

    It 'skips rows with no changes without calling the API' {
        Update-JamfComputer -Session $script:session -SerialNumber 'C02ABC123' -AssetTag '' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }

    It 'makes no API call under -WhatIf' {
        Update-JamfComputer -Session $script:session -SerialNumber 'C02ABC123' -AssetTag 'A-1' -WhatIf | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }

    It 'continues past per-row failures, emitting a Failed result object' {
        Mock -ModuleName JamfProKit Invoke-JamfRequest { throw 'Jamf API request failed: HTTP 404' }
        $rows = @(
            [pscustomobject]@{ 'Computer Serial' = 'GOOD1'; 'Asset Tag' = 'A' }
            [pscustomobject]@{ 'Computer Serial' = 'BAD01'; 'Asset Tag' = 'B' }
        )
        $results = $rows | Update-JamfComputer -Session $script:session -Confirm:$false -ErrorAction SilentlyContinue
        @($results).Count | Should -Be 2
        @($results)[0].Status | Should -Be 'Failed'
        @($results)[1].Status | Should -Be 'Failed'
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 2 -Exactly
    }

    It 'writes managed as a remote_management boolean and warns on invalid input' {
        Update-JamfComputer -Session $script:session -SerialNumber 'X' -Managed 'true' -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<remote_management><managed>true</managed></remote_management>*'
        }
        Update-JamfComputer -Session $script:session -SerialNumber 'X' -Managed 'banana' -Confirm:$false `
            -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
        $warnings | Should -Not -BeNullOrEmpty
    }

    It 'includes extension attributes with CLEAR! wiping the value' {
        Update-JamfComputer -Session $script:session -SerialNumber 'X' `
            -ExtensionAttribute @{ 2 = 'Building A'; 7 = 'CLEAR!' } -Confirm:$false | Out-Null
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<extension_attribute><id>2</id><value>Building A</value></extension_attribute>*' -and
            ($Body.OuterXml -like '*<id>7</id><value></value>*' -or $Body.OuterXml -like '*<id>7</id><value />*')
        }
    }
}

Describe 'Set-JamfStaticGroupMember' {
    BeforeEach {
        $script:session = New-TestJamfSession
        Mock -ModuleName JamfProKit Invoke-JamfRequest { $null }
    }

    It 'PUTs additions and deletions as differential XML' {
        Set-JamfStaticGroupMember -Session $script:session -GroupId 15 `
            -Add 'C02AAA', '42' -Remove 'C02BBB' -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and
            $Path -eq 'JSSResource/computergroups/id/15' -and
            $Body.OuterXml -like '*<computer_additions><computer><serial_number>C02AAA</serial_number></computer><computer><id>42</id></computer></computer_additions>*' -and
            $Body.OuterXml -like '*<computer_deletions><computer><serial_number>C02BBB</serial_number></computer></computer_deletions>*' -and
            $Body.OuterXml -like '*<is_smart>false</is_smart>*'
        }
    }

    It 'replaces the full membership with -Replace' {
        Set-JamfStaticGroupMember -Session $script:session -GroupId 8 -Type User `
            -Replace 'alice', 'bob' -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/usergroups/id/8' -and
            $Body.OuterXml -like '*<users><user><username>alice</username></user><user><username>bob</username></user></users>*'
        }
    }

    It 'honors -NumericIdentifiersAreNames (MUT usernames-are-ints)' {
        Set-JamfStaticGroupMember -Session $script:session -GroupId 8 -Type User `
            -Add '12345' -NumericIdentifiersAreNames -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Body.OuterXml -like '*<username>12345</username>*'
        }
    }

    It 'uses mobile device group endpoints for -Type MobileDevice' {
        Set-JamfStaticGroupMember -Session $script:session -GroupId 3 -Type MobileDevice `
            -Add 'F9FXH1' -Confirm:$false
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'JSSResource/mobiledevicegroups/id/3' -and
            $Body.OuterXml -like '*<mobile_device_additions><mobile_device><serial_number>F9FXH1</serial_number></mobile_device></mobile_device_additions>*'
        }
    }

    It 'requires -Add or -Remove in delta mode' {
        { Set-JamfStaticGroupMember -Session $script:session -GroupId 15 -Confirm:$false } |
            Should -Throw '*-Add and/or -Remove*'
    }

    It 'makes no API call under -WhatIf' {
        Set-JamfStaticGroupMember -Session $script:session -GroupId 15 -Add 'C02AAA' -WhatIf
        Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
    }
}
