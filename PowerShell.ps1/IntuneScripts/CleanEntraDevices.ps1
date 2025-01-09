# Script removes any device from Entra ID that does not have a matching Intune object.
function Remove-StaleEntraDevices {

    BEGIN {
        Connect-MgGraph -Identity
        $EntraDevices = Get-MgDevice -all
    }
    PROCESS {
        foreach ($device in $EntraDevices) {
            $ID = $device.DeviceId
            $value = Get-MgDeviceManagementManagedDevice -filter "AzureAdDeviceID eq '$ID'"

            if (-not $value) {
                $Trust = $device.TrustType
                if ($Trust -eq "AzureAd") {
                    $Name = $devicFe.DisplayName
                    Write-Verbose "Remove device $Name. Press any button to confirm." -Verbose
                    Read-Host
                    Remove-MgDevice -DeviceId $device.Id
                }
            }
        }
    }

}

Remove-StaleEntraDevices