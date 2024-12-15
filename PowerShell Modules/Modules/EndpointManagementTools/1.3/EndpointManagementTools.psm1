function Clear-ApHash {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Id
    )
    process {
        if ($PSCmdlet.ShouldProcess("Device with ID $Id", "Remove")) {
            Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
        }
    }
}
function Clear-IntuneDevice {
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
            $URI = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$DeviceName'"
            $managedDevice = Invoke-MgGraphRequest -Method GET -Uri $URI | Select -expand Value 
        }
        elseif ($SerialNumber) {
            $URI = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$SerialNumber'"
            $managedDevice = Invoke-MgGraphRequest -Method GET -Uri $URI | Select -expand Value 
        }
        $params = @{
            keepEnrollmentData = $false
            keepUserData       = $false
        }
    }

    process {
        
        foreach ($device in $managedDevice) {
            $Name = $device.DeviceNAme
            $URI = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/wipe" 
            Write-Verbose "Sending Wipe command..." -Verbose
            Invoke-MgGraphRequest -Method POST -Uri $URI -ErrorAction Stop -Confirm:$true
            Write-Verbose "Wipe initiated for $Name." -Verbose
        }
    }
}
function Export-M365LicensedUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LicenseSkuPartNumber
    )
    $licenseArray = @(
        "SPE_E5"
        "ENTERPRISEPACK"
        "SPE_F1"
        "DESKLESSPACK"
        "PROJECT_P1"
        "PROJECTPROFESSIONAL"
        "PROJECTPREMIUM"
        "VISIOCLIENT"
        "Microsoft_365_Copilot"
        "MCOMEETADV"
        "EMS"
        "MCOCAP"
        "MCOPSTN_5"
        "MCOEV"
        "EMSPREMIUM"
    )

    switch ($licenseArray) {
        "Microsoft_365_Copilot" {
            $productName = "Microsoft 365 Copilot"
        } "SPE_E5" {
            $productName = "Microsoft 365 E5"
        } "ENTERPRISEPACK" {
            $productName = "Office 365 E3"
        } "SPE_F1" {
            $productName = "Microsoft 365 F3"
        }"DESKLESSPACK" {
            $productName = "Office 365 F3"
        }"PROJECT_P1" {
            $productName = "Project Plan 1"
        }"PROJECTPROFESSIONAL" {
            $productName = "Project Plan 3"
        }"PROJECTPREMIUM" {
            $productName = "Project Plan 5"
        }"VISIOCLIENT" {
            $productName = "Visio Plan 2"
        } "MCOMEETADV" {
            $productName = "Microsoft 365 Audio Conferencing"
        } "EMS" {
            $productName = "Enterprise Mobility + Security E3"
        } "EMSPREMIUM" {
            $productName = "Enterprise Mobility + Security E5"
        } "MCOEV" {
            $productName = "Microsoft Teams Phone Standard"
        } "MCOCAP" {
            $productName = "Microsoft Teams Shared Devices"
        } "MCOPSTN_5" {
            $productName = "Microsoft Teams Domestic Calling Plan (120 min)"
        } 
    }

    $allusers = @()
    $uri = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,assignedLicenses&`$top=999"
    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        $allusers += $response.value
        $uri = $response.'@odata.nextLink'
    } while ($uri)

    $License = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq $LicenseSkuPartNumber
    $SkuID = $license.skuid

    $licensedUsers = foreach ($user in $allusers) {
        $user.Where({ $_.AssignedLicenses.SkuID -eq $SkuID })
    }
    [PSCustomObject]@{
        Name              = $licensedUsers.DisplayName
        UserPrincipalName = $licensedUsers.UserPrincipalName
        ID                = $licensedUsers.ID
        License           = $productName
    }

}
function Export-RemediationScript {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$scriptID
    )

    PROCESS {
        foreach ($id in $scriptID) {
            #SET URI
            $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/{$id}?$select=remediationScriptContent,detectionScriptContent"
            #Export detection Script
            $value = Invoke-MgGraphRequest -Uri $URI2 -Method GET
            ##Get script content (encoded)
            $detectionScriptContent = $value | Select-Object -expand detectionScriptContent
            $remediationScriptContent = $value | Select-Object -expand remediationScriptContent
            ##Decode script content
            $decodedDetection = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($detectionScriptContent))
            $decodedRemediation = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($remediationScriptContent))
            ##Set filename
            $foldername = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "")
            try {
                $path = New-Item -Path $env:USERPROFILE\$foldername -ItemType Directory -ErrorAction Stop
            }
            catch {
                $path = Get-Item $env:USERPROFILE\$foldername
            }
            $detectionFilename = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "") + "Remediation.ps1"
            $remediationFileName = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "") + "_Detection.ps1"
            ##Export filename
            $decodedDetection | Out-File -FilePath "$env:USERPROFILE\$foldername\$detectionFilename"
            Write-Verbose -Message "$detectionFilename has been exported successfully to: $($path)"
            
            $decodedRemediation | Out-File "$env:USERPROFILE\$foldername\$remediationFileName"
            Write-Verbose -Message "$remediationFileName has been exported successfully to: $($path)"

        }
    }

}
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
function Get-AssignedEntraDevice {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SerialNumber,
        [string]$DeviceName
    )

    if ($DeviceName) {
        $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=displayName eq '$DeviceName'"
        if ($device.value.Count -eq 0) {
            Write-Error "Device not found"
            return
        }
        $deviceId = $device.value[0].id
        $mgUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices/$deviceId/registeredOwners"
        if ($mgUser.value.Count -eq 0) {
            Write-Error "No Registered User"
            return
        }
        Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($mgUser.value[0].id)"
    }

    if ($SerialNumber) {
        $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$SerialNumber'"
        if ($device.value.Count -eq 0) {
            Write-Error "Device not found"
            return
        }
        $deviceId = $device.value[0].azureADDeviceId
        $mgDevice = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=DeviceID eq '$deviceId'"
        $ID = $mgDevice.value.id
        $mgUser = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices/$ID/registeredOwners"
        if ($mgUser.value.Count -eq 0) {
            Write-Error "No Registered User"
            return
        }
        Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($mgUser.value[0].id)"
    }
}
function Get-EntraDupe {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('AzureActiveDirectoryDeviceID')]
        [string[]]$EntraDeviceID
    )

    BEGIN {
        $alldevices = Get-MgDevice -All
        Set-Variable 'alldevices' -Value $alldevices -Scope Script

    }
    PROCESS {
        foreach ($id in $EntraDeviceID) {
            try {
                $mgDevice = Get-MgDevice -Filter "DeviceId eq '$id'" -ErrorAction Stop
            }
            catch {
                Write-Error "Invalid ID. Please see ID value and make necessary corrections: $id" -Category InvalidArgument 
                $message = "Entra Device associated with S/N: " + $hash.SerialNumber.ToString() + " not processed"
                Write-Verbose $message -Verbose
            }
        
            #Two if loops that check to see if a device was found and if a ZTDID was found. 
            if ($null -eq $mgDevice) {
                Write-Error "Variable is Null. No Entra device with ID: $id found"
            }
            else {
                #Get ZTDID of that device
                $ZTDID = $mgDevice.PhysicalIds | Select-String [ZTDID] -SimpleMatch
        
                if ($null -eq $ZTDID) {
                    Write-Error "Variable is Null. No ZTDID found for this device. Check to see if Autopilot hash still exists in Intune"
                }
                else {
                    #Find all devices in Entra that have the same ZTDID
                    $dupeDevices = $alldevices | Where-Object PhysicalIds -Contains $ZTDID
                }
            }



        }
        foreach ($device in $dupeDevices) {
            $obj = [PSCustomObject]@{
                ID            = $device.DeviceId
                EntraDeviceID = $device.Id
            }
            Write-Output $obj
        }
    }
}
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
function Get-IntuneAppStatusReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AppID,
        [switch]$Export,
        [switch]$Display,
        [string]$JSONPath = "$env:USERPROFILE\AppJSONs"
    )
    # Make temp dir
    $value = Test-Path $JSONPath
    if (-not $value) {
        New-Item -ItemType Directory -Path $JSONPath -ErrorAction SilentlyContinue
    }

    $MobileAppURI = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$AppID"
    $FileName = (Invoke-MgGraphRequest -Method GET -Uri $MobileAppURI | Select-Object -ExpandProperty DisplayName) -replace '[^a-zA-Z0-9]', '' # Replace with the actual application name

    $params = @{
        filter = "(ApplicationId eq '$AppID')"
    }
    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/getAppStatusOverviewReport"
    Invoke-MgGraphRequest -Method POST -Uri $URI -OutputFilePath "$JSONPath\$FileName.json" -Body $params
    # Define the application name variable
    $AppName = Invoke-MgGraphRequest -Method GET -Uri $MobileAppURI | Select-Object -ExpandProperty DisplayName # Replace with the actual application name

    # Read the JSON file
    $jsonContent = Get-Content -Path "$JSONPath\$FileName.json" -Raw | ConvertFrom-Json
    $jsonContent = $jsonContent.Values -split " " 
    # Extract the values from the JSON content
    $applicationId = $jsonContent[0]
    $failedDeviceCount = $jsonContent[1]
    $pendingInstallDeviceCount = $jsonContent[2]
    $installedDeviceCount = $jsonContent[3]
    $notInstalledDeviceCount = $jsonContent[4]
    $notApplicableDeviceCount = $jsonContent[5]

    # Create a custom object for the table
    $table = [PSCustomObject]@{
        AppName                   = $AppName
        ApplicationId             = $applicationId
        FailedDeviceCount         = $failedDeviceCount
        PendingInstallDeviceCount = $pendingInstallDeviceCount
        InstalledDeviceCount      = $installedDeviceCount
        NotInstalledDeviceCount   = $notInstalledDeviceCount
        NotApplicableDeviceCount  = $notApplicableDeviceCount
    }

    # Display the table
    $TableList = @($table)
    $Date = Get-Date -Format MM/dd/yyyy
    if ($Export) {
        $TableList | Export-Excel -Path .\AppStatusReport.xlsx -AutoSize -WorksheetName "AppInstallStatuses-$Date" -BoldTopRow -TableName "AppStatuses"
    }
    if ($Display) {
        return $TableList
    }

    # Clean temp directory
    Remove-Item -Path $JSONPath -Recurse -Force
}
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
        $configlist = @()

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
            $configlist += $result

            $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$count=true&`$top=100" #displayName, #@odata.type
            $result = Invoke-MgGraphRequest -Uri $URI2 -Method GET | Select-Object -ExpandProperty Value
            $configlist += $result
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
        if ($macOS) {
            $configlist | Where-Object { $_.platforms -in $macOS -or $_.("@odata.type") -in $macOS }
        }
        if ($iOS) {
            $configlist | Where-Object { $_.platforms -in $iOS -or $_.("@odata.type") -in $iOS }
        }
        if ($Android) {
            $configlist | Where-Object { $_.platforms -in $Android -or $_.("@odata.type") -in $Android }
        }
    }
}
<#
.SYNOPSIS
Creates or clears extension attributes for a specified device in Microsoft Graph.

