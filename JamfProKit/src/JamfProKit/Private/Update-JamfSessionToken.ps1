function Update-JamfSessionToken {
    <#
    .SYNOPSIS
        Ensures a session holds a token that is valid for at least the buffer window.
    .DESCRIPTION
        Called by Invoke-JamfRequest before every request. If the token is missing or
        inside the expiry buffer:
          - OAuth sessions re-mint (client-credentials tokens cannot be extended).
          - User sessions try POST /api/v1/auth/keep-alive first, then fall back to
            re-minting from the cached credential.
        Use -Force to renew regardless of remaining lifetime (used after a 401).
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'Tokens arrive in plaintext from the API response; converting them to SecureString for in-memory storage is the point.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Private helper; token renewal is not a user-facing state change.')]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('JamfProKit.Session')]
        [object] $Session,

        [int] $BufferSeconds = 60,

        [switch] $Force
    )

    $needsRenewal = $Force -or
        ($null -eq $Session.Token) -or
        ($Session.TokenExpiry -le [DateTimeOffset]::UtcNow.AddSeconds($BufferSeconds))

    if (-not $needsRenewal) { return }

    if ($Session.AuthType -eq 'OAuth') {
        New-JamfToken -Session $Session
        return
    }

    # User-account session: try to extend the current token before re-minting.
    if ($null -ne $Session.Token -and $Session.TokenExpiry -gt [DateTimeOffset]::UtcNow) {
        $tokenPlain = ConvertFrom-SecureString -SecureString $Session.Token -AsPlainText
        try {
            $result = Invoke-JamfHttp -Uri "$($Session.BaseUri)/api/v1/auth/keep-alive" -Method 'POST' `
                -Headers @{ Authorization = "Bearer $tokenPlain" } -WebSession $Session.WebSession
        }
        finally {
            $tokenPlain = $null
        }
        if ($result.StatusCode -eq 200) {
            $Session.Token = ConvertTo-SecureString -String $result.Content.token -AsPlainText -Force
            $Session.TokenExpiry = [DateTimeOffset]::Parse($result.Content.expires, [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
            return
        }
        Write-Verbose "keep-alive returned HTTP $($result.StatusCode); minting a new token."
    }

    New-JamfToken -Session $Session
}
