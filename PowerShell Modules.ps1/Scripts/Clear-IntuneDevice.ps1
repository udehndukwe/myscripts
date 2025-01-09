<#
.SYNOPSIS
    Sends a wipe command to Intune devices based on their names or serial numbers.

.DESCRIPTION
    This function sends a wipe command to Intune devices using their names or serial numbers.

.PARAMETER DeviceName
    The names of the devices to wipe.

.PARAMETER SerialNumber
    The serial numbers of the devices to wipe.

.EXAMPLE
    Clear-IntuneDevice -DeviceName "Device1"

.NOTES
    Author: Udeh Ndukwe
    Date: 12/18/2024
#>
function Clear-IntuneDevice {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$DeviceName,
        [string[]]$SerialNumber
    )

    begin {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }

        if ($DeviceName) {
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$DeviceName'"
        }
        elseif ($SerialNumber) {
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$SerialNumber'"
        }
        $params = @{
            keepEnrollmentData = $false
            keepUserData       = $false
        }
    }

    process {
        
        foreach ($device in $managedDevice) {
            $Name = $device.DeviceNAme
            Write-Verbose "Sending Wipe command..." -Verbose
            Clear-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id -BodyParameter $params -ErrorAction Stop -Confirm:$true
            Write-Verbose "Wipe initiated for $Name." -Verbose
        }
    }
}

<#
.SYNOPSIS
    Renames all files in the current directory to have a .ps1 extension.

.DESCRIPTION
    This script renames all files in the current directory to have a .ps1 extension.

.EXAMPLE
    .\Clear-IntuneDevice.ps1

.NOTES
    Author: Udeh Ndukwe
    Date: 12/18/2024
#>
$files = ls

foreach ($file in $files) {
    Rename-item -Path $file.FullName -NewName ($file.BaseName + ".ps1")
}