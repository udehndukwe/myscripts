function Get-IntuneAppStatusReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AppID,
        [string]$AppDisplayName,
        [string]$Platform
    )
    $body = @{
        reportName       = 'AppInstallStatusAggregate'
        localizationType = 'LocalizedValuesAsAdditionalColumn'
        format           = 'csv'
        select           = @(
            'ApplicationId',
            'DisplayName',
            'Publisher',
            'Platform',
            'AppVersion',
            'InstalledDeviceCount',
            'FailedDeviceCount',
            'PendingInstallDeviceCount',
            'NotApplicableDeviceCount',
            'NotInstalledDeviceCount',
            'FailedDevicePercentage'
        )
    }
    # Create report request in Intune
    $request = Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/reports/exportJobs' -Body $body

    # Get Report Status
    $URI = "/beta/deviceManagement/reports/exportJobs('$($request.id)')"
    Invoke-MgGraphRequest -Method GET -Uri $URI
    do {
        Start-Sleep -Seconds 3
        $reportStatus = Invoke-MgGraphRequest -Method GET -Uri $URI
    } while ($reportStatus.status -ne 'completed')

    # Download the report
    $ReportName = $reportStatus.id
    Invoke-RestMethod -Method GET -Uri $reportStatus.url -OutFile "$ReportName.zip"

    # Extract the report as CSV and import CSV as a variable.
    Expand-Archive -Path "$ReportName.zip" -DestinationPath $ReportName
    $csv = Get-ChildItem $ReportName -Filter '*.csv'
    $report = $csv | Import-Csv

    # Parameters to return specific result. Returns entire report if no parameters are provided.
    if ($appID) {
        $report | Where-Object { $_.ApplicationId -eq $appID }
    }
    elseif ($AppDisplayName) {
        $report | Where-Object { $_.DisplayName -eq $AppDisplayName }
    }
    else {
        $report
    }

}