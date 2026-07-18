function Set-MosyleDeviceOwner {
    <#
    .SYNOPSIS
        Assigns a device to a user in Mosyle (POST /users, operation "assign_device").
    .DESCRIPTION
        Links a device (by serial number) to a user (by user ID). Piped input is
        batched into a single request.
    .EXAMPLE
        Set-MosyleDeviceOwner -SerialNumber F9FXH12ABC -User student.1
    .EXAMPLE
        Import-Csv assignments.csv | Set-MosyleDeviceOwner -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('serial_number')]
        [string] $SerialNumber,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('id', 'UserId')]
        [string] $User,

        [PSTypeName('MosyleKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-MosyleSession -Session $Session
        $elements = [System.Collections.Generic.List[object]]::new()
    }

    process {
        [void]$elements.Add([ordered]@{
                operation     = 'assign_device'
                id            = $User
                serial_number = $SerialNumber
            })
    }

    end {
        if ($elements.Count -eq 0) { return }
        if ($PSCmdlet.ShouldProcess("$($elements.Count) device/user assignment(s)", 'Assign device to user')) {
            $response = Invoke-MosyleRequest -Session $resolved -Endpoint 'users' -Body @{ elements = @($elements) }
            Select-MosyleResult -Response $response -Property 'elements'
        }
    }
}
