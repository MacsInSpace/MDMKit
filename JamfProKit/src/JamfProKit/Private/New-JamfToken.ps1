function New-JamfToken {
    <#
    .SYNOPSIS
        Mints a fresh bearer token for a session and stores it on the session object.
    .DESCRIPTION
        Supports both auth flows:
          - OAuth client credentials (API Roles and Clients): POST /api/oauth/token
          - User account (basic to token endpoint):           POST /api/v1/auth/token
        The token is stored on the session as a SecureString together with its expiry
        as a DateTimeOffset (UTC).
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'Tokens arrive in plaintext from the API response; converting them to SecureString for in-memory storage is the point.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Private helper; minting a token is not a user-facing state change.')]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    if ($Session.AuthType -eq 'OAuth') {
        $secretPlain = ConvertFrom-SecureString -SecureString $Session.ClientSecret -AsPlainText
        try {
            $result = Invoke-JamfHttp -Uri "$($Session.BaseUri)/api/oauth/token" -Method 'POST' `
                -Body @{
                    grant_type    = 'client_credentials'
                    client_id     = $Session.ClientId
                    client_secret = $secretPlain
                } `
                -ContentType 'application/x-www-form-urlencoded' `
                -WebSession $Session.WebSession
        }
        finally {
            $secretPlain = $null
        }

        if ($result.StatusCode -ne 200) {
            throw "Failed to obtain an OAuth token from $($Session.BaseUri) (HTTP $($result.StatusCode)). Check the client ID, client secret and that the API client is enabled."
        }
        $Session.Token = ConvertTo-SecureString -String $result.Content.access_token -AsPlainText -Force
        # Renew ahead of the advertised lifetime; OAuth tokens are short-lived (default 20 min).
        $Session.TokenExpiry = [DateTimeOffset]::UtcNow.AddSeconds([double]$result.Content.expires_in)
    }
    else {
        if ($null -eq $Session.Credential) {
            throw "The session for $($Session.BaseUri) has no cached credential and its token cannot be renewed. Run Connect-JamfPro again."
        }
        $result = Invoke-JamfHttp -Uri "$($Session.BaseUri)/api/v1/auth/token" -Method 'POST' `
            -Credential $Session.Credential -WebSession $Session.WebSession

        if ($result.StatusCode -ne 200) {
            throw "Failed to obtain a bearer token from $($Session.BaseUri) (HTTP $($result.StatusCode)). Check the username and password."
        }
        $Session.Token = ConvertTo-SecureString -String $result.Content.token -AsPlainText -Force
        $Session.TokenExpiry = [DateTimeOffset]::Parse($result.Content.expires, [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
    }
}
