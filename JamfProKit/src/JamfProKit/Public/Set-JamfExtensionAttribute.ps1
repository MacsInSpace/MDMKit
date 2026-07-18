function Set-JamfExtensionAttribute {
    <#
    .SYNOPSIS
        Updates a computer or mobile device extension attribute. Only the properties
        you supply change.
    .EXAMPLE
        Set-JamfExtensionAttribute -Id 4 -ScriptContents (Get-Content ./cycles-v2.sh -Raw)
    .EXAMPLE
        Set-JamfExtensionAttribute -Type MobileDevice -Id 2 -PopupChoices '1','2','3','4'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string] $Id,

        [ValidateSet('Computer', 'MobileDevice')]
        [string] $Type = 'Computer',

        [string] $Name,

        [string] $Description,

        [ValidateSet('TEXT', 'POPUP', 'SCRIPT', 'DIRECTORY_SERVICE_ATTRIBUTE_MAPPING')]
        [string] $InputType,

        [ValidateSet('STRING', 'INTEGER', 'DATE')]
        [string] $DataType,

        [ValidateSet('GENERAL', 'HARDWARE', 'OPERATING_SYSTEM', 'USER_AND_LOCATION', 'PURCHASING', 'EXTENSION_ATTRIBUTES')]
        [string] $InventoryDisplayType,

        [string[]] $PopupChoices,

        [string] $ScriptContents,

        [bool] $Enabled,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
        $endpoint = if ($Type -eq 'Computer') { 'api/v1/computer-extension-attributes' } else { 'api/v1/mobile-device-extension-attributes' }
        $apiNameMap = @{
            Name                 = 'name'
            Description          = 'description'
            InputType            = 'inputType'
            DataType             = 'dataType'
            InventoryDisplayType = 'inventoryDisplayType'
            PopupChoices         = 'popupMenuChoices'
            ScriptContents       = 'scriptContents'
            Enabled              = 'enabled'
        }
    }

    process {
        $current = Invoke-JamfRequest -Session $resolved -Method GET -Path "$endpoint/$Id"
        $body = @{}
        foreach ($property in $current.PSObject.Properties) {
            $body[$property.Name] = $property.Value
        }
        foreach ($paramName in $apiNameMap.Keys) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                $body[$apiNameMap[$paramName]] = $PSBoundParameters[$paramName]
            }
        }

        if ($PSCmdlet.ShouldProcess("$($body['name']) (id $Id)", "Update $Type extension attribute")) {
            Invoke-JamfRequest -Session $resolved -Method PUT -Path "$endpoint/$Id" -Body $body
        }
    }
}
