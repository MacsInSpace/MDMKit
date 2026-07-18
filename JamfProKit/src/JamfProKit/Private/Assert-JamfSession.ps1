function Assert-JamfSession {
    <#
    .SYNOPSIS
        Resolves the session a cmdlet should use, or throws a friendly error.
    .DESCRIPTION
        Returns the explicitly supplied session if given, otherwise the module default
        set by the most recent Connect-JamfPro. Throws if neither exists.
    #>
    [CmdletBinding()]
    param(
        [object] $Session
    )

    if ($null -ne $Session) {
        if ($Session.PSObject.TypeNames -notcontains 'JamfProKit.Session') {
            throw 'The supplied -Session object is not a JamfProKit session. Use Connect-JamfPro to create one.'
        }
        return $Session
    }
    if ($null -ne $script:DefaultJamfSession) {
        return $script:DefaultJamfSession
    }
    throw 'Not connected to a Jamf Pro server. Run Connect-JamfPro first.'
}
