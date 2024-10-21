function Get-APHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SerialNumber
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }

        $apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
    }
    PROCESS {
        foreach ($serial in $SerialNumber) {
            $device = $apDevices.where{ ($_.SerialNumber -eq $serial) }

            $obj = [PSCustomObject]@{
                HashID         = $device.Id
                Serial         = $device.SerialNumber
                EntraDeviceID  = $device.AzureActiveDirectoryDeviceId
                IntuneDeviceID = $device.ManagedDeviceId
                AssociatedUser = $device.UserPrincipalName
            }
            Write-Output $obj

        }
    }
}

function Remove-APHash {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string[]]$SerialNumber,
        [string[]]$Hash
    )

    BEGIN {    
        $apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        $removedHashes = New-Object System.Collections.Generic.List[System.Object]

    }

    PROCESS {
        $device = $apDevices.where{ ($_.SerialNumber -eq $SerialNumber) }
        Write-Verbose "Device with S/N: $device.SerialNumber will be removed from Autopilot" -Verbose
        Read-Host -Prompt "Press enter to continue"
        Start-sleep 5
        try {
            Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $device.Id
            $removedHashes.Add($device)
        } catch {
            Write-Output $_.Exception.Message
        }
    }

    END {
        Write-Output $removedHashes
    }
    

}

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
                } else {
                    #Find all devices in Entra that have the same ZTDID
                    $dupeDevices = $alldevices | Where-Object PhysicalIds -Contains $ZTDID
                }
            }



        }
        foreach ($device in $dupeDevices) {
            $obj = [PSCustomObject]@{
                ID = $device.DeviceId
                EntraDeviceID  = $device.Id
            }
            Write-Output $obj
        }
    }
}

function Remove-EntraDevice {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string[]]$EntraDeviceID
    )

    PROCESS {
        foreach ($id in $EntraDeviceID) {
            Remove-MgDevice -DeviceId $id -WhatIf
        }
    }
}