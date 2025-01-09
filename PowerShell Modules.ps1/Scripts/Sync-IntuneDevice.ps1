function Sync-IntuneDevice {
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
            $managedDeviceId = (Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$DeviceName'").Id
        }
        elseif ($SerialNumber) {
            $managedDeviceId = (Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$SerialNumber'").Id 
        }

    }

    process {
        Write-Verbose "Sending Sync command..." 
        Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $managedDeviceId 
    }

}