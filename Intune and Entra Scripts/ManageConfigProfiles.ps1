function Get-IntuneDeviceConfig {
    $body = Get-Content -Path "batchPayload.json" -Raw

    $response = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/`$batch" -Body $body
    $values = $response.responses.body.value

    # Sorting hash table

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

    $values = foreach ($value in $values) {
        if ($value.Name) {
            $Name = $value.Name
        }
        else {
            $Name = $value.DisplayName
        }

        if ($value.platforms) {
            $Platform = $value.platforms
        }
        else {
            $Platform = switch -Wildcard ($value["@odata.type"]) {
                "*android*" { "Android" }
                "*macOS*" { "macOS" }
                "*windows*" { "windows10" }
                "*iOS*" { "iOS" }
                default { "windows10" }
            }
        }

        [PSCustomObject]@{
            Name                 = $Name
            Id                   = $value.Id
            LastModifiedDateTime = $value.LastModifiedDateTime
            Platform             = $Platform
            DataType             = $value."@odata.type"
        }
    }

    $values
}

############### Update Config Profiles ######################

$values = Get-IntuneDeviceConfig

foreach ($value in $values) {
    foreach ($URI in $URIS) { 
        $ConfigID = "$($value.Id)"
        $URI = $URI.replace("`$metadata`#", "") + "('$($ConfigID)')"
        switch ($value.Platform) {
            "windows10" {
                $displayName = $value.Name -replace '^(?:CFG - )?(?:CFG - )?windows10 - (.+)$', 'CFG - windows10 - $1'
            }
            "macOS" {
                $displayName = $value.Name -replace '^(?:CFG - )?(?:CFG - )?macOS - (.+)$', 'CFG - macOS - $1'
            }
            "Android" {
                $displayName = $value.Name -replace '^(?:CFG - )?(?:CFG - )?Android - (.+)$', 'CFG - Android - $1'
            }
            "iOS" {
                $displayName = $value.Name -replace '^(?:CFG - )?(?:CFG - )?iOS - (.+)$', 'CFG - iOS - $1'
            }
            default {
                $displayName = $value.Name
            }
        }
        $body = @{
            "name"        = $displayName
            "displayName" = $displayName
        } | ConvertTo-Json -Depth 10

        Invoke-MgGraphREquest -Method PATCH -Uri $URI -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue


    }
}