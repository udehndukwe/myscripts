<#---

$permissionList = @(
    'DeviceManagementServiceConfig.ReadWrite.All',
    'Files.ReadWrite.All',
    'Sites.ReadWrite.all',
    'DeviceManagementManagedDevices.ReadWrite.All'
)
    
---#>

Write-Verbose 'Connecting to Microsoft Graph.' -Verbose
Connect-MgGraph -Identity

Write-Verbose 'Retrieving site information.' -Verbose
$URI = "https://graph.microsoft.com/v1.0/sites/?`$search=`"rrfileshare01`""
$site = Invoke-MgGraphRequest -Method GET -Uri $URI | Select-Object -ExpandProperty Value

$siteId = $site.id
Write-Verbose "Site ID: $siteId" -Verbose

Write-Verbose 'Retrieving documents folder information.' -Verbose
$DocumentsFolder = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drives" | Select-Object -ExpandProperty Value

Write-Verbose 'Searching for EndpointCleanup folder.' -Verbose
$EndpointCleanup = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drives/$($DocumentsFolder.id)/root/children" | Select-Object -ExpandProperty Value | Where-Object Name -EQ 'EndpointCleanup'

$EndpointCleanupDriveID = $EndpointCleanup | Select-Object -ExpandProperty parentReference | Select-Object -ExpandProperty driveId
Write-Verbose "EndpointCleanup Drive ID: $EndpointCleanupDriveID" -Verbose

Write-Verbose 'Retrieving files in EndpointCleanup folder.' -Verbose
$EndpointCleanupFiles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drives/$EndpointCleanupDriveID/items/$($EndpointCleanup.id)/children"

foreach ($file in $EndpointCleanupFiles.value) {
    $URI = $file.'@microsoft.graph.downloadUrl'
    Write-Verbose "Downloading file: $($file.name)" -Verbose
    Invoke-RestMethod -Uri $URI -OutFile "./$($file.name)"
}

Write-Verbose 'Importing CSV file.' -Verbose
$devices = Import-Csv -Path './Devices_To_Retire.csv'

Write-Verbose 'Initializing lists.' -Verbose
$entraDeviceObjects = [System.Collections.Generic.List[object]]::new()
$wipedDevices = [System.Collections.Generic.List[object]]::new()
$removedDevices = [System.Collections.Generic.List[object]]::new()
$removedHashes = [System.Collections.Generic.List[object]]::new()
$notInAutoPilot = [System.Collections.Generic.List[object]]::new()

Write-Verbose 'Retrieving Autopilot device identities.' -Verbose
$apHashes = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities' | Select-Object -ExpandProperty Value

$apHashes = foreach ($device in $devices) {
    $apDevice = $apHashes | Where-Object { $_.SerialNumber -EQ $device.SerialNumber -and $device.OS -eq 'Windows' } 
    if (-not $apDevice -and $device.OS -eq 'Windows') {
        Write-Verbose "Windows device with serial number $($device.SerialNumber) not found in Autopilot." -Verbose
        $notInAutoPilot.Add($device)
    }
}

Write-Verbose 'Retrieving all Intune devices.' -Verbose
$allIntuneDevices = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/deviceManagement/managedDevices' | Select-Object -ExpandProperty Value

Write-Verbose 'Finding matching Intune devices.' -Verbose
$intuneDevices = foreach ($device in $devices) {
    $allIntuneDevices | Where-Object { $_.SerialNumber -eq $device.SerialNumber }
}

Write-Verbose 'Retrieving Entra devices.' -Verbose
$allEntraDevices = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/devices' | Select-Object -ExpandProperty Value

Write-Verbose 'Finding matching Entra devices, including duplicated device objects.' -Verbose
foreach ($device in $intuneDevices) {
    $id = $device.AzureAdDeviceId
    $mgDevice = Invoke-MgGraphRequest -Method GET -Uri "v1.0/devices?`$filter=DeviceID eq '$id'" | Select-Object -ExpandProperty Value

    try {
        $mgDevice = $allEntraDevices | Where-Object { $_.DeviceId -eq $id }
    }
    catch {
        Write-Error "Invalid ID. Please see ID value, make necessary corrections, and re-run script: $id" -Category InvalidArgument
        $message = 'Exiting script.'
        Write-Verbose $message -Verbose
    }
    if ($device.operatingSystem -eq 'Windows') {
        $ZTDID = $mgDevice.PhysicalIds | Select-String [ZTDID] -SimpleMatch
        $entraDeviceObjects.Add(($allEntraDevices | Where-Object PhysicalIds -EQ $ZTDID))
    }
    else {
        $duplicateDevices = $allEntraDevices | Where-Object { $_.displayName -eq $mgDevice.displayName }
        if ($duplicateDevices.Count -gt 1) {
            $entraDeviceObjects.Add(($duplicateDevices | Select-Object DisplayName, OperatingSystem))
        }
        else {
            $entraDeviceObjects.Add(($mgDevice | Select-Object DisplayName, OperatingSystem))
        }
    }
}

