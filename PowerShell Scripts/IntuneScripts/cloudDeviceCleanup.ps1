<#-----------------------------------------------------------------------------------------------------------------------------
# This script will delete an Autopilot hash from Intune, delete all associated Entra device objects, and delete the device record from Intune
# Script built by Udeh Ndukwe
#------------------------------------------------------------------------------------------------------------------------------
# REQUIREMENTS 
#------------------------------------------------------------------------------------------------------------------------------
    # Install-Module Microsoft.Graph -Scope CurrentUser (Get-InstalledModule to verify)
    # CSV file with the Serial Numbers of devices to be removed (Replace existing value for $Path with path of your CSV)
---------------------------------------------------------------------------------#>

#Imports modules for Autopilot device management commands and Graph authentication
Import-Module Microsoft.Graph.DeviceManagement.Enrollment 
Import-Module Microsoft.Graph.Authentication 
        
#Connect to Graph
Connect-MgGraph 

#Enable logging. Checks for existence of OneDrive documents folder. Exports log to that folder if it exists. Otherwise, log is exported to default "Documents" folder in Windows.

$oneDrivePath = "$env:USERPROFILE\OneDrive - STERIS Corporation\Documents\"
$path = "$env:USERPROFILE\Documents\removeAutopilotDevices.log"

if (Test-Path $oneDrivePath) {
    Start-Transcript $oneDrivePath\removeAutopilotDevices.log
}
else {
    Start-Transcript -Path $path
}


#Import CSV that contains device information. Make sure serial numbers on CSV are labeled "Serial"
$path = "c:\Users\undukwe\Downloads\Steris Laptops 287363.csv"
$devices = Import-Csv -Path $path

#---------------------------------------------------------------------------------------------------------------------
####Collect Autopilot Hashes
#---------------------------------------------------------------------------------------------------------------------
Write-Host "Retrieving Autopilot Hashes..." -ForegroundColor Yellow

#Collect all Autopilot Devices
$apdevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All


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

Write-Host "Following devices not found in Autopilot:" -ForegroundColor Yellow
Start-Sleep 2
$notInAP.SerialNumber

#---------------------------------------------------------------------------------------------------------------------
####Collect and Remove Duplicate Device Objects
#---------------------------------------------------------------------------------------------------------------------

#Collect all Devices

Write-Host "Making collection of all Entra devices" -ForegroundColor Yellow
$alldevices = Get-MgDevice -All 

$removedDevices = [System.Collections.Generic.List[object]]::new()
$removedHashes = [System.Collections.Generic.List[object]]::new()

#Collect Device ID of removed AP device
Write-Host "Searching for duplicate device objects to be removed along with primary" -ForegroundColor Yellow
foreach ($hash in $apHashes) {
    $id = $hash.AzureActiveDirectoryDeviceId
    
    #Retrieve Entra device object based on the above ID. Catch bad ID values, report an error, and then store unprocessed hashes in a collection.
    try {
        $mgDevice = $allDevices.Where({ $_.DeviceId -eq $id })
    }
    catch {
        Write-Error "Invalid ID. Please see ID value and make necessary corrections: $id" -Category InvalidArgument 
        $message = "Entra Device associated with S/N: " + $hash.SerialNumber.ToString() + " not processed"
        Write-Verbose $message -Verbose
    }

    #Two if loops that check to see if a device was found and if a ZTDID was found. 
    if ($null -eq $mgDevice) {
        Write-Error "Variable is Null. No Entra device with ID: $id found"
    }
    else {
        #Get ZTDID of that device
        $ZTDID = $mgDevice.PhysicalIds | Select-String [ZTDID] -SimpleMatch

        if ($null -eq $ZTDID) {
            Write-Error "Variable is Null. No ZTDID found for this device. Check to see if Autopilot hash still exists in Intune"
        }
        else {
            #Find all devices in Entra that have the same ZTDID
            $dupeDevices = $alldevices | Where-Object PhysicalIds -Contains $ZTDID  

            #Remove all instances of this physical device
            foreach ($dupe in $dupeDevices) {
                Remove-MgDevice -DeviceId $dupe.Id
                $checkDevice = Get-MgDevice -DeviceId $dupe.id -ErrorAction SilentlyContinue
                if ($null -eq $checkDevice) {
                    $notif = $dupe.DisplayName + " has been removed"
                    Write-Verbose -Message $notif -Verbose 
                    $removedDevices.Add($dupe)
                }
            }     
        }
    }
}

#---------------------------------------------------------------------------------------------------------------------
####Remove device object from Intune
#---------------------------------------------------------------------------------------------------------------------

Write-Verbose -Message "Removing Intune device record(s)"
foreach ($hash in $apHashes) {
    try {
        Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $hash.ManagedDeviceId -ErrorAction Stop
    }
    catch {
        if ($test.ErrorDetails.Message -match "Status: 404 (NotFound)*") {
            Write-Host "Device with S/N:"$hash.SerialNumber"not found in Intune" 
        
        }
    }
}
#---------------------------------------------------------------------------------------------------------------------
####Remove AP Hashes after removal of Entra Device Objects
#---------------------------------------------------------------------------------------------------------------------

Start-Sleep -Seconds 5

Read-Host -Prompt "Press any button to proceed with Autopilot hash removal after confirming that device objects have been successfully deleted"

Write-Host "Deleting Autopilot Hashes..." -ForegroundColor Yellow 
#Remove hashes from Autopilot

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
} #foreach
Start-Sleep -Seconds 5

Stop-Transcript

#Creates report of removed Autopilot hashes, removed Entra devices. and devices that were not processed and exports them to CSV format

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


if (Test-Path $oneDrivePath) {
    $obj | Export-Csv "$env:USERPROFILE\OneDrive - STERIS Corporation\Documents\removedDevices.csv" -Force  -NoTypeInformation
    $obj2 | Export-Csv "$env:USERPROFILE\OneDrive - STERIS Corporation\Documents\removedHashes.csv" -Force  -NoTypeInformation
    $notInAP | Export-csv "$env:USERPROFILE\OneDrive - STERIS Corporation\Documents\devicesNotFoundInAutopilot.csv" -Force -NoTypeInformation

}
else {
    $obj | Export-Csv $env:USERPROFILE\Documents\removedDevices.csv -Force  -NoTypeInformation
    $obj2 | Export-Csv $env:USERPROFILE\Documents\removedHashes.csv -Force  -NoTypeInformation
    $notInAP | Export-csv $env:USERPROFILE\Documents\devicesNotFoundInAutopilot.csv -Force -NoTypeInformation

}
