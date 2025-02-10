$body = @{
    reportName       = 'DeviceInstallStatusByApp'
    localizationType = 'LocalizedValuesAsAdditionalColumn'
    filter           = "(ApplicationId eq '$($appid)')"
    format           = 'csv'
    select           = @(
        'DeviceName',
        'DeviceId',
        'Platform',
        'UserPrincipalName',
        'AppInstallState',
        'AppInstallStateDetails',
        'AppVersion',
        'ErrorCode',
        'LastModifiedDateTime'
    )

}
#Create report request in Intune
$report = Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/reports/exportJobs' -Body $body

#Get Report Status
$URI = "/beta/deviceManagement/reports/exportJobs('$($report.id)')"
Invoke-MgGraphRequest -Method GET -Uri $URI
do {
    Start-Sleep -Seconds 5
    $reportStatus = Invoke-MgGraphRequest -Method GET -Uri $URI
} while ($reportStatus.status -ne 'completed')

#Download the report

Invoke-RestMethod -Method GET -Uri $reportStatus.url -OutFile DeviceInstallStatusReport.zip

#Extract the report

Expand-Archive -Path .\DeviceInstallStatusReport.zip -DestinationPath .\DeviceInstallStatusReport
$csv = Get-ChildItem DeviceInstallStatusReport -Filter '*.csv'
$report = $csv | Import-Csv