function New-PwshModule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name
    )
    BEGIN {
        $pwshModulePath = "C:\Users\undukwe\OneDrive - STERIS Corporation\Documents\PowerShell\Modules"
    }
    PROCESS {
        $module = New-PSModule -Name $Name
        Move-Item -Path $module.FullName -Destination $pwshModulePath
    }

}

Get-MgBetaDeviceAppManagementMobileApp -Filter "((isof('microsoft.graph.managedIOSStoreApp') and microsoft.graph.managedApp/appAvailability eq microsoft.graph.managedAppAvailability'lineOfBusiness') or isof('microsoft.graph.iosLobApp') or isof('microsoft.graph.iosStoreApp') or isof('microsoft.graph.iosVppApp') or isof('microsoft.graph.managedIOSLobApp') or (isof('microsoft.graph.managedIOSStoreApp') and microsoft.graph.managedApp/appAvailability eq microsoft.graph.managedAppAvailability'global') or isof('microsoft.graph.webApp') or isof('microsoft.graph.iOSiPadOSWebClip')) and (microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true)" -Sort "displayName" 