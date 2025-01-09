<#
.SYNOPSIS
    Retrieves the assigned Entra device and its registered owner based on the provided serial number or device name.

.DESCRIPTION
    The Get-AssignedEntraDevice function queries the Microsoft Graph API to find a device by its serial number or device name.
    If a device is found, it retrieves the Azure AD device ID and then fetches the registered owner of the device.

.PARAMETER SerialNumber
    The serial number of the device to search for.

.PARAMETER DeviceName
    The name of the device to search for.

.EXAMPLE
    Get-AssignedEntraDevice -SerialNumber "1234567890"
    Retrieves the device and its registered owner with the specified serial number.

.EXAMPLE
    Get-AssignedEntraDevice -DeviceName "MyDevice"
    Retrieves the device and its registered owner with the specified device name.

.NOTES
    This function requires the Microsoft Graph PowerShell SDK to be installed and authenticated.
    Ensure you have the necessary permissions to access device and user information in Microsoft Graph.

    Author: Udeh Ndukwe
    Date: 12/18/2024
#>
function Get-AssignedEntraDevice {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SerialNumber,
        [string]$DeviceName
    )


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