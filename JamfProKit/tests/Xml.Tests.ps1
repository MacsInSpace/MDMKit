BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
}

Describe 'ConvertTo-JamfXml' {
    It 'converts nested sections into elements' {
        $xml = InModuleScope JamfProKit {
            ConvertTo-JamfXml -RootElement 'computer' -InputObject ([ordered]@{
                general  = [ordered]@{ asset_tag = 'A-100'; name = 'Mac 1' }
                location = [ordered]@{ username = 'jappleseed' }
            })
        }
        $xml.computer.general.asset_tag | Should -Be 'A-100'
        $xml.computer.general.name | Should -Be 'Mac 1'
        $xml.computer.location.username | Should -Be 'jappleseed'
    }

    It 'renders extension attribute arrays with singular child elements' {
        $xml = InModuleScope JamfProKit {
            ConvertTo-JamfXml -RootElement 'computer' -InputObject ([ordered]@{
                extension_attributes = @(
                    [ordered]@{ id = 2; value = 'Building A' }
                    [ordered]@{ id = 7; value = '' }
                )
            })
        }
        $nodes = $xml.SelectNodes('/computer/extension_attributes/extension_attribute')
        $nodes.Count | Should -Be 2
        $nodes[0].id | Should -Be '2'
        $nodes[0].value | Should -Be 'Building A'
    }

    It 'renders group addition/deletion deltas with correct member elements' {
        $xml = InModuleScope JamfProKit {
            ConvertTo-JamfXml -RootElement 'computer_group' -InputObject ([ordered]@{
                is_smart           = $false
                computer_additions = @(
                    [ordered]@{ serial_number = 'C02AAA' }
                    [ordered]@{ id = 42 }
                )
                computer_deletions = @(
                    [ordered]@{ serial_number = 'C02BBB' }
                )
            })
        }
        $xml.computer_group.is_smart | Should -Be 'false'
        $additions = $xml.SelectNodes('/computer_group/computer_additions/computer')
        $additions.Count | Should -Be 2
        $additions[0].serial_number | Should -Be 'C02AAA'
        $additions[1].id | Should -Be '42'
        $xml.SelectNodes('/computer_group/computer_deletions/computer').Count | Should -Be 1
    }

    It 'lowercases booleans' {
        $xml = InModuleScope JamfProKit {
            ConvertTo-JamfXml -RootElement 'thing' -InputObject ([ordered]@{ enabled = $true; hidden = $false })
        }
        $xml.thing.enabled | Should -Be 'true'
        $xml.thing.hidden | Should -Be 'false'
    }

    It 'produces an empty element for empty strings (field clearing)' {
        $xml = InModuleScope JamfProKit {
            ConvertTo-JamfXml -RootElement 'computer' -InputObject ([ordered]@{
                general = [ordered]@{ asset_tag = '' }
            })
        }
        $node = $xml.SelectSingleNode('/computer/general/asset_tag')
        $node | Should -Not -BeNullOrEmpty
        $node.InnerText | Should -Be ''
    }
}
