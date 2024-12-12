function Get-IntuneApp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("macOS", "Windows", "Android", "iOS")]
        [string]$Platform,
        [switch]$All
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph -NoWelcome
        }

        $URI = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/"
        
        $value = Invoke-MgGraphRequest -Uri $URI -Method GET | Select-Object -ExpandProperty value
        
        $macOS = @(
            "#microsoft.graph.macOsVppApp",
            "#microsoft.graph.macOSLobApp",
            "#microsoft.graph.macOSPkgApp",
            "#microsoft.graph.macOSOfficeSuiteApp",
            "#microsoft.graph.macOSMicrosoftEdgeApp"
        )
        #Hashtable for sorting
    
        $Android = @(
            "#microsoft.graph.managedAndroidStoreApp", #NOT SUPPORTED ANYMORE. Cannot be deleted.
            "#microsoft.graph.androidManagedStoreApp",
            "#microsoft.graph.androidLobApp",
            "#microsoft.graph.androidStoreApp"
        )
        #Hashtable for sorting
    
        $iOS_iPadOS = @(
            "#microsoft.graph.iosVppApp",
            "#microsoft.graph.iosLobApp"
        )
    
        $Win32 = @(
            "#microsoft.graph.win32LobApp",
            "#microsoft.graph.winGetApp", 
            "#microsoft.graph.windowsMobileMSI", 
            "#microsoft.graph.officeSuiteApp", 
            "#microsoft.graph.windowsWebApp", 
            "#microsoft.graph.windowsMicrosoftEdgeApp"
        )
    
    } 

    PROCESS {
        switch ($Platform) {
            "macOS" { $value | Where-Object { $_."@odata.type" -in $macOS } }
            "Windows" { $value | Where-Object { $_."@odata.type" -in $Win32 } }
            "Android" { $value | Where-Object { $_."@odata.type" -in $Android } }
            "iOS" { $value | Where-Object { $_."@odata.type" -in $iOS_iPadOS } }
        }

        if ($All) {
            $value
        }   
            
        
    }
}