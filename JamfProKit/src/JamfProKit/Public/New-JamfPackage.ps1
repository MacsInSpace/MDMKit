function New-JamfPackage {
    <#
    .SYNOPSIS
        Creates a package record (metadata only) in Jamf Pro.
    .DESCRIPTION
        Creates the package record via the Jamf Pro API (v1/packages, Jamf Pro 11.5+).
        This is metadata only — use Publish-JamfPackage to upload the actual file
        (it creates the record for you if one doesn't exist).
    .PARAMETER CategoryId
        Category ID as a string; '-1' means no category (the Jamf default).
    .EXAMPLE
        New-JamfPackage -PackageName 'Firefox 128' -FileName 'Firefox-128.0.pkg'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $PackageName,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string] $FileName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $CategoryId = '-1',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Info = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Notes = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, 20)]
        [int] $Priority = 10,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $OsRequirements = '',

        [switch] $RebootRequired,

        [switch] $FillUserTemplate,

        [switch] $OsInstall,

        [switch] $SuppressUpdates,

        [switch] $SuppressFromDock,

        [switch] $SuppressEula,

        [switch] $SuppressRegistration,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        # v1/packages requires the boolean fields to be present explicitly.
        $body = @{
            packageName          = $PackageName
            fileName             = $FileName
            categoryId           = $CategoryId
            info                 = $Info
            notes                = $Notes
            priority             = $Priority
            osRequirements       = $OsRequirements
            rebootRequired       = [bool]$RebootRequired
            fillUserTemplate     = [bool]$FillUserTemplate
            fillExistingUsers    = $false
            osInstall            = [bool]$OsInstall
            suppressUpdates      = [bool]$SuppressUpdates
            suppressFromDock     = [bool]$SuppressFromDock
            suppressEula         = [bool]$SuppressEula
            suppressRegistration = [bool]$SuppressRegistration
        }

        if ($PSCmdlet.ShouldProcess($PackageName, 'Create Jamf Pro package record')) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path 'api/v1/packages' -Body $body
            Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/packages/$($response.id)"
        }
    }
}
