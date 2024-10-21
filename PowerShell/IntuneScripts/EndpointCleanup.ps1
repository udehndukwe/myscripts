<#-----------------------------------------------------------------------------------------------------------------------------
Goals:
-Remove targeted devices from: Entra ID, Intune, and Autopilot
----Android Devices
----iOS Devices
----Windows Devices

-Send a wipe command to devices enrolled in Intune
-Provide a report of removed devices and a log

Procedure:
BEGIN
1. Collect all Autopilot hashes
2. Collect all Entra devices along with any duplicate objects
3. Collect all Intune devices

PROCESS
4. Initiate wipe on devices that are Intune enrolled (Delets Intune object as well)
5. Delete device objects from Entra ID (along with duplicates)
6. Delete hash for Autopilot registered Windows devices 

NOTES: 
-Androids and iPads/iPhones should be cleaned up by the time Step 5 completes. Windows devices will be done when step 6 completes.
-Test as function and as multiple scripts


HELP:
$Path should be the path to your spreadsheet containing the serial numbers of the devices to be wiped/removed/cleaned
$exportPath should be the folder path where you want to export the reports created by this script. Filename is already specified, so only 
Ex: "C:\users\undukwe"
-----------------------------------------------------------------------------------------------------------------------------#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$Path = ".\devices.csv",
    [string]$exportPath = "INSERT_PATH_HERE"
)

###Intialize Lists for report and start logging###
$wipedDevices = [System.Collections.Generic.List[object]]::new()
$removedDevices = [System.Collections.Generic.List[object]]::new()
$removedHashes = [System.Collections.Generic.List[object]]::new()

Start-Transcript -Path C:\IntuneScriptLogs\EndpointCleanup.log


####Get AP Hashes####

if (-not (Get-MgContext) ) {
    Connect-MgGraph
}
Write-Verbose -Message "Collecting Autopilot Hashes" -Verbose

$apdevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All

#Importing CSV
$devices = Import-Csv -Path $Path

#Retrieve items from Autopilot collection that having matching serials in imported CSV
$apHashes = foreach ($device in $devices) {
    $apDevices.Where{ ($_.SerialNumber -eq $device.SerialNumber) }
}

try {
    $compare = Compare-Object -ReferenceObject $devices.SerialNumber -DifferenceObject $apHashes.SerialNumber
}
catch {
    if ($_.Exception.Message -match "Cannot bind argument to parameter 'DifferenceObject' because it is null.") {
        Write-Error -Message "No devices were found in Autopilot to be used for comparison."
    }
}
$notInAp = $Null
$notInAP = foreach ($item in $compare) {
    [PSCustomObject]@{
        SerialNumber = $item.inputobject
    }
}

Write-Verbose "Following devices not found in Autopilot:"  -Verbose
Start-Sleep 2
$notInAP.SerialNumber

####Get Intune Device Objects####

$allIntuneDevices = Get-MgDeviceManagementManagedDevice -All

##find matching Intune devices##

$intuneDevices = foreach ($device in $devices) {
    $allIntuneDevices.Where({ $_.SerialNumber -eq $device.SerialNumber })
}

#### Get Entra Devices #### 

$allEntraDevices = Get-MgDevice -All

##find matching Entra devices##

$entraDeviceObjects = foreach ($device in $intuneDevices) {
    $id = $device.AzureAdDeviceId

    $mgDevice = Get-MgDevice -Filter "DeviceID eq '$id'"

    try {
        $mgDevice = $allEntraDevices.Where({ $_.DeviceId -eq $id })
    }
    catch {
        Write-Error "Invalid ID. Please see ID value and make necessary corrections: $id" -Category InvalidArgument 
        $message = "Entra Device associated with S/N: " + $hash.SerialNumber.ToString() + " not processed"
        Write-Verbose $message -Verbose

    }

    $ZTDID = $mgDevice.PhysicalIds | Select-String [ZTDID] -SimpleMatch
    $allEntraDevices | Where-Object PhysicalIds -eq $ZTDID
}

