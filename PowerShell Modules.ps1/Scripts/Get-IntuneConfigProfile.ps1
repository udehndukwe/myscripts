function Get-IntuneConfigProfile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet("Windows", "macOS", "Android", "iOS")]
        [string]$Platform,
        [switch]$All,
        [switch]$AllProperties
    )
    BEGIN {
        $configlist = [System.Collections.Generic.List[PSCustomObject]]::new()

  
        $Windows = @(
            "#microsoft.graph.windows10GeneralConfiguration",
            "#microsoft.graph.windows10CustomConfiguration",
            "#microsoft.graph.windowsDomainJoinConfiguration",
            "#microsoft.graph.windowsWifiEnterpriseEAPConfiguration",
            "#microsoft.graph.windows81TrustedRootCertificate",
            "#microsoft.graph.windowsUpdateForBusinessConfiguration",
            "#microsoft.graph.windows81SCEPCertificateProfile",
            "#microsoft.graph.windowsDeliveryOptimizationConfiguration",
            "#microsoft.graph.windowsKioskConfiguration",
            "#microsoft.graph.editionUpgradeConfiguration",
            "#microsoft.graph.windowsHealthMonitoringConfiguration",
            "#microsoft.graph.sharedPCConfiguration"
        )

        $macOS = @(
            "#microsoft.graph.macOSCustomConfiguration",
            "#microsoft.graph.macOSGeneralDeviceConfiguration",
            "#microsoft.graph.macOSCustomAppConfiguration",
            "#microsoft.graph.macOSScepCertificateProfile",
            "#microsoft.graph.macOSTrustedRootCertificate",
            "#microsoft.graph.macOSSoftwareUpdateConfiguration"
        )

        $iOS = @(
            "#microsoft.graph.iosUpdateConfiguration",
            "#microsoft.graph.iosGeneralDeviceConfiguration",
            "#microsoft.graph.iosTrustedRootCertificate",
            "#microsoft.graph.iosScepCertificateProfile",
            "#microsoft.graph.iosEnterpriseWiFiConfiguration",
            "#microsoft.graph.iosEasEmailProfileConfiguration",
            "#microsoft.graph.iosMobileAppConfiguration"
        )

        $Android = @(
            "#microsoft.graph.androidDeviceOwnerEnterpriseWiFiConfiguration",
            "#microsoft.graph.androidWorkProfileGeneralDeviceConfiguration",
            "#microsoft.graph.androidDeviceOwnerGeneralDeviceConfiguration",
            "#microsoft.graph.androidGeneralDeviceConfiguration",
            "#microsoft.graph.androidDeviceOwnerScepCertificateProfile",
            "#microsoft.graph.androidWorkProfileNineWorkEasConfiguration",
            "#microsoft.graph.androidDeviceOwnerTrustedRootCertificate",
            "#microsoft.graph.androidManagedStoreAppConfiguration"
        )
    

        $DCURIs = @(
            "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$expand=Assignments",
            "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$expand=Assignments",
            "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$expand=Assignments",
            "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations?`$expand=Assignments"
        )
        
    }
    PROCESS {
        $values = foreach ($uri in $DCURIs) {
            Invoke-MgGraphRequest -Method GET -Uri $uri
        }

        foreach ($value in $values.value) {
            switch ($Platform) {
                { $Windows -contains $value."@odata.type" } { $Platform = "Windows" }
                { $macOS -contains $value."@odata.type" } { $Platform = "macOS" }
                { $iOS -contains $value."@odata.type" } { $Platform = "iOS" }
                { $Android -contains $value."@odata.type" } { $Platform = "Android" }
            } 
            if ($value.Name) {
                [PSCustomObject]@{
                    DisplayName  = $value.Name
                    id           = $value.id
                    "Created On" = $value.createdDateTime
                    Assignments  = $value.Assignments
                    Platform = $Platform 

                }
            }
            if ($value.DisplayName) {
                [PSCustomObject]@{
                    DisplayName  = $value.DisplayName
                    id           = $value.id
                    "Created On" = $value.createdDateTime
                    Assignments  = $value.Assignments
                    Platform = $Platform 

                }
            }
        }
    }

}


