function Connect-Mosyle {
    <#
    .SYNOPSIS
        Connects to the Mosyle Manager API and creates the module's default session.
    .DESCRIPTION
        Mosyle uses JWT auth: POST /login with the API access token plus an admin
        user's email and password returns a 24-hour bearer token. This cmdlet logs in,
        caches the credential, and renews the token automatically before it expires.

        The API access token comes from My School > API Integration (a paid feature).
        The email/password are those of an admin user who has API permissions.
    .PARAMETER AccessToken
        The API access token as a SecureString (e.g. from Get-Secret).
    .PARAMETER Credential
        The admin user's email (as the username) and password.
    .PARAMETER Url
        API base endpoint. Defaults to the standard https://managerapi.mosyle.com/v2.
    .EXAMPLE
        Connect-Mosyle -AccessToken (Get-Secret MosyleToken) -Credential (Get-Credential)
    .EXAMPLE
        $s = Connect-Mosyle -AccessToken $tok -Credential $cred -PassThru
        Get-MosyleUser -Session $s
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [securestring] $AccessToken,

        [Parameter(Mandatory)]
        [pscredential] $Credential,

        [ValidatePattern('^https?://')]
        [string] $Url = 'https://managerapi.mosyle.com/v2',

        [switch] $PassThru
    )

    $session = [pscustomobject]@{
        PSTypeName  = 'MosyleKit.Session'
        BaseUri     = $Url.TrimEnd('/')
        AccessToken = $AccessToken
        Credential  = $Credential
        Token       = $null
        TokenExpiry = [DateTimeOffset]::MinValue
    }

    # Log in now so connection problems surface immediately.
    Update-MosyleSessionToken -Session $session

    $script:DefaultMosyleSession = $session
    Write-Verbose "Connected to $($session.BaseUri) as $($Credential.UserName)."

    if ($PassThru) { return $session }
}
