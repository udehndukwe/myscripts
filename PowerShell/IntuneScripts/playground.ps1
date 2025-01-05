$URI = 'https://graph.microsoft.com/beta/deviceManagement/deviceCategories'
Invoke-MgGraphRequest -Method GET -Uri $URI 

#Test Category
function Update-DeviceCategory {
    $CategoryID = '16539421-c981-48a7-9682-50162be4a8ba'
    $DevURI = 'https://graph.microsoft.com/beta/deviceManagement/deviceCategories/' + $CategoryID
    $ObjID = '4e3d1689-259f-4afa-b6de-8e29d6d35415'
    $Id = '@odata.id'
    $JSON = @{ $id = "$DevURI" } | ConvertTo-Json -Compress
    $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ObjID')/deviceCategory/`$ref"
    Invoke-MgGraphRequest -Method PUT -Uri $URI -Body $JSON -ContentType 'application/json'

}


$URI = 'https://graph.microsoft.com/v1.0/devices/b57e6618-186e-465b-a201-bd6325a4d10b'
Invoke-MgGraphRequest GET -Uri $URI


$intuneDevices = Get-MgDeviceManagementManagedDevice -all

$SourceScript = 'WRite-Host "Hostname: $env:COMPUTERNAME, Username $env:USERNAME"'

New-AzConnectedMachineRunCommand -ResourceGroupName ArcResources -SourceScript $SourceScript -RunCommandName 'runGetInfo50' -MachineName WIN-0D7JKROJ730 -Location 'eastus'


$URI = 'https://prod-65.westus.logic.azure.com:443/workflows/5fd30d21214842ab9becbc500bbe5bb9/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=frjXrTjai2j6Q84cYOhDdJYI9Qko9tfR23Lnjgg2CXw'

$URI = 'https://prod-25.westus.logic.azure.com:443/workflows/86e5bd316cf84a289242b20a5836e175/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=caRx4nAlSwRpCspGDPprYBxmDO_HH48uRK5N_BEFZpQ'


$json = Get-Content .\sample.json

Invoke-RestMethod -Method POST -Uri $URI -ContentType application/json -Body $json


$URI = 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=owner eq ""'

$apps = Invoke-MgGraphRequest -Method GET -Uri $URI | Select-Object -ExpandProperty value | Select-Object displayName, id, owner
$apps

foreach ($app in $apps) {
    if (-not $app.owner) {
        Write-Output "App: $($app.displayName) has no owner"
    }
}


### URI to retrieve non-global apps
$appEndpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=(microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true)"