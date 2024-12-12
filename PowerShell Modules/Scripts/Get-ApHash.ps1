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