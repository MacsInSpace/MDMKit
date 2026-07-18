function ConvertTo-JamfXml {
    <#
    .SYNOPSIS
        Converts nested hashtables/PSCustomObjects into a Classic API XML document.
    .DESCRIPTION
        The Classic API requires XML for writes. This converter maps:
          - hashtable / ordered dictionary / PSCustomObject  -> nested elements
          - arrays -> repeated child elements, named via a plural->singular map
            (e.g. extension_attributes -> extension_attribute)
          - scalars -> text nodes (booleans lowercased to match Jamf's format)
        Returns a System.Xml.XmlDocument.
    .EXAMPLE
        ConvertTo-JamfXml -RootElement computer -InputObject @{
            location = @{ username = 'jappleseed' }
            extension_attributes = @( @{ id = 2; value = 'Building A' } )
        }
    #>
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param(
        [Parameter(Mandatory)]
        [string] $RootElement,

        [Parameter(Mandatory)]
        [object] $InputObject
    )

    $singularMap = @{
        extension_attributes    = 'extension_attribute'
        computers               = 'computer'
        computer_additions      = 'computer'
        computer_deletions      = 'computer'
        mobile_devices          = 'mobile_device'
        mobile_device_additions = 'mobile_device'
        mobile_device_deletions = 'mobile_device'
        users                   = 'user'
        user_additions          = 'user'
        user_deletions          = 'user'
        criteria                = 'criterion'
        packages                = 'package'
        scripts                 = 'script'
        categories              = 'category'
    }

    $document = [System.Xml.XmlDocument]::new()
    $root = $document.CreateElement($RootElement)
    [void]$document.AppendChild($root)

    Add-JamfXmlChild -Document $document -Parent $root -Value $InputObject -SingularMap $singularMap
    return $document
}

function Add-JamfXmlChild {
    [CmdletBinding()]
    param(
        [System.Xml.XmlDocument] $Document,
        [System.Xml.XmlElement] $Parent,
        [object] $Value,
        [hashtable] $SingularMap
    )

    if ($null -eq $Value) { return }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $child = $Document.CreateElement([string]$key)
            [void]$Parent.AppendChild($child)
            Add-JamfXmlNodeValue -Document $Document -Element $child -Value $Value[$key] -SingularMap $SingularMap
        }
        return
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        foreach ($property in $Value.PSObject.Properties) {
            $child = $Document.CreateElement($property.Name)
            [void]$Parent.AppendChild($child)
            Add-JamfXmlNodeValue -Document $Document -Element $child -Value $property.Value -SingularMap $SingularMap
        }
        return
    }

    $Parent.InnerText = Format-JamfXmlScalar -Value $Value
}

function Add-JamfXmlNodeValue {
    [CmdletBinding()]
    param(
        [System.Xml.XmlDocument] $Document,
        [System.Xml.XmlElement] $Element,
        [object] $Value,
        [hashtable] $SingularMap
    )

    if ($null -eq $Value) { return }

    if ($Value -is [System.Collections.IDictionary] -or $Value -is [System.Management.Automation.PSCustomObject]) {
        Add-JamfXmlChild -Document $Document -Parent $Element -Value $Value -SingularMap $SingularMap
        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $itemName = if ($SingularMap.ContainsKey($Element.Name)) { $SingularMap[$Element.Name] } else { $Element.Name.TrimEnd('s') }
        foreach ($item in $Value) {
            $itemElement = $Document.CreateElement($itemName)
            [void]$Element.AppendChild($itemElement)
            Add-JamfXmlNodeValue -Document $Document -Element $itemElement -Value $item -SingularMap $SingularMap
        }
        return
    }

    $Element.InnerText = Format-JamfXmlScalar -Value $Value
}

function Format-JamfXmlScalar {
    [CmdletBinding()]
    [OutputType([string])]
    param([object] $Value)

    if ($Value -is [bool]) { return $Value.ToString().ToLowerInvariant() }
    return [string]$Value
}
