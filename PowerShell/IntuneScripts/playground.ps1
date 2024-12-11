$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories"
Invoke-MgGraphRequest -method GET -Uri $URI | Select -expand Value

#Test Category
function Update-DeviceCategory {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ObjID,
        [string]$CategoryID
    )

    $DevURI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/" + $CategoryID
    $Id = "@odata.id"
    $JSON = @{ $id = "$DevURI" } | ConvertTo-Json -compress
    $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ObjID')/deviceCategory/`$ref"
    Invoke-MgGraphRequest -Method PUT -Uri $URI -Body $JSON -ContentType "application/json"

}



$bridgedAdapterDevices = $csv | Where DetectionScriptStatus -eq "With Issues"


foreach ($device in $bridgedAdapterDevices) {
    Update-DeviceCategory -ObjID $device.DeviceId -CategoryID a62acae9-8f4f-4d67-a95f-6d4311e73913
}