<#
.SYNOPSIS
    Clears Autopilot hashes for devices based on their IDs or serial numbers.

.DESCRIPTION
    This function clears Autopilot hashes for devices using their IDs or serial numbers.

.PARAMETER Id
    The ID of the device to clear the Autopilot hash for.

.PARAMETER SerialNumber
    The serial number of the device to clear the Autopilot hash for.

.EXAMPLE
    Clear-ApHash -Id "12345"

.NOTES
    Author: Udeh Ndukwe
    Date: Today's Date
#>
function Clear-ApHash {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Id,
        [string]$SerialNumber
    )
    begin {
        if ($SerialNumber) {
            $hashes = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        }
    }
    process {
        if ($SerialNumber) {
            $Id = $hashes | Where-Object { $_.serialNumber -eq $SerialNumber } | Select-Object -ExpandProperty id
            if ($PSCmdlet.ShouldProcess("Device with ID $Id", "Remove")) {
                Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Device with ID $Id", "Remove")) {
                Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id
            }
        }
    }
}