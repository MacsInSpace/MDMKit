function New-JamfExtensionAttribute {
    <#
    .SYNOPSIS
        Creates a computer or mobile device extension attribute.
    .DESCRIPTION
        Computer EAs support TEXT, POPUP, SCRIPT and DIRECTORY_SERVICE_ATTRIBUTE_MAPPING
        input types; mobile device EAs support TEXT and POPUP (the server rejects the
        rest — this cmdlet passes your input through and lets Jamf validate).
    .EXAMPLE
        New-JamfExtensionAttribute -Name 'Battery Cycle Count' -InputType SCRIPT -DataType INTEGER `
            -ScriptContents (Get-Content ./cycles.sh -Raw)
    .EXAMPLE
        New-JamfExtensionAttribute -Type MobileDevice -Name 'Cart Number' -InputType POPUP `
            -PopupChoices '1','2','3'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [ValidateSet('Computer', 'MobileDevice')]
        [string] $Type = 'Computer',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Description = '',

        [ValidateSet('TEXT', 'POPUP', 'SCRIPT', 'DIRECTORY_SERVICE_ATTRIBUTE_MAPPING')]
        [string] $InputType = 'TEXT',

        [ValidateSet('STRING', 'INTEGER', 'DATE')]
        [string] $DataType = 'STRING',

        [ValidateSet('GENERAL', 'HARDWARE', 'OPERATING_SYSTEM', 'USER_AND_LOCATION', 'PURCHASING', 'EXTENSION_ATTRIBUTES')]
        [string] $InventoryDisplayType = 'EXTENSION_ATTRIBUTES',

        [string[]] $PopupChoices,

        [string] $ScriptContents,

        [switch] $Disabled,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $endpoint = if ($Type -eq 'Computer') { 'api/v1/computer-extension-attributes' } else { 'api/v1/mobile-device-extension-attributes' }
    }

    process {
        $body = @{
            name                 = $Name
            description          = $Description
            dataType             = $DataType
            inputType            = $InputType
            inventoryDisplayType = $InventoryDisplayType
            enabled              = -not $Disabled
        }
        if ($null -ne $PopupChoices -and $PopupChoices.Count -gt 0) { $body['popupMenuChoices'] = @($PopupChoices) }
        if ($ScriptContents) { $body['scriptContents'] = $ScriptContents }

        if ($PSCmdlet.ShouldProcess($Name, "Create $Type extension attribute")) {
            $response = Invoke-JamfRequest -Session $resolved -Method POST -Path $endpoint -Body $body
            Invoke-JamfRequest -Session $resolved -Method GET -Path "$endpoint/$($response.id)"
        }
    }
}