foreach ($intuneDevice in $intuneDevices) {
    Write-Verbose "Attempting to remove $($intuneDevice.DeviceName) from Intune...." -Verbose
    try {
        if ($intunedevice.operatingSystem -eq 'macOS') { 
            $params = @{
                keepEnrollmentData = $false
                keepUserData       = $false
                macOsUnlockCode    = '123456'
            }
        }
        else {
            $params = @{
                keepEnrollmentData = $false
                keepUserData       = $false
            }
        }
        Invoke-MgGraphRequest -Method POST -Uri "v1.0/deviceManagement/managedDevices/$($intunedevice.id)/wipe" -Body $params -ErrorAction Stop
    }
    catch {
        $notAuthorizedMsg = 'Application is not authorized to perform this operation. Application must have one of the following scopes: DeviceManagementManagedDevices.PrivilegedOperations.All' 

        if ($_.ErrorDetails.Message -match $notAuthorizedMsg) {
            Write-Error -Message "Please connect to Graph again and specify 'DeviceManagementManagedDevices.PrivilegedOperations.All' as a scope." 
        }
        else {
            try {
                Invoke-MgGraphRequest -Method POST -Uri "v1.0/deviceManagement/managedDevices/$($intunedevice.id)/wipe" -Body $params -ErrorAction Stop
            }
            catch {
                Write-Verbose -Message "$($intuneDevice.DeviceName) has been removed from Intune mobile device management" -Verbose
                $wipedDevices.Add(($intuneDevice | Select-Object DeviceName, SerialNumber))
            }
        }
    }
}

foreach ($entraDevice in $entraDeviceObjects) {
    try {
        Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/devices/$($entraDevice.id)" -ErrorAction Stop
    }
    catch {
        if ($_.ErrorDetails.Message -match 'Status: 404 (NotFound)*') {
            Write-Host 'Device:' $entraDevice.DisplayName 'not found in Entra ID' 
        }
    }
}

foreach ($hash in $apHashes) {        
    try {
        Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$($hash.id)" -ErrorAction Stop
        Write-Verbose -Message ('Autpilot device with S/N: ' + $hash.SerialNumber + ' has been deleted.')
        $removedHashes.Add(($apHashes | Select-Object SerialNumber, Model))
    }   
    catch {
        if ($_.ErrorDetails.Message -match 'has already been deleted') {
            Write-Verbose -Message ('Autpilot device with S/N: ' + $hash.SerialNumber + ' has already been deleted.') -Verbose
            $removedHashes.Add(($apHashes | Select-Object SerialNumber, Model))
        }
        elseif ($_.ErrorDetails.Message -match 'ZtdDeviceDeletionInProgess') {
            Write-Verbose -Message ('Device deletion is currently in progress') -Verbose
            $removedHashes.Add(($apHashes | Select-Object SerialNumber, Model))
        }
        elseif ($_.ErrorDetails.Message -match 'ZtdDeviceAlreadyDeleted') {
            Write-Verbose -Message 'Device has already been deleted' -Verbose
            $removedHashes.Add(($apHashes | Select-Object SerialNumber, Model))
        }
        else {
            Write-Verbose -Message 'Device either does not exist in Autopilot or invalid value has been provided' -Verbose
        }
    }
}

Write-Verbose 'Creating report objects.' -Verbose
$obj = foreach ($device in $removedDevices) {
    [PSCustomObject]@{
        DisplayName = $device.DisplayName
        Model       = $device.Model
        RemovedDate = (Get-Date -Format MM/dd/yyyy)
    }
}

$obj2 = foreach ($hash in $removedHashes) {
    [PSCustomObject]@{
        SerialNumber = $hash.SerialNumber
        GroupTag     = $hash.GroupTag
        Model        = $hash.Model
        RemovedDate  = (Get-Date -Format MM/dd/yyyy)
    }
}

Write-Verbose 'Exporting reports to Excel.' -Verbose
Export-Excel -Path './EndpointCleanupReport.xlsx' -InputObject $obj -WorksheetName 'RemovedDevices'
Export-Excel -Path './EndpointCleanupReport.xlsx' -InputObject $obj2 -WorksheetName 'RemovedHashes' -Append
Export-Excel -Path './EndpointCleanupReport.xlsx' -InputObject $wipedDevices -WorksheetName 'WipedDevices' -Append

Write-Verbose 'Sending email with report attachment.' -Verbose
$params = @{
    message         = @{
        subject      = 'Endpoint Cleanup Report'
        body         = @{
            contentType = 'HTML'
            content     = 'See attached report'
        }
        toRecipients = @(
            @{
                emailAddress = @{
                    address = 'udehndukwe@gmail.com'
                }
            } 
            @{
                emailAddress = @{
                    address = 'udeh.ndukwe@relrepairs.com'
                }
            }
        )
        attachments  = @(
            @{
                '@odata.type' = '#microsoft.graph.fileAttachment'
                name          = 'EndpointCleanupReport.xlsx'
                contentBytes  = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes('.\EndpointCleanupReport.xlsx'))
            }
        )
    }
    saveToSentItems = 'true'
}

Invoke-MgGraphRequest -Method POST -Uri 'v1.0/users/endpointengineeringteam@relrepairs.com/sendMail' -Body $params

Remove-Item ./EndpointCleanupReport.xlsx -Force

