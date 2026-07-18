function Set-MosyleDeviceGroupMember {
    <#
    .SYNOPSIS
        Adds and/or removes devices in a Mosyle dynamic device group
        (POST /devicegroups, operation "update_devices").
    .DESCRIPTION
        Unlike most Mosyle write endpoints, /devicegroups takes its keys at the top
        level of the body (not inside an elements array). Devices are identified by UDID.
    .EXAMPLE
        Set-MosyleDeviceGroupMember -GroupId 210 -Add $udid1, $udid2
    .EXAMPLE
        Set-MosyleDeviceGroupMember -GroupId 210 -Remove $udid3
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('idgroup')]
        [int] $GroupId,

        [string[]] $Add,

        [string[]] $Remove,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    $resolved = Assert-MosyleSession -Session $Session

    if (-not $Add -and -not $Remove) {
        throw 'Supply -Add and/or -Remove (device UDIDs).'
    }

    $body = @{
        operation = 'update_devices'
        idgroup   = $GroupId
    }
    if ($Add) { $body['add'] = @($Add) }
    if ($Remove) { $body['remove'] = @($Remove) }

    $counts = @(
        if ($Add) { "add $(@($Add).Count)" }
        if ($Remove) { "remove $(@($Remove).Count)" }
    ) -join ', '

    if ($PSCmdlet.ShouldProcess("Device group $GroupId", "Update membership ($counts)")) {
        $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'devicegroups' -Body $body
        Select-MosyleResult -Response $response -Property 'response'
    }
}