## Initiate Intune Wipe ##

foreach ($intuneDevice in $intuneDevices) {
    Write-Verbose "Attempting to remove" $intuneDevice.DeviceName "from Intune...." -Verbose
    try {
        Clear-MgDeviceManagementManagedDevice -ManagedDeviceId $intuneDevice.Id -BodyParameter $params -ErrorAction Stop
    }
    # Error handling for permission related problems
    catch {
        $notAuthorizedMsg = "Application is not authorized to perform this operation. Application must have one of the following scopes: DeviceManagementManagedDevices.PrivilegedOperations.All" 

        if ($_.ErrorDetails.Message -match $notAuthorizedMsg) {
            Write-Error -Message "Please connect to Graph again and specify 'DeviceManagementManagedDevices.PrivilegedOperations.All' as a scope." 
        }
        else {
            # Nested try/catch to double check that device was deleted
            try {
                Clear-MgDeviceManagementManagedDevice -ManagedDeviceId $intuneDevice.Id -BodyParameter $params -ErrorAction Stop
            }
            catch {
                Write-Verbose -Message $intuneDevice.DeviceName " has been removed from Intune mobile device management" -Verbose
                $wipedDevices.Add($intuneDevice)
            }
        }
    }

}

## Remove Device objects from Entra ID

foreach ($entraDevice in $entraDeviceObjects) {
    try {
        Remove-MgDevice -DeviceId $entraDevice.Id -ErrorAction Stop
    }
    catch {
        if ($test.ErrorDetails.Message -match "Status: 404 (NotFound)*") {
            Write-Host "Device:"$entraDevice.DisplayName "not found in Entra ID" 
        
        }
    }
}

## Delete Autopilot Hashes

#Remove hashes from Autopilot

Write-Verbose "Deleting Autopilot Hashes...." -Verbose

foreach ($hash in $apHashes) {        
    try {
        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $hash.Id -ErrorAction Stop
        Write-Verbose -Message ("Autpilot device with S/N: " + $hash.SerialNumber + " has been deleted.")
        $removedHashes.Add($hash)
    }   
    catch {
        if ($_.ErrorDetails.Message -match "has already been deleted") {
            Write-Verbose -Message ("Autpilot device with S/N: " + $hash.SerialNumber + " has already been deleted.") -Verbose
            $removedHashes.Add($hash)

        }
        elseif ($_.ErrorDetails.Message -match "ZtdDeviceDeletionInProgess") {
            Write-Verbose -Message ("Device deletion is currently in progress") -Verbose
            $removedHashes.Add($hash)
        }
        elseif ($_.ErrorDetails.Message -match 'ZtdDeviceAlreadyDeleted') {
            Write-Verbose -Message "Device has already been deleted" -Verbose
            $removedHashes.Add($hash)
        }
        else {
            Write-Verbose -Message "Device either does not exist in Autopilot or invalid value has been provided" -Verbose
        }
    }
}

Stop-Transcript

Write-Verbose -Message "Exporting a record of removed hashes, a record of removed devices, and a record of devices that were not found in Autopilot in beginning of script..."

$obj = foreach ($device in $removedDevices) {
    [PSCustomObject]@{
        DisplayName = $device.DisplayName
        Model       = $device.Model
        RemovedDate = (get-date -Format MM/dd/yyyy)
    }

}

$obj2 = foreach ($hash in $removedHashes) {
    [PSCustomObject]@{
        SerialNumber = $hash.SerialNumber
        GroupTag     = $hash.GroupTag
        Model        = $hash.Model
        RemovedDate  = (get-date -Format MM/dd/yyyy)
    }

}



$obj | Export-Csv "$exportPath\removedDevices.csv" -Force  -NoTypeInformation
$obj2 | Export-Csv "exportPath\removedHashes.csv" -Force  -NoTypeInformation
$notInAP | Export-csv "exportPath\devicesNotFoundInAutopilot.csv" -Force -NoTypeInformation


