function Connect-JamfPro {
    <#
    .SYNOPSIS
        Connects to a Jamf Pro server and creates the module's default session.
    .DESCRIPTION
        Supports both modern authentication flows:

          OAuth client credentials (recommended; API Roles and Clients):
            Connect-JamfPro -Url https://acme.jamfcloud.com -ClientId $id -ClientSecret $secret

          User account (basic auth is only ever sent to the token endpoint):
            Connect-JamfPro -Url https://acme.jamfcloud.com -Credential (Get-Credential)

        The secret can come straight from SecretManagement:
            Connect-JamfPro -Url $url -ClientId $id -ClientSecret (Get-Secret JamfClientSecret)

        The session tracks token expiry and renews automatically (keep-alive for user
        tokens, re-mint for OAuth) — you connect once and forget about tokens. A shared
        WebRequestSession preserves Jamf Cloud sticky-session cookies across calls.

        The session becomes the module default; pass -PassThru to also capture it for
        use with the -Session parameter on any cmdlet (e.g. for multi-server work).
    .PARAMETER Url
        Base URL of the Jamf Pro server, e.g. https://acme.jamfcloud.com
    .PARAMETER ClientId
        API client ID (OAuth client credentials flow).
    .PARAMETER ClientSecret
        API client secret as a SecureString (OAuth client credentials flow).
    .PARAMETER Credential
        Jamf Pro user account credential (bearer-token flow).
    .PARAMETER DoNotCacheCredential
        For the user flow: do not keep the credential on the session. The token will
        still be kept alive, but once it fully expires you must reconnect.
    .PARAMETER PassThru
        Return the session object.
    .EXAMPLE
        Connect-JamfPro -Url https://acme.jamfcloud.com -ClientId $id -ClientSecret (Get-Secret JamfPro)
    .EXAMPLE
        $prod = Connect-JamfPro -Url https://prod.jamfcloud.com -Credential $cred -PassThru
        Get-JamfComputer -Session $prod
    #>
    [CmdletBinding(DefaultParameterSetName = 'OAuth')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^https?://')]
        [string] $Url,

        [Parameter(Mandatory, ParameterSetName = 'OAuth')]
        [string] $ClientId,

        [Parameter(Mandatory, ParameterSetName = 'OAuth')]
        [securestring] $ClientSecret,

        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'Credential')]
        [switch] $DoNotCacheCredential,

        [switch] $PassThru
    )

    $session = [pscustomobject]@{
        PSTypeName     = 'JamfProKit.Session'
        BaseUri        = $Url.TrimEnd('/')
        AuthType       = $PSCmdlet.ParameterSetName  # 'OAuth' or 'Credential'
        ClientId       = if ($PSCmdlet.ParameterSetName -eq 'OAuth') { $ClientId } else { $null }
        ClientSecret   = if ($PSCmdlet.ParameterSetName -eq 'OAuth') { $ClientSecret } else { $null }
        Credential     = if ($PSCmdlet.ParameterSetName -eq 'Credential' -and -not $DoNotCacheCredential) { $Credential } else { $null }
        Token          = $null
        TokenExpiry    = [DateTimeOffset]::MinValue
        WebSession     = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        JamfProVersion = $null
    }

    if ($PSCmdlet.ParameterSetName -eq 'Credential' -and $DoNotCacheCredential) {
        # Mint the first token with the transient credential before discarding it.
        $mintSession = $session.PSObject.Copy()
        $mintSession.Credential = $Credential
        New-JamfToken -Session $mintSession
        $session.Token = $mintSession.Token
        $session.TokenExpiry = $mintSession.TokenExpiry
    }
    else {
        New-JamfToken -Session $session
    }

    try {
        $versionInfo = Invoke-JamfRequest -Session $session -Method GET -Path 'api/v1/jamf-pro-version'
        $session.JamfProVersion = $versionInfo.version
    }
    catch {
        Write-Verbose "Connected, but could not read the Jamf Pro version: $_"
    }

    $script:DefaultJamfSession = $session
    Write-Verbose "Connected to $($session.BaseUri) (Jamf Pro $($session.JamfProVersion)) using $($session.AuthType) authentication."

    if ($PassThru) { return $session }
}
