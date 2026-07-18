function Update-JamfComputer {
    <#
    .SYNOPSIS
        Updates computer inventory attributes — drop-in replacement for The MUT's
        computer template, as a pipeline cmdlet.
    .DESCRIPTION
        Updates general, location and purchasing attributes plus extension attributes
        on a computer record via the Classic API (the only API that can write these).

        MUT compatibility: every parameter carries an alias matching the MUT CSV
        template header, so a MUT computer template pipes straight in:

            Import-Csv ./ComputerTemplate.csv | Update-JamfComputer -WhatIf

        MUT semantics are honored: an empty value means "leave unchanged" and the
        literal value CLEAR! wipes the field (for Site, CLEAR! unassigns via id -1).
        Failures are per-row non-terminating errors, so one bad row never stops a
        bulk run; each row emits a result object you can export for retry.
    .PARAMETER ExtensionAttribute
        Hashtable of extension attribute IDs to values, e.g. @{ 2 = 'Building A'; 7 = 'CLEAR!' }.
    .EXAMPLE
        Update-JamfComputer -SerialNumber C02ABC123XYZ -AssetTag 'A-1001' -Building 'HQ'
    .EXAMPLE
        Import-Csv ./ComputerTemplate.csv | Update-JamfComputer
    .EXAMPLE
        $results = Import-Csv ./bulk.csv | Update-JamfComputer -ErrorAction SilentlyContinue -ErrorVariable rowErrors
        $results | Where-Object Status -ne 'Updated' | Export-Csv ./retry.csv
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Serial')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Serial', ValueFromPipelineByPropertyName)]
        [Alias('Serial', 'Computer Serial')]
        [string] $SerialNumber,

        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipelineByPropertyName)]
        [int] $Id,

        # --- general ---
        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Display Name')]
        [string] $DisplayName,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Asset Tag')]
        [string] $AssetTag,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Barcode 1')]
        [string] $Barcode1,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Barcode 2')]
        [string] $Barcode2,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Site (ID or Name)')]
        [string] $Site,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Managed,

        # --- location ---
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Username,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Real Name')]
        [string] $RealName,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Email Address')]
        [string] $EmailAddress,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Position,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Phone Number')]
        [string] $PhoneNumber,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Department,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Building,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Room,

        # --- purchasing ---
        [Parameter(ValueFromPipelineByPropertyName)] [Alias('PO Number')]
        [string] $PONumber,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Vendor,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Purchase Price')]
        [string] $PurchasePrice,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('PO Date')]
        [string] $PODate,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Warranty Expires')]
        [string] $WarrantyExpires,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Is Leased')]
        [string] $IsLeased,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('Lease Expires')]
        [string] $LeaseExpires,

        [Parameter(ValueFromPipelineByPropertyName)] [Alias('AppleCare ID')]
        [string] $AppleCareId,

        [hashtable] $ExtensionAttribute,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session

        # parameter name -> Classic API section + element
        $fieldMap = @{
            DisplayName     = @('general', 'name')
            AssetTag        = @('general', 'asset_tag')
            Barcode1        = @('general', 'barcode_1')
            Barcode2        = @('general', 'barcode_2')
            Username        = @('location', 'username')
            RealName        = @('location', 'real_name')
            EmailAddress    = @('location', 'email_address')
            Position        = @('location', 'position')
            PhoneNumber     = @('location', 'phone_number')
            Department      = @('location', 'department')
            Building        = @('location', 'building')
            Room            = @('location', 'room')
            PONumber        = @('purchasing', 'po_number')
            Vendor          = @('purchasing', 'vendor')
            PurchasePrice   = @('purchasing', 'purchase_price')
            PODate          = @('purchasing', 'po_date')
            WarrantyExpires = @('purchasing', 'warranty_expires')
            IsLeased        = @('purchasing', 'is_leased')
            LeaseExpires    = @('purchasing', 'lease_expires')
            AppleCareId     = @('purchasing', 'applecare_id')
        }
    }

    process {
        $identifier = if ($PSCmdlet.ParameterSetName -eq 'Id') { "id/$Id" } else { "serialnumber/$([uri]::EscapeDataString($SerialNumber))" }
        $identityLabel = if ($PSCmdlet.ParameterSetName -eq 'Id') { "id $Id" } else { $SerialNumber }

        $sections = [ordered]@{}
        $changes = [System.Collections.Generic.List[string]]::new()

        foreach ($paramName in $fieldMap.Keys) {
            if (-not $PSBoundParameters.ContainsKey($paramName)) { continue }
            $value = [string]$PSBoundParameters[$paramName]
            if ($value -eq '') { continue }                    # MUT: blank = unchanged
            if ($value -ceq 'CLEAR!') { $value = '' }          # MUT: CLEAR! = wipe

            $sectionName, $elementName = $fieldMap[$paramName]
            if (-not $sections.Contains($sectionName)) { $sections[$sectionName] = [ordered]@{} }
            $sections[$sectionName][$elementName] = $value
            [void]$changes.Add($paramName)
        }

        # Site: integer -> id, CLEAR! -> id -1 (unassign), anything else -> name.
        if ($PSBoundParameters.ContainsKey('Site') -and $Site -ne '') {
            if (-not $sections.Contains('general')) { $sections['general'] = [ordered]@{} }
            $siteId = 0
            if ($Site -ceq 'CLEAR!') {
                $sections['general']['site'] = [ordered]@{ id = -1 }
            }
            elseif ([int]::TryParse($Site, [ref]$siteId)) {
                $sections['general']['site'] = [ordered]@{ id = $siteId }
            }
            else {
                $sections['general']['site'] = [ordered]@{ name = $Site }
            }
            [void]$changes.Add('Site')
        }

        # Managed: strict true/false, matching MUT's validation.
        if ($PSBoundParameters.ContainsKey('Managed') -and $Managed -ne '') {
            $managedBool = $false
            if ([bool]::TryParse($Managed, [ref]$managedBool)) {
                if (-not $sections.Contains('general')) { $sections['general'] = [ordered]@{} }
                $sections['general']['remote_management'] = [ordered]@{ managed = $managedBool }
                [void]$changes.Add('Managed')
            }
            else {
                Write-Warning "[$identityLabel] Managed value '$Managed' is not true/false; skipping that field."
            }
        }

        if ($null -ne $ExtensionAttribute -and $ExtensionAttribute.Count -gt 0) {
            $eaList = foreach ($key in $ExtensionAttribute.Keys) {
                $eaValue = [string]$ExtensionAttribute[$key]
                if ($eaValue -eq '') { continue }
                if ($eaValue -ceq 'CLEAR!') { $eaValue = '' }
                [ordered]@{ id = [int]$key; value = $eaValue }
            }
            if (@($eaList).Count -gt 0) {
                $sections['extension_attributes'] = @($eaList)
                [void]$changes.Add('ExtensionAttribute')
            }
        }

        if ($sections.Count -eq 0) {
            Write-Verbose "[$identityLabel] No changes supplied; skipping."
            return
        }

        $xml = ConvertTo-JamfXml -RootElement 'computer' -InputObject $sections

        if ($PSCmdlet.ShouldProcess($identityLabel, "Update computer ($($changes -join ', '))")) {
            try {
                Invoke-JamfRequest -Session $resolved -Method PUT -Path "JSSResource/computers/$identifier" `
                    -Body $xml -Accept 'application/xml' | Out-Null
                [pscustomobject]@{
                    PSTypeName = 'JamfProKit.BulkResult'
                    Identifier = $identityLabel
                    Status     = 'Updated'
                    Fields     = $changes -join ', '
                    Error      = $null
                }
            }
            catch {
                [pscustomobject]@{
                    PSTypeName = 'JamfProKit.BulkResult'
                    Identifier = $identityLabel
                    Status     = 'Failed'
                    Fields     = $changes -join ', '
                    Error      = $_.Exception.Message
                }
                Write-Error -Message "[$identityLabel] $($_.Exception.Message)" -TargetObject $identityLabel
            }
        }
    }
}
