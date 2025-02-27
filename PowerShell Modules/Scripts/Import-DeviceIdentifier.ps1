function Import-DeviceIdentifier {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$SerialNumber
    )
    $URI = "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities/importDeviceIdentityList"
    
    $params = @{
        overwriteImportedDeviceIdentities = $false
        importedDeviceIdentities = @(
            @{
                importedDeviceIdentityType = "serialNumber"
                importedDeviceIdentifier = $SerialNumber
                description = $description
            }
        )
    }


    Invoke-MgGraphRequest -Method POST -Uri $URI -Body $params -ContentType application/json
}

