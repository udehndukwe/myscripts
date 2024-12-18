<#
.SYNOPSIS
    Identifies duplicate Entra devices based on their IDs.

.DESCRIPTION
    This function checks for duplicate Entra devices using their IDs and returns the duplicate devices.

.PARAMETER EntraDeviceID
    The IDs of the Entra devices to check for duplicates.

.PARAMETER hash
    Additional hash information for the devices.

.EXAMPLE
    Get-EntraDupe -EntraDeviceID "device1", "device2"

.NOTES
    Author: Udeh Ndukwe
    Date: Today's Date
#>
function Get-EntraDupe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('AzureActiveDirectoryDeviceID')]
        [string[]]$EntraDeviceID,
        [string[]]$hash
    )

    BEGIN {
        $alldevices = Get-MgDevice -All
        Set-Variable 'alldevices' -Value $alldevices -Scope Script

    }
    PROCESS {
        foreach ($id in $EntraDeviceID) {
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
                }
            }



        }
        foreach ($device in $dupeDevices) {
            $obj = [PSCustomObject]@{
                ID            = $device.DeviceId
                EntraDeviceID = $device.Id
            }
            Write-Output $obj
        }
    }
}