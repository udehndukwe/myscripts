<#-----------------------------------------------------------------------------------------------------------------------------
# This script will delete an Autopilot hash from Intune and delete all associated Entra device objects.
# Does not remove device from Intune as a wipe should be initiated from the Intune portal or programmatically via Graph API before deleting from Intune
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

#Enable logging
Start-Transcript -Path $env:USERPROFILE\Documents\removeAutopilotDevices.log 

#Import CSV that contains device information. Make sure serial numbers on CSV are labeled "Serial"
$path = 'c:\Users\undukwe\OneDrive - STERIS Corporation\Documents\Spreadsheets\apdevices.csv'
$devices = Import-Csv -Path $path

#---------------------------------------------------------------------------------------------------------------------
####Collect and Remove Autopilot Devices
#---------------------------------------------------------------------------------------------------------------------
Write-Host "Retrieving Autopilot Hashes..." -ForegroundColor Yellow

#Collect all Autopilot Devices
$apdevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All


#Retrieve items from Autopilot collection that having matching serials in imported CSV
$apHashes = foreach ($device in $devices) {
    $apDevices | Where-Object SerialNumber -EQ $device.SerialNumber
}

#---------------------------------------------------------------------------------------------------------------------
####Collect and Remove Duplicate Device Objects
#---------------------------------------------------------------------------------------------------------------------

#Collect all Devices

Write-Host "Making collection of all Entra devices" -ForegroundColor Yellow
$alldevices = Get-MgDevice -All 

$removedDevices = New-Object System.Collections.Generic.List[System.Object]
$removedHashes = New-Object System.Collections.Generic.List[System.Object]

#Collect Device ID of removed AP device
Write-Host "Searching for duplicate device objects to be removed along with primary" -ForegroundColor Yellow
foreach ($hash in $apHashes) {
    $id = $hash.AzureActiveDirectoryDeviceId
    
    #Retrieve Entra device object based on the above ID. Catch bad ID values, report an error, and then store unprocessed hashes in a collection.
    try {
        $mgDevice = Get-MgDevice -Filter "DeviceId eq '$id'" -ErrorAction Stop
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
                Remove-MgDevice -DeviceId $dupe.Id -Confirm:$true
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
####Remove AP Hashes after removal of Entra Device Objects
#---------------------------------------------------------------------------------------------------------------------

Start-Sleep -Seconds 5

Read-Host -Prompt "Press any button to proceed with Autopilot hash removal after confirming that device objects have been successfully deleted"

Write-Host "Deleting Autopilot Hashes..." -ForegroundColor Yellow 
#Remove hashes from Autopilot

$counter = 1
:loop while ($counter -le 2) {
    foreach ($hash in $apHashes) {        
        # "VERBOSE: Device deletion is currently in progress" keeps showing up
        try {
            Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $hash.Id -ErrorAction Stop
            Write-Verbose -Message ("Autpilot device with S/N: " + $hash.SerialNumber + " has been deleted.")
        }   
        catch {
            if ($_.ErrorDetails.Message -match "has already been deleted") {
                Write-Verbose -Message ("Autpilot device with S/N: " + $hash.SerialNumber + " has already been deleted.") -Verbose
                $removedHashes.Add($hash)
                break loop
            }
            elseif ($_.ErrorDetails.Message -match "ZtdDeviceDeletionInProgess") {
                Write-Verbose -Message ("Device deletion is currently in progress") -Verbose
                $removedHashes.Add($hash)
                break loop
            }
            elseif ($_.ErrorDetails.Message -match 'ZtdDeviceAlreadyDeleted') {
                Write-Verbose -Message "Device has already been deleted" -Verbose
                break loop
            }
            else {
                Write-Verbose -Message "Device either does not exist in Autopilot or invalid value has been provided" -Verbose
                break loop
            }
        }
    } #foreach
    $counter++
    Start-Sleep -Seconds 5

}
Stop-Transcript

#Creates report of removed serials and exports them to CSV format
Write-Verbose -Message "Exporting a record of removed hashes and a record of removed devices"
$removedDevices | Export-Csv ./removedDevices.csv -Force -Append
$removedHashes | Export-Csv ./removedHashes.csv -Force -Append

