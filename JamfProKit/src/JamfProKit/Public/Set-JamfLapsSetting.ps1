function Set-JamfLapsSetting {
    <#
    .SYNOPSIS
        Updates the instance-wide LAPS settings. Only the properties you supply change.
    .PARAMETER PasswordRotationTimeSeconds
        How long a viewed password stays valid before rotation (seconds).
    .PARAMETER AutoRotateExpirationTimeSeconds
        Maximum age of an unviewed password before automatic rotation (seconds).
    .EXAMPLE
        Set-JamfLapsSetting -AutoDeployEnabled $true -AutoRotateEnabled $true
    .EXAMPLE
        Set-JamfLapsSetting -PasswordRotationTimeSeconds 3600
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [bool] $AutoDeployEnabled,

        [int] $PasswordRotationTimeSeconds,

        [bool] $AutoRotateEnabled,

        [int] $AutoRotateExpirationTimeSeconds,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    $resolved = Assert-JamfSession -Session $Session
    $apiNameMap = @{
        AutoDeployEnabled               = 'autoDeployEnabled'
        PasswordRotationTimeSeconds     = 'passwordRotationTime'
        AutoRotateEnabled               = 'autoRotateEnabled'
        AutoRotateExpirationTimeSeconds = 'autoRotateExpirationTime'
    }

    $current = Invoke-JamfRequest -Session $resolved -Method GET -Path 'api/v2/local-admin-password/settings'
    $body = @{}
    foreach ($property in $current.PSObject.Properties) {
        $body[$property.Name] = $property.Value
    }

    $changes = [System.Collections.Generic.List[string]]::new()
    foreach ($paramName in $apiNameMap.Keys) {
        if ($PSBoundParameters.ContainsKey($paramName)) {
            $body[$apiNameMap[$paramName]] = $PSBoundParameters[$paramName]
            [void]$changes.Add($apiNameMap[$paramName])
        }
    }

    if ($changes.Count -eq 0) {
        Write-Verbose 'No LAPS settings supplied; nothing to change.'
        return
    }

    if ($PSCmdlet.ShouldProcess('Jamf Pro LAPS settings', "Update ($($changes -join ', '))")) {
        Invoke-JamfRequest -Session $resolved -Method PUT -Path 'api/v2/local-admin-password/settings' -Body $body
    }
}
