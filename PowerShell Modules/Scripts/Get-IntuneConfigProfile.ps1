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

        $Android = @(
            "microsoft.graph.androidDeviceOwnerEnterpriseWiFiConfiguration",
            "microsoft.graph.androidWorkProfileGeneralDeviceConfiguration",
            "microsoft.graph.androidDeviceOwnerGeneralDeviceConfiguration",
            "microsoft.graph.androidGeneralDeviceConfiguration",
            "microsoft.graph.androidDeviceOwnerScepCertificateProfile",
            "microsoft.graph.androidWorkProfileNineWorkEasConfiguration",
            "microsoft.graph.androidDeviceOwnerTrustedRootCertificate"
        )

        $macOS = @(
            "microsoft.graph.macOSCustomConfiguration",
            "microsoft.graph.macOSGeneralDeviceConfiguration",
            "microsoft.graph.macOSCustomAppConfiguration",
            "microsoft.graph.macOSScepCertificateProfile",
            "microsoft.graph.macOSTrustedRootCertificate",
            "microsoft.graph.macOSSoftwareUpdateConfiguration",
            "macOS"
        )

        $Windows = @(
            "microsoft.graph.windows10GeneralConfiguration",
            "microsoft.graph.windows10CustomConfiguration",
            "microsoft.graph.windowsDomainJoinConfiguration",
            "microsoft.graph.windowsWifiEnterpriseEAPConfiguration",
            "microsoft.graph.windows81TrustedRootCertificate",
            "microsoft.graph.windowsUpdateForBusinessConfiguration",
            "microsoft.graph.windows81SCEPCertificateProfile",
            "microsoft.graph.windowsDeliveryOptimizationConfiguration",
            "microsoft.graph.windowsKioskConfiguration",
            "microsoft.graph.editionUpgradeConfiguration",
            "microsoft.graph.windowsHealthMonitoringConfiguration",
            "microsoft.graph.sharedPCConfiguration",
            "windows10"
        )

        $iOS = @(
            "microsoft.graph.iosUpdateConfiguration",
            "microsoft.graph.iosGeneralDeviceConfiguration",
            "microsoft.graph.iosTrustedRootCertificate",
            "microsoft.graph.iosScepCertificateProfile",
            "microsoft.graph.iosEnterpriseWiFiConfiguration",
            "microsoft.graph.iosEasEmailProfileConfiguration",
            "iOS"
        )
    }
    PROCESS {
        if ($AllProperties) {
            $URI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=100"
            $result = Invoke-MgGraphRequest -Uri $URI -Method GET | Select-Object -ExpandProperty Value
            $configlist.AddRange($result)

            $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$count=true&`$top=100" #displayName, #@odata.type
            $result = Invoke-MgGraphRequest -Uri $URI2 -Method GET | Select-Object -ExpandProperty Value
            $configlist.AddRange($result)
            
        }
        else {
            $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$count=true&`$top=100" #displayName, #@odata.type
            $result2 = Invoke-MgGraphRequest -Uri $URI2 -Method GET | Select-Object -ExpandProperty Value
            foreach ($item in $result2) {
                $configlist += [PSCustomObject]@{
                    Name            = $item.displayName
                    Id              = $item.id
                    CreatedDateTime = $item.createdDateTime
                    LastModified    = $item.lastModifiedDateTime
                    Platform        = $item."@odata.type"
                }
            }
            $URI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=100"
            $result = Invoke-MgGraphRequest -Uri $URI -Method GET | Select-Object -ExpandProperty Value
            foreach ($item in $result) {
                $configlist += [PSCustomObject]@{
                    Name            = $item.name
                    Id              = $item.id
                    CreatedDateTime = $item.createdDateTime
                    LastModified    = $item.lastModifiedDateTime
                    Platform        = $item.platforms
                }
            }
        }
    }
    END {
        if ($All) {
            $configlist
        }
        if ($Platform -eq "Windows") {
            $configlist | Where-Object { $_.platforms -in $Windows -or $_.("@odata.type") -in $Windows }
        }
        if ($Platform -eq "macOS") {
            $configlist | Where-Object { $_.platforms -in $macOS -or $_.("@odata.type") -in $macOS }
        }
        if ($Platform -eq "iOS") {
            $configlist | Where-Object { $_.platforms -in $iOS -or $_.("@odata.type") -in $iOS }
        }
        if ($Platform -eq "Android") {
            $configlist | Where-Object { $_.platforms -in $Android -or $_.("@odata.type") -in $Android }
        }
    }
}
