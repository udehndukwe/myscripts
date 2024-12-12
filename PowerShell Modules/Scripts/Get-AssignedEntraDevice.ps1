function Get-AssignedEntraDevice {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SerialNumber,
        [string]$DeviceName
    )

    if ($DeviceName) {
        $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=displayName eq '$DeviceName'"
        if ($device.value.Count -eq 0) {
            Write-Error "Device not found"
            return
        }
        $deviceId = $device.value[0].id
        $mgUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices/$deviceId/registeredOwners"
        if ($mgUser.value.Count -eq 0) {
            Write-Error "No Registered User"
            return
        }
        Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($mgUser.value[0].id)"
    }

    if ($SerialNumber) {
        $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$SerialNumber'"
        if ($device.value.Count -eq 0) {
            Write-Error "Device not found"
            return
        }
        $deviceId = $device.value[0].azureADDeviceId
        $mgDevice = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=DeviceID eq '$deviceId'"
        $ID = $mgDevice.value.id
        $mgUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices/$ID/registeredOwners"
        if ($mgUser.value.Count -eq 0) {
            Write-Error "No Registered User"
            return
        }
        Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($mgUser.value[0].id)"
    }
}