function Disconnect-JamfPro {
    <#
    .SYNOPSIS
        Invalidates the session's bearer token and clears the module default session.
    .EXAMPLE
        Disconnect-JamfPro
    #>
    [CmdletBinding()]
    param(
        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = $null
    try {
        $resolved = Assert-JamfSession -Session $Session
    }
    catch {
        Write-Verbose 'No active session to disconnect.'
        return
    }

    if ($null -ne $resolved.Token) {
        $tokenPlain = ConvertFrom-SecureString -SecureString $resolved.Token -AsPlainText
        try {
            $result = Invoke-JamfHttp -Uri "$($resolved.BaseUri)/api/v1/auth/invalidate-token" -Method 'POST' `
                -Headers @{ Authorization = "Bearer $tokenPlain" } -WebSession $resolved.WebSession
            Write-Verbose "invalidate-token returned HTTP $($result.StatusCode)."
        }
        catch {
            Write-Verbose "Failed to invalidate token (continuing): $_"
        }
        finally {
            $tokenPlain = $null
        }
    }

    $resolved.Token = $null
    $resolved.TokenExpiry = [DateTimeOffset]::MinValue
    $resolved.Credential = $null
    $resolved.ClientSecret = $null

    if ($script:DefaultJamfSession -eq $resolved) {
        $script:DefaultJamfSession = $null
    }
}
