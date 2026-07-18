BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'JamfProKit' 'JamfProKit.psd1') -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')

    # Trimmed but structurally faithful Jamf Pro OpenAPI fixture.
    $script:fixtureSpec = @'
{
  "openapi": "3.0.1",
  "paths": {
    "/v1/buildings": {
      "get": {
        "responses": { "200": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/BuildingSearchResults" } } } } }
      },
      "post": {
        "requestBody": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Building" } } } }
      }
    },
    "/v1/buildings/{id}": {
      "get": {},
      "put": { "requestBody": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/Building" } } } } },
      "delete": {}
    },
    "/v1/mobile-devices": {
      "get": { "deprecated": true, "responses": { "200": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/MobileDeviceSearchResults" } } } } } }
    },
    "/v2/mobile-devices": {
      "get": { "responses": { "200": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/MobileDeviceSearchResults" } } } } } }
    },
    "/v2/mobile-devices/{id}": {
      "get": {},
      "patch": { "requestBody": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/MobileDeviceUpdate" } } } } }
    },
    "/v1/jamf-pro-version": {
      "get": { "responses": { "200": { "content": { "application/json": { "schema": { "$ref": "#/components/schemas/JamfProVersion" } } } } } }
    },
    "/v1/buildings/{id}/history": {
      "get": {}
    }
  },
  "components": {
    "schemas": {
      "Building": {
        "type": "object",
        "properties": {
          "id": { "type": "string", "readOnly": true },
          "name": { "type": "string" },
          "priority": { "type": "integer" },
          "secure": { "type": "boolean" },
          "region": { "type": "string", "enum": ["APAC", "EMEA"] },
          "tags": { "type": "array", "items": { "type": "string" } },
          "address": { "$ref": "#/components/schemas/Address" }
        }
      },
      "Address": { "type": "object", "properties": { "city": { "type": "string" } } },
      "BuildingSearchResults": {
        "type": "object",
        "properties": { "totalCount": { "type": "integer" }, "results": { "type": "array", "items": { "$ref": "#/components/schemas/Building" } } }
      },
      "MobileDeviceUpdate": { "type": "object", "properties": { "name": { "type": "string" }, "enforceName": { "type": "boolean" } } },
      "MobileDeviceSearchResults": {
        "type": "object",
        "properties": { "totalCount": { "type": "integer" }, "results": { "type": "array", "items": { "type": "object" } } }
      },
      "JamfProVersion": { "type": "object", "properties": { "version": { "type": "string" } } }
    }
  }
}
'@ | ConvertFrom-Json
}

Describe 'Spec-driven generic layer' {
    BeforeEach {
        $script:session = New-TestJamfSession
        # Isolate the disk cache per test and clear the in-memory cache.
        InModuleScope JamfProKit -Parameters @{ dir = (Join-Path $TestDrive ([guid]::NewGuid().ToString('n'))) } {
            $script:JamfProKitCacheDir = $dir
            $script:JamfApiIndexCache = @{}
        }
        $script:spec = $script:fixtureSpec
        Mock -ModuleName JamfProKit Invoke-JamfRequest {
            if ($Path -eq 'api/schema') { return $script:spec }
            [pscustomobject]@{ totalCount = 0; results = @() }
        }
    }

    Context 'index distillation' {
        It 'indexes resources with correct operations and skips sub-resource paths' {
            $resources = Get-JamfApiResource -Session $script:session
            $names = @($resources).Resource
            $names | Should -Contain 'buildings'
            $names | Should -Contain 'mobile-devices'
            $names | Should -Contain 'jamf-pro-version'
            $buildings = @($resources) | Where-Object Resource -eq 'buildings'
            $buildings.Operations | Should -BeLike '*create*'
            $buildings.Operations | Should -BeLike '*delete*'
            $buildings.Operations | Should -Not -BeLike '*history*'
        }

        It 'marks deprecated operations' {
            $mobile = Get-JamfApiResource -Session $script:session -Name 'mobile-devices'
            $mobile.Operations | Should -BeLike '*list `[v1`] (deprecated)*'
            $mobile.Versions | Should -Be @('v1', 'v2')
        }
    }

    Context 'Get-JamfObject' {
        It 'prefers the newest non-deprecated version for lists' {
            Get-JamfObject -Session $script:session -Resource mobile-devices | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/v2/mobile-devices' -and $null -ne $Query -and $Query.ContainsKey('page')
            }
        }

        It 'honors -ApiVersion pinning' {
            Get-JamfObject -Session $script:session -Resource mobile-devices -ApiVersion v1 `
                -WarningAction SilentlyContinue | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/v1/mobile-devices'
            }
        }

        It 'fetches by id with the placeholder replaced and escaped' {
            Get-JamfObject -Session $script:session -Resource buildings -Id 'a b' | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/v1/buildings/a%20b'
            }
        }

        It 'calls unpaged endpoints directly and warns when -Filter is supplied' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                if ($Path -eq 'api/schema') { return $script:spec }
                [pscustomobject]@{ version = '11.30.0' }
            }
            Get-JamfObject -Session $script:session -Resource jamf-pro-version -Filter 'x=="y"' `
                -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
            $warnings | Should -Not -BeNullOrEmpty
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/v1/jamf-pro-version' -and ($null -eq $Query -or -not $Query.ContainsKey('page'))
            }
        }

        It 'suggests near-matches for unknown resources' {
            { Get-JamfObject -Session $script:session -Resource building } |
                Should -Throw '*Did you mean: buildings*'
        }
    }

    Context 'write cmdlets' {
        It 'creates then refetches by the returned id' {
            Mock -ModuleName JamfProKit Invoke-JamfRequest {
                if ($Path -eq 'api/schema') { return $script:spec }
                if ($Method -eq 'POST') { return [pscustomobject]@{ id = '9'; href = '/v1/buildings/9' } }
                [pscustomobject]@{ id = '9'; name = 'HQ' }
            }
            $result = New-JamfObject -Session $script:session -Resource buildings -Body @{ name = 'HQ' } -Confirm:$false
            $result.name | Should -Be 'HQ'
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and $Path -eq 'api/v1/buildings'
            }
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and $Path -eq 'api/v1/buildings/9'
            }
        }

        It 'updates with the verb the endpoint documents (PATCH for v2 mobile-devices)' {
            Set-JamfObject -Session $script:session -Resource mobile-devices -Id 31 `
                -Body @{ name = 'Cart-01' } -Confirm:$false | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'PATCH' -and $Path -eq 'api/v2/mobile-devices/31'
            }
        }

        It 'deletes with ShouldProcess protection' {
            Remove-JamfObject -Session $script:session -Resource buildings -Id 3 -WhatIf
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly -ParameterFilter {
                $Method -eq 'DELETE'
            }
            Remove-JamfObject -Session $script:session -Resource buildings -Id 3 -Confirm:$false
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and $Path -eq 'api/v1/buildings/3'
            }
        }

        It 'refuses operations a resource does not document' {
            { Set-JamfObject -Session $script:session -Resource jamf-pro-version -Id 1 -Body @{} -Confirm:$false } |
                Should -Throw "*does not support 'update'*"
        }
    }

    Context 'New-JamfObjectTemplate' {
        It 'builds a schema-accurate skeleton: defaults, enums, nested refs, readOnly omitted' {
            $template = New-JamfObjectTemplate -Session $script:session -Resource buildings
            $template.ContainsKey('id') | Should -BeFalse
            $template['name'] | Should -Be ''
            $template['priority'] | Should -Be 0
            $template['secure'] | Should -BeFalse
            $template['region'] | Should -Be 'APAC'
            @($template['tags']).Count | Should -Be 1
            $template['address']['city'] | Should -Be ''
        }

        It 'templates the Update schema on request and supports -AsJson' {
            $json = New-JamfObjectTemplate -Session $script:session -Resource mobile-devices -Operation Update -AsJson
            $parsed = $json | ConvertFrom-Json
            $parsed.enforceName | Should -BeFalse
            $parsed.PSObject.Properties.Name | Should -Contain 'name'
        }

        It 'is a copy, not a reference into the cached index' {
            $first = New-JamfObjectTemplate -Session $script:session -Resource buildings
            $first['name'] = 'mutated'
            $second = New-JamfObjectTemplate -Session $script:session -Resource buildings
            $second['name'] | Should -Be ''
        }
    }

    Context 'caching' {
        It 'fetches /api/schema once per session (memory cache)' {
            Get-JamfObject -Session $script:session -Resource buildings | Out-Null
            Get-JamfObject -Session $script:session -Resource mobile-devices | Out-Null
            Get-JamfApiResource -Session $script:session | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/schema'
            }
        }

        It 'reloads from disk without refetching when the memory cache is cleared' {
            Get-JamfObject -Session $script:session -Resource buildings | Out-Null
            InModuleScope JamfProKit { $script:JamfApiIndexCache = @{} }
            Get-JamfObject -Session $script:session -Resource buildings | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'api/schema'
            }
        }

        It 'refetches with -Refresh' {
            Get-JamfApiResource -Session $script:session | Out-Null
            Get-JamfApiResource -Session $script:session -Refresh | Out-Null
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 2 -Exactly -ParameterFilter {
                $Path -eq 'api/schema'
            }
        }

        It 'returns nothing in cache-only mode with a cold cache (completer path)' {
            $result = InModuleScope JamfProKit -Parameters @{ s = $script:session } {
                Get-JamfApiIndex -Session $s -CacheOnly
            }
            $result | Should -BeNullOrEmpty
            Should -Invoke -ModuleName JamfProKit Invoke-JamfRequest -Times 0 -Exactly
        }
    }
}
