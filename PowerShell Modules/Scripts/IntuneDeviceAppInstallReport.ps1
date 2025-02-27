$body = @{
    reportName       = 'Devices'
    localizationType = 'LocalizedValuesAsAdditionalColumn'
}

Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/reports/exportJobs' -Body $body


## GET

Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/reports/exportJobs('Devices_62bdf5f9-b17f-419c-a4f5-c1c650bfcd47')"