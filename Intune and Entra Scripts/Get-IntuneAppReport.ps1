function Get-IntuneAppStatusReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AppID,
        [switch]$Export,
        [switch]$Display
    )
    
    $MobileAppURI = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppID"
    $FileName = (Invoke-MgGraphRequest -Method GET -Uri $MobileAppURI | Select -expand DisplayName) -replace '[^a-zA-Z0-9]', '' # Replace with the actual application name

    $params = @{
        filter = "(ApplicationId eq '$AppID')"
    }
    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/getAppStatusOverviewReport"
    Invoke-MgGraphRequest -Method POST -uri $uri -OutputFilePath ".\$FileName.json" -Body $params
    # Define the application name variable
    $AppName = get-mgdeviceappManagementMobileApp -MobileAppId $AppID | Select -expand DisplayNAme # Replace with the actual application name

    # Read the JSON file
    $jsonContent = Get-Content -Path ".\$FileName.json"-Raw | ConvertFrom-Json
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
    $TableList =  @($table)
    $Date = get-date -Format MM/dd/yyyy
    if ($Export) {
        $TableList | Export-Excel -Path .\AppStatusReport.xlsx -AutoSize -WorksheetName "AppInstallStatuses-$Date" -BoldTopRow -TableName "AppStatuses"
    }
    if ($Display) {
        return $TableList
    }

}


function Format-Sheet {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $file,
        [switch]
        $Formats
    )
    IF ($Format) {
        # Format Sheet
        $excel = Open-ExcelPackage -Path $file
        $worksheet = $excel.Workbook.Worksheets

        $newRange = $worksheet.Cells
        foreach ($cell in $newRange) {
            $cell.Style.Border.BorderAround("Medium")
        }
        Close-ExcelPackage -ExcelPackage $excel 

        & $file
    }
}

foreach ($app in $filter) {
    $ID = $app.id
    Get-IntuneAppStatusReport -AppID $ID -Export
}

