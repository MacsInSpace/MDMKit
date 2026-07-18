# Shared helpers dot-sourced by test files.

function New-TestJamfSession {
    <#
        Builds a fake connected session for unit tests. The token is valid for an hour
        so Update-JamfSessionToken is a no-op unless a test forces renewal.
    #>
    param(
        [string] $AuthType = 'OAuth',
        [datetimeoffset] $TokenExpiry = [DateTimeOffset]::UtcNow.AddHours(1)
    )

    [pscustomobject]@{
        PSTypeName     = 'JamfProKit.Session'
        BaseUri        = 'https://test.jamfcloud.com'
        AuthType       = $AuthType
        ClientId       = 'test-client'
        ClientSecret   = (ConvertTo-SecureString -String 'test-secret' -AsPlainText -Force)
        Credential     = [pscredential]::new('apiuser', (ConvertTo-SecureString -String 'pw' -AsPlainText -Force))
        Token          = (ConvertTo-SecureString -String 'current-token' -AsPlainText -Force)
        TokenExpiry    = $TokenExpiry
        WebSession     = $null
        JamfProVersion = '11.30.0'
    }
}

function New-TestHttpResult {
    param(
        [int] $StatusCode = 200,
        [object] $Content = $null,
        [hashtable] $Headers = $null
    )

    [pscustomobject]@{
        StatusCode = $StatusCode
        Headers    = $Headers
        Content    = $Content
    }
}
