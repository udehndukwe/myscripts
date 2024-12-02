$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories"
Invoke-MgGraphRequest -method GET -Uri $URI 

#Test Category
$CategoryID = "16539421-c981-48a7-9682-50162be4a8ba"
$DevURI = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/" + $CategoryID
$ObjID = "4e3d1689-259f-4afa-b6de-8e29d6d35415"
$Id = "@odata.id"
$JSON = @{ $id = "$DevURI" } | ConvertTo-Json -compress
$URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ObjID')/deviceCategory/`$ref"
Invoke-MgGraphRequest -Method PUT -Uri $URI -Body $JSON -ContentType "application/json"



