function Clear-IntuneDevice {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$DeviceName,
        [string[]]$SerialNumber
    )

    begin {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }

        if ($DeviceName) {
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$DeviceName'"
        }
        elseif ($SerialNumber) {
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$SerialNumber'"
        }
        $params = @{
            keepEnrollmentData = $false
            keepUserData       = $false
        }
    }

    process {
        
        foreach ($device in $managedDevice) {
            $Name = $device.DeviceNAme
            Write-Verbose "Sending Wipe command..." -Verbose
            Clear-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id -BodyParameter $params -ErrorAction Stop -Confirm:$true
            Write-Verbose "Wipe initiated for $Name." -Verbose
        }
    }
}

