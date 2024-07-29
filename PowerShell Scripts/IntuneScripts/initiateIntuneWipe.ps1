<#-----------------------------------------------------------------------------------------------------------------------------
# This script will initiate a wipe for Intune devices provided by CSV.
# Script built by Udeh Ndukwe
#------------------------------------------------------------------------------------------------------------------------------
# REQUIREMENTS 
#------------------------------------------------------------------------------------------------------------------------------
    # Install-Module Microsoft.Graph -Scope CurrentUser (Get-InstalledModule to verify)
    # CSV file with the managedDeviceId of each device to be wiped
    # Admin approval to utilize DeviceManagementManagedDevices.PrivilegedOperations.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All scopes
---------------------------------------------------------------------------------#>

#Imports modules for Autopilot device management commands and Graph authentication
Import-Module Microsoft.Graph.DeviceManagement.Actions
Import-Module Microsoft.Graph.Authentication 
        
#Connect to Graph
Connect-MgGraph -ClientId '469cf6a6-0b2c-4eff-94ee-7e1e72af91d2' -CertificateThumbprint "F1E3B4C5A6FBB15734031DEAD457EFCDF5E8C4FF" -TenantId '6d798b83-1769-4a29-9f77-8b9fae1560df'

#Enable logging
Start-Transcript -Path $env:USERPROFILE\Documents\initiateIntuneWipe.log 

#Create a list that will be populated with all devices removed by the script
#$deletedDevices = New-Object System.Collections.Generic.List[System.Object]


#Import CSV that contains device information. Make sure managed device IDs on CSV are labeled "SerialNumber"
$path = 
$devices = Import-Csv -Path $path

#Collect all Intune devices
$allIntuneDevices = Get-MgDeviceManagementManagedDevice -All

#Collect managedDeviceIds of each device that needs to be wiped

$intuneDevices = foreach ($device in $devices) {
    $allIntuneDevices | Where-Object SerialNumber -EQ $device.SerialNumber
}

#Set body parameters
$params = @{
    keepEnrollmentData = $false
    keepUserData = $false
}

#-----------------------------------------------------------------------------------------------------------------------------
####Initiate Intune Wipe
#-----------------------------------------------------------------------------------------------------------------------------

foreach ($intuneDevice in $intuneDevices) {
    Write-Host "Attempting to remove" $intuneDevice.DeviceName "from Intune...." -ForegroundColor Yellow
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
                Write-Host $intuneDevice.DeviceName " has been removed from Intune mobile device management"
                $wipedDevices.Add($intuneDevice)
            }
        }
    }

}
$date = Get-Date -Format "yyyymmdd"
$filename = "wipedDevices-$date"

$deleteReport | Export-csv -Path ./$filename.csv