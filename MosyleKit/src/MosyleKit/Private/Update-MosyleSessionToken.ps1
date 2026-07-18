function Update-MosyleSessionToken {
    <#
    .SYNOPSIS
        Ensures the session holds a bearer JWT valid for at least the buffer window.
    .DESCRIPTION
        Mosyle JWTs expire every 24 hours. This re-runs POST /login (accessToken +
        admin email/password) when the token is missing or within the expiry buffer.
        The bearer token is returned in the login RESPONSE header, not the body.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Private helper; renewing a token is not a user-facing state change.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'The bearer token arrives in plaintext from the login response header; wrapping it in a SecureString for in-memory storage is the point.')]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('MosyleKit.Session')]
        [object] $Session,

        [int] $BufferSeconds = 300,

        [switch] $Force
    )

    $needsRenewal = $Force -or
        ($null -eq $Session.Token) -or
        ($Session.TokenExpiry -le [DateTimeOffset]::UtcNow.AddSeconds($BufferSeconds))
    if (-not $needsRenewal) { return }

    if ($null -eq $Session.Credential) {
        throw "The Mosyle session has no cached admin credential to renew its token. Run Connect-Mosyle again."
    }

    $accessToken = ConvertFrom-SecureString -SecureString $Session.AccessToken -AsPlainText
    $password = $Session.Credential.GetNetworkCredential().Password
    try {
        $body = ConvertTo-Json -Compress -InputObject @{
            accessToken = $accessToken
            email       = $Session.Credential.UserName
            password    = $password
        }
        $result = Invoke-MosyleHttp -Uri "$($Session.BaseUri)/login" -Body $body
    }
    finally {
        $accessToken = $null
        $password = $null
    }

    if ($result.StatusCode -ne 200) {
        throw "Mosyle login failed (HTTP $($result.StatusCode)). Check the access token, admin email and password, and that the API profile is enabled."
    }

    $authHeader = $null
    if ($null -ne $result.Headers -and $result.Headers.ContainsKey('Authorization')) {
        $authHeader = @($result.Headers['Authorization'])[0]
    }
    if (-not $authHeader) {
        throw 'Mosyle login succeeded but returned no Authorization header with a bearer token.'
    }
    # The header value is "Bearer <jwt>"; store the raw header string to echo back verbatim.
    $Session.Token = ConvertTo-SecureString -String $authHeader -AsPlainText -Force
    $Session.TokenExpiry = [DateTimeOffset]::UtcNow.AddHours(24)
}
