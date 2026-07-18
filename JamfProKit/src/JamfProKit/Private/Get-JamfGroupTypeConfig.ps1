function Get-JamfGroupTypeConfig {
    <#
    .SYNOPSIS
        Returns the Classic API naming config for a group type.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Computer', 'MobileDevice', 'User')]
        [string] $Type
    )

    @{
        Computer     = @{
            Endpoint        = 'computergroups'
            Root            = 'computer_group'
            ListProperty    = 'computer_groups'
            List            = 'computers'
            IdentityElement = 'serial_number'
        }
        MobileDevice = @{
            Endpoint        = 'mobiledevicegroups'
            Root            = 'mobile_device_group'
            ListProperty    = 'mobile_device_groups'
            List            = 'mobile_devices'
            IdentityElement = 'serial_number'
        }
        User         = @{
            Endpoint        = 'usergroups'
            Root            = 'user_group'
            ListProperty    = 'user_groups'
            List            = 'users'
            IdentityElement = 'username'
        }
    }[$Type]
}
