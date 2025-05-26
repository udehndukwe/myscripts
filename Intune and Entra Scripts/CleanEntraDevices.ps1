# Script removes any device from Entra ID that does not have a matching Intune object and has been stale for 30 days.
function Remove-StaleEntraDevices {

    BEGIN {
        Connect-MgGraph -Identity
        $EntraDevices = Get-MgDevice -all
        $DaysStale = 30
        $Now = Get-Date
    }
    PROCESS {
        foreach ($device in $EntraDevices) {
            $ID = $device.DeviceId
            $value = Get-MgDeviceManagementManagedDevice -filter "AzureAdDeviceId eq '$ID'"

            if (-not $value) {
                $Trust = $device.TrustType
                if ($Trust -eq "AzureAd") {
                    # Check if device is stale for 30 days
                    $LastActivity = $device.ApproximateLastSignInDateTime
                    if ($LastActivity -and (($Now - $LastActivity).Days -ge $DaysStale)) {
                        $Name = $device.DisplayName
                        Write-Verbose "Remove device $Name (stale for $($Now - $LastActivity)). Press any button to confirm." -Verbose
                        Read-Host
                        Remove-MgDevice -DeviceId $device.Id
                    }
                }
            }
        }
    }

}

Remove-StaleEntraDevices