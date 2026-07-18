function Get-MosyleDeviceGroupDevice {
    <#
    .SYNOPSIS
        Lists the device UDIDs in a Mosyle device group (POST /listdevicesbygroup).
    .DESCRIPTION
        Returns the group name and its member UDIDs. Optionally filter security-group
        membership by compliance status.
    .EXAMPLE
        Get-MosyleDeviceGroupDevice -GroupId 210
    .EXAMPLE
        Get-MosyleDeviceGroupDevice -GroupId 210 -SecurityGroup -ComplianceStatus noncompliant
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('iddevicegroup', 'id')]
        [int] $GroupId,

        [switch] $SecurityGroup,

        [ValidateSet('compliant', 'noncompliant')]
        [string] $ComplianceStatus,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
    }

    process {
        $requestOptions = @{ iddevicegroup = $GroupId }
        if ($SecurityGroup) { $requestOptions['is_security_group'] = 1 }
        if ($ComplianceStatus) { $requestOptions['security_compliance_status'] = $ComplianceStatus }

        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'listdevicesbygroup' -Body @{ options = $requestOptions }
        Select-MosyleResult -Response $response -Property 'udids'
    }
}
