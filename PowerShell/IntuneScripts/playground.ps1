$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories"
Invoke-MgGraphRequest -method GET -Uri $URI 

#Test Category
function Update-DeviceCategory {
    $CategoryID = "16539421-c981-48a7-9682-50162be4a8ba"
    $DevURI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/" + $CategoryID
    $ObjID = "4e3d1689-259f-4afa-b6de-8e29d6d35415"
    $Id = "@odata.id"
    $JSON = @{ $id = "$DevURI" } | ConvertTo-Json -compress
    $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ObjID')/deviceCategory/`$ref"
    Invoke-MgGraphRequest -Method PUT -Uri $URI -Body $JSON -ContentType "application/json"

}


$URI = "https://graph.microsoft.com/v1.0/devices/b57e6618-186e-465b-a201-bd6325a4d10b"
Invoke-MgGraphRequest GET -Uri $URI


$intuneDevices = Get-MgDeviceManagementManagedDevice -all
$EntraDevices = Get-MgDevice -all

foreach ($device in $EntraDevices) {
    $ID = $device.DeviceId
    $value = Get-MgDeviceManagementManagedDevice -filter "AzureAdDeviceID eq '$ID'"

    if (-not $value) {
        $Name = $device.DisplayName
        Write-Verbose "Remove device $Name. Press any button to confirm." -Verbose
        Read-Host
        Remove-MgDevice -DeviceId $ID 
    }
}