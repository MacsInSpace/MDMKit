function New-JamfScript {
    <#
    .SYNOPSIS
        Creates a script in Jamf Pro.
    .EXAMPLE
        New-JamfScript -Name 'Reset Dock' -ScriptContents (Get-Content ./reset-dock.sh -Raw) -CategoryId 5
    .EXAMPLE
        Get-ChildItem ./scripts/*.sh | ForEach-Object {
            New-JamfScript -Name $_.BaseName -ScriptContents (Get-Content $_ -Raw)
        }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $ScriptContents,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Info = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Notes = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('BEFORE', 'AFTER', 'AT_REBOOT')]
        [string] $Priority = 'AFTER',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $CategoryId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $OsRequirements = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Parameters,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $body = @{
            name            = $Name
            scriptContents  = $ScriptContents
            info            = $Info
            notes           = $Notes
            priority        = $Priority
            osRequirements  = $OsRequirements
        }
        if ($CategoryId) { $body['categoryId'] = $CategoryId }
        if ($null -ne $Parameters) {
            # Jamf script parameters occupy slots 4-11.
            for ($i = 0; $i -lt [math]::Min($Parameters.Count, 8); $i++) {
                $body["parameter$($i + 4)"] = $Parameters[$i]
            }
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Create Jamf Pro script')) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v1/scripts' -Body $body
            Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/scripts/$($response.id)"
        }
    }
}