.DESCRIPTION
The New-ExtensionAttribute function allows you to set or clear extension attributes for a specified device in Microsoft Graph. 
You can either set a specific extension attribute to a given value or clear all extension attributes for the device.

.PARAMETER DeviceID
The ID of the device for which the extension attribute is to be set or cleared.

.PARAMETER ExtensionAttribute
The name of the extension attribute to be set. This parameter is ignored if the ClearAll switch is used.

.PARAMETER ExtensionAttributeValue
The value to set for the specified extension attribute. This parameter is ignored if the ClearAll switch is used.

.PARAMETER ClearAll
A switch parameter that, when specified, clears all extension attributes for the device.

.EXAMPLE
PS C:\> New-ExtensionAttribute -DeviceID "12345" -ExtensionAttribute "ExtensionAttribute1" -ExtensionAttributeValue "Value1"
Sets the extension attribute "ExtensionAttribute1" to "Value1" for the device with ID "12345".

.EXAMPLE
PS C:\> New-ExtensionAttribute -DeviceID "12345" -ClearAll
Clears all extension attributes for the device with ID "12345".

.NOTES
This function requires the Microsoft Graph PowerShell SDK to be installed and authenticated.

#>
function New-ExtensionAttribute {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter()]
        [string]$DeviceID,
        [string]$ExtensionAttribute,
        [string]$ExtensionAttributeValue,
        [switch]$ClearAll
    )

    $URI = "https://graph.microsoft.com/v1.0/devices/$DeviceID"

    if ($ClearAll) {
        if ($PSCmdlet.ShouldProcess("Device $DeviceID", "Clear all extension attributes")) {
            $body = @{
                extensionAttributes = @{}
            }
            1..15 | ForEach-Object { $body.extensionAttributes["ExtensionAttribute$_"] = $null }
            Invoke-MgGraphRequest -Method PATCH -Uri $URI -Body $body -ErrorAction Stop

            $URI2 = "https://graph.microsoft.com/v1.0/devices/$($DeviceID)?`$select=extensionAttributes"
            $filteredDevice = Invoke-MgGraphRequest -Method GET -Uri $URI2 -ErrorAction Stop

            Write-Verbose "The following extensionAttributes are set on device: $($device.displayName)" -Verbose
            $filteredDevice.extensionAttributes.GetEnumerator() | Where-Object { $null -ne $_.Value } | ForEach-Object { @{ $_.Key = $_.Value } }
        }
    }
    else {
        try {
            $device = Invoke-MgGraphRequest -Method GET -Uri $URI -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess("Device $DeviceID", "Set $ExtensionAttribute to '$ExtensionAttributeValue'")) {
                $body = @{
                    extensionAttributes = @{}
                }
                $body.extensionAttributes.$ExtensionAttribute = $ExtensionAttributeValue

                Write-Verbose "Setting $ExtensionAttribute to '$ExtensionAttributeValue' for device: $($device.displayName)" -Verbose

                Invoke-MgGraphRequest -Method PATCH -Uri $URI -Body $body -ErrorAction Stop

                $URI2 = "https://graph.microsoft.com/v1.0/devices/$($DeviceID)?`$select=extensionAttributes"
                $filteredDevice = Invoke-MgGraphRequest -Method GET -Uri $URI2 -ErrorAction Stop

                Write-Verbose "The following extensionAttributes are set on device: $($device.displayName)" -Verbose
                $filteredDevice.extensionAttributes.GetEnumerator() | Where-Object { $null -ne $_.Value } | ForEach-Object { @{ $_.Key = $_.Value } }
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
        finally {
            Write-Verbose "Finished processing New-ExtensionAttribute function." -Verbose
        }
    }
}
function New-IntuneAppAssignment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        [ValidateSet("All users", "All devices")]
        [string]$GroupName,
        [ValidateSet("required", "available")]
        [string]$Intent,
        [string]$AppID
    )
    BEGIN {
        if ($GroupName -eq "All users") {
            $target = @{
                "@odata.type" = "microsoft.graph.groupAssignmentTarget"    
                "groupId"     = "acacacac-9df4-4c7d-9d50-4ef0226f57a9"
            }
        }
        elseif ($GroupName -eq "All devices") {
            $target = @{
                "@odata.type" = "microsoft.graph.groupAssignmentTarget"
                "groupId"     = "adadadad-808e-44e2-905a-0b7873a8a531"
            }
        }
        else {
            $group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"
            $target = @{
                "@odata.type" = "microsoft.graph.groupAssignmentTarget"    
                "groupId"     = $group.Id
            }
        }
    }
    PROCESS {
        if ($PSCmdlet.ShouldProcess("AppID: $AppID", "Assign app to group: $GroupName with intent: $Intent")) {
            try {
                New-MgDeviceAppManagementMobileAppAssignment -MobileAppId $AppID -Intent $Intent -Target $target -ErrorAction Stop
            }
            catch {
                $_.Exception.Message
            }
        }
    }
}
function Remove-Win32Hash {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $appId
    )

   
    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName
    $regpath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\b400d43b-687e-4adc-8c21-2d2dac338aa1\GRS\"
    if (!$intuneLogList) {
        Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\]\[GRSManager\] App with id: $appId is not expired." -Context 0, 1
        if ($appMatch) {
            foreach ($match in $appMatch) {
                $Hash = '“”'
                $LineNumber = 0
                $LineNumber = $match.LineNumber
                $Hash = Get-Content -Path $intuneLog | Select-Object -Skip $LineNumber -First 1
                if ($hash) {
                    $hash = $hash.Replace("Hash = ", "")
                }
            }
        }
    }

    if ($PSCmdlet.ShouldProcess("Registry path $regpath\$Hash", "Remove")) {
        #Remove folder that matches hash name from registry
        Remove-Item -Recurse -Force -Path $regpath\$Hash

        Write-Verbose "Restarting IntuneManagementExtension service" -Verbose

        Restart-Service -Name IntuneManagementExtension
    }
}
function Restart-IntuneDevice {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
            $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=displayName eq '$DeviceName'"
            $managedDeviceID = $device.value.id
        }
        elseif ($SerialNumber) {
            $device = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$SerialNumber'"
            $managedDeviceID = $device.value.id
        }
    }

    process {
        $Name = $device.value.deviceName
        if ($PSCmdlet.ShouldProcess("Device: $Name", "Restart")) {
            Write-Verbose "Sending restart command..." -Verbose

            $URI = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$managedDeviceID/rebootNow"
            Invoke-MgGraphRequest -Method POST -Uri $URI -ErrorAction Stop
        }
    }
}
function Set-APGroupTag {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$SerialNumber,
        [string]$GroupTag
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
        if (-not $apDevices) {
            $apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        }
    }

    PROCESS {
        $HashID = $apDevices.Where({ $_.SerialNumber -eq $SerialNumber }).ID
        if ($PSCmdlet.ShouldProcess("Device with Serial Number $SerialNumber", "Update Group Tag to $GroupTag")) {
            try {
                Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $HashID -GroupTag $GroupTag -ErrorAction Stop
                Write-Verbose -Message "Group Tag successfully updated. Allow 5-10 minutes for changes to reflect" 
            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }
}
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
