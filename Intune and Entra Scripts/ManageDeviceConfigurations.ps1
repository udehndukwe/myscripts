$deviceConfigurationsUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
$groupPolicyConfigurationsUrl = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations"
$configurationPoliciesUrl = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
$hardwareConfigurationsUrl = "https://graph.microsoft.com/beta/deviceManagement/hardwareConfigurations"

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

function Get-IntuneDeviceConfigurations {
    ###Get device configurations
    $deviceConfigurationResults = Invoke-MgGraphRequest -Method GET -Uri $deviceConfigurationsUrl | Select -expand Value
    $deviceConfigurationValues = foreach ($value in $deviceConfigurationResults) {
        $Name = $value.DisplayName
        $Platform = switch -Wildcard ($value["@odata.type"]) {
            "*android*" { "Android" }
            "*macOS*" { "macOS" }
            "*windows*" { "windows10" }
            "*iOS*" { "iOS" }
            default { "windows10" }
        }
        [PSCustomObject]@{
            Name                 = $Name
            Id                   = $value.Id
            LastModifiedDateTime = $value.LastModifiedDateTime
            Platform             = $Platform
            DataType             = $value."@odata.type"
        }
    }

    $deviceConfigurationValues

}

# Update configurations
function Update-IntuneDeviceConfigurations {
    foreach ($value in $deviceConfigurationValues) {
        $configid = $value.Id
        switch ($value.Platform) {
            "windows10" {
                $string = $value.Name -replace '^(?:CFG - )?(?:Windows|Win10)\s*-\s*', ''
                $displayName = "CFG - Win10 - $string"
            }
            "macOS" {
                $string = $value.Name -replace '^(?:CFG - )?(?:macOS|macOS)\s*-\s*', ''
                $displayName = "CFG - macOS - $string"
            }
            "Android" {
                $string = $value.Name -replace '^(?:CFG - )?(?:Android|Android)\s*-\s*', ''
                $displayName = "CFG - Android - $string"
            }
            "iOS" {
                $string = $value.Name -replace '^(?:CFG - )?(?:iOS|iOS)\s*-\s*', ''
                $displayName = "CFG - iOS - $string"
            }
            default {
                $displayName = $value.Name
            }
        }

        $body = @{
            "displayName" = $DisplayName
            "@odata.type" = $value.DataType
        }

        try {
            Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$configid" -Body $body -ContentType "application/json" -ErrorAction Stop
            Write-Output "Successfully updated profile: $DisplayName"
        }
        catch {
            Write-Output "Failed to update profile: $DisplayName"

        }

    }

}


# Manage group policy configurations
$groupPolicyResults = Invoke-MgGraphRequest -Method GET -Uri $groupPolicyConfigurationsUrl | Select -expand Value
$groupPolicyValues = foreach ($value in $groupPolicyResults) {
    $Name = $value.DisplayName
    
    [PSCustomObject]@{
        Name                 = $Name
        Id                   = $value.Id
        LastModifiedDateTime = $value.LastModifiedDateTime
        Platform             = "windows10"
        "dataType"           = $value."@odata.type"
    }
}

# Update group policy configurations
foreach ($value in $groupPolicyValues) {
    switch ($value.Platform) {
        "windows10" {
            $string = $value.Name -replace '^(?:CFG - )?(?:Windows|Win10)\s*-\s*', ''
            $displayName = "CFG - Win10 - $string"
        }
        "macOS" {
            $string = $value.Name -replace '^(?:macOS\s*-\s*)?', ''
            $displayName = "CFG - macOS - $string"
        }
        "Android" {
            $string = $value.Name -replace '^(?:Android\s*-\s*)?', ''
            $displayName = "CFG - Android - $string"
        }
        "iOS" {
            $string = $value.Name -replace '^(?:iOS\s*-\s*)?', ''
            $displayName = "CFG - iOS - $string"
        }
        default {
            $displayName = $value.Name
        }
    }

    $body = @{
        "id"          = $value.Id
        "displayName" = $DisplayName
        "@odata.type" = $value.dataType
    }

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations/$configid" -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-Output "Successfully updated profile: $DisplayName"
    }
    catch {
        Write-Output "Failed to update profile: $DisplayName"

    }

}

#####Manage configuration policies
$configurationPolicyResults = Invoke-MgGraphRequest -Method GET -Uri $configurationPoliciesUrl | Select -expand Value
$configurationPolicyValues = foreach ($value in $configurationPolicyResults) {
    $Name = $value.Name
    $Platform = $value.platforms
    [PSCustomObject]@{
        Name                 = $Name
        Id                   = $value.Id
        LastModifiedDateTime = $value.LastModifiedDateTime
        Platform             = $Platform
    }
}


# Update configuration policies
foreach ($value in $configurationPolicyValues) {
    switch ($value.Platform) {
        "windows10" {
            $string = $value.Name -replace '^(?:CFG - )?(?:Windows|Win10)\s*-\s*', ''
            $displayName = "CFG - Win10 - $string"
        }
        "macOS" {
            $string = $value.Name -replace '^(?:CFG - )?(?:macOS|macOS)\s*-\s*', ''
            $displayName = "CFG - macOS - $string"
        }
        "Android" {
            $string = $value.Name -replace '^(?:Android\s*-\s*)?', ''
            $displayName = "CFG - Android - $string"
        }
        "iOS" {
            $string = $value.Name -replace '^(?:iOS\s*-\s*)?', ''
            $displayName = "CFG - iOS - $string"
        }
        default {
            $displayName = $value.Name
        }
    }

    $body = @{
        "name" = $DisplayName
    } | ConvertTo-Json -Depth 10

    $URI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies('$configid')"

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri $URI -Body $body -ContentType "application/json" -ErrorAction Stop -Headers $headers
        Write-Output "Successfully updated profile: $DisplayName"
    }
    catch {
        Write-Output "Failed to update profile: $DisplayName"

    }

}

# Manage hardware configurations
$hardwareConfigurationResults = Invoke-MgGraphRequest -Method GET -Uri $hardwareConfigurationsUrl | Select -expand Value
$hardwareConfigurationValues = foreach ($value in $hardwareConfigurationResults) {
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
