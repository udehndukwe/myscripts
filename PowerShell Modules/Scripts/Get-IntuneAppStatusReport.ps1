function Get-IntuneAppStatusReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AppID,
        [switch]$Export,
        [switch]$Display,
        [string]$JSONPath = "$env:USERPROFILE\AppJSONs"
    )
    # Make temp dir
    $value = Test-Path $JSONPath
    if (-not $value) {
        New-Item -ItemType Directory -Path $JSONPath -ErrorAction SilentlyContinue
    }

    $MobileAppURI = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppID"
    $FileName = (Invoke-MgGraphRequest -Method GET -Uri $MobileAppURI | Select-Object -ExpandProperty DisplayName) -replace '[^a-zA-Z0-9]', '' # Replace with the actual application name

    $params = @{
        filter = "(ApplicationId eq '$AppID')"
    }
    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/getAppStatusOverviewReport"
    Invoke-MgGraphRequest -Method POST -Uri $URI -OutputFilePath "$JSONPath\$FileName.json" -Body $params
    # Define the application name variable
    $AppName = Invoke-MgGraphRequest -Method GET -Uri $MobileAppURI | Select-Object -ExpandProperty DisplayName # Replace with the actual application name

    # Read the JSON file
    $jsonContent = Get-Content -Path "$JSONPath\$FileName.json" -Raw | ConvertFrom-Json
    $jsonContent = $jsonContent.Values -split " " 
    # Extract the values from the JSON content
    $applicationId = $jsonContent[0]
    $failedDeviceCount = $jsonContent[1]
    $pendingInstallDeviceCount = $jsonContent[2]
    $installedDeviceCount = $jsonContent[3]
    $notInstalledDeviceCount = $jsonContent[4]
    $notApplicableDeviceCount = $jsonContent[5]

    # Create a custom object for the table
    $table = [PSCustomObject]@{
        AppName                   = $AppName
        ApplicationId             = $applicationId
        FailedDeviceCount         = $failedDeviceCount
        PendingInstallDeviceCount = $pendingInstallDeviceCount
        InstalledDeviceCount      = $installedDeviceCount
        NotInstalledDeviceCount   = $notInstalledDeviceCount
        NotApplicableDeviceCount  = $notApplicableDeviceCount
    }

    # Display the table
    $TableList = @($table)
    $Date = Get-Date -Format MM/dd/yyyy
    if ($Export) {
        $TableList | Export-Excel -Path .\AppStatusReport.xlsx -AutoSize -WorksheetName "AppInstallStatuses-$Date" -BoldTopRow -TableName "AppStatuses"
    }
    if ($Display) {
        return $TableList
    }

    # Clean temp directory
    Remove-Item -Path $JSONPath -Recurse -Force
}
