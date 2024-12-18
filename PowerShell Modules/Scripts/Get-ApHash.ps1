<#
.SYNOPSIS
    Retrieves Autopilot hash information for devices based on their serial numbers.

.DESCRIPTION
    This function fetches Autopilot hash information for devices using their serial numbers.

.PARAMETER SerialNumber
    The serial numbers of the devices.

.EXAMPLE
    Get-APHash -SerialNumber "12345"

.NOTES
    Author: Udeh Ndukwe
    Date: Today's Date
#>
function Get-APHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$SerialNumber
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
        $script:apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All

    }
    PROCESS {
        foreach ($serial in $SerialNumber) {
            $device = $apDevices.where{ ($_.SerialNumber -eq $serial) }

            $obj = [PSCustomObject]@{
                HashID          = $device.Id
                Serial          = $device.SerialNumber
                EntraDeviceID   = $device.AzureActiveDirectoryDeviceId
                IntuneDeviceID  = $device.ManagedDeviceId
                GroupTag        = $device.GroupTag
                Model           = $device.Model
                EnrollmentState = $device.EnrollmentState
            }
            Write-Output $obj

        }
    }
}