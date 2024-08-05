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
-----------------------------------------------------------------------------------------------------------------------------#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$Path = ".\devices.csv"
)

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

Write-Host "Following devices not found in Autopilot:" -ForegroundColor Yellow
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

foreach ($device in $intuneDevices) {
    $id = $device.AzureAdDeviceId

    try {
        $mgDevice = $allEntraDevices.Where({$_.DeviceId -eq $id})
    } catch {
        Write-Error "Invalid ID. Please see ID value and make necessary corrections: $id" -Category InvalidArgument 
        $message = "Entra Device associated with S/N: " + $hash.SerialNumber.ToString() + " not processed"
        Write-Verbose $message -Verbose

    }
}



