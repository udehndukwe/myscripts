function Restart-IntuneDevice {
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
        Write-Verbose "Sending restart command..." 
        Restart-MgDeviceManagementManagedDeviceNow -ManagedDeviceId $managedDeviceId 
        Start-Sleep -Seconds 5

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
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$DeviceName'"
        }
        elseif ($SerialNumber) {
            $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$SerialNumber'"
        }
        $params = @{
            keepEnrollmentData = $false
            keepUserData       = $false
        }
    }

    process {
        
        foreach ($device in $managedDevice) {
            $Name = $device.DeviceNAme
            Write-Verbose "Sending Wipe command..." 
            Clear-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id -BodyParameter $params -ErrorAction Stop -Confirm:$true
            Write-Verbose "Wipe initiated for $Name." 
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

function Set-APGroupTag {
    [CmdletBinding()]
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
        if (-not $apdevices) {
            $apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        }
    }

    PROCESS {
        $HashID = $apDevices.where({ $_.SerialNumber -eq "g8ypcb3" }).ID
        try {
            Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $HashID -GroupTag $GroupTag -erroraction Stop
            Write-Verbose -Message "Group Tag successfully updated. Allow 5-10 minutes for changes to reflect" 
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

function Clear-ApHash {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$Id
    )
    process {
        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
    }
}

function Remove-EntraDevice {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$AzureActiveDirectoryDeviceId,
        [string[]]$DisplayName,
        [string[]]$DeviceName
    )

    begin {
        if (-not $script:allDevices) {
            $script:allDevices = Get-MgDevice -Property Id, DeviceId, PhysicalIds, DisplayName -All
        }   
    }

    process {
        switch ($true) {
            { $AzureActiveDirectoryDeviceId } {
                $script:allDevices.Where({ $_.DeviceId -eq $AzureActiveDirectoryDeviceId })
            }
            { $DisplayName } {
                $script:allDevices.where({ $_.DisplayName -eq $DisplayName })
            }   
        }
    }
}


function Get-EntraDupe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('AzureActiveDirectoryDeviceID')]
        [string[]]$EntraDeviceID,
        [string[]]$hash
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

function Get-RemediationScript {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ParameterName
    )
    BEGIN {
        $URI = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
        $result = invoke-mgGraphRequest -Uri $URI | Select -ExpandProperty value

    }
    PROCESS {
        foreach ($x in $result) {
            [PSCustomObject]@{
                Name        = $x.displayName
                ID          = $x.id
                Publisher   = $x.publisher
                Description = $x.description
            }
        
        }
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
            $path = New-Item -Path $env:USERPROFILE\$foldername -ItemType Directory
            $detectionFilename = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "") + "Remediation.ps1"
            $remediationFileName = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "") + "_Detection.ps1"
            ##Export filename
            $decodedDetection | Out-File -FilePath "$env:USERPROFILE\$foldername\$detectionFilename"
            Write-Verbose -Message "$detectionFilename has been exported successfully" -Verbose
            
            $decodedRemediation | Out-File "$env:USERPROFILE\$foldername\$remediationFileName"
            Write-Verbose -Message "$remediationFileName has been exported successfully" -Verbose

        }
    }

}


function Get-LAPSCredential {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$SerialNumber,
        [string[]]$DeviceName
    )

    BEGIN {
        #Connect to Microsoft Graph
        Connect-Mggraph -Scope DeviceLocalCredential.Read.All, Device.Read.All

    }

    PROCESS {
        if ($DeviceName) {
            $managedDeviceId = (Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$DeviceName'").AzureAdDeviceId
        }
        elseif ($SerialNumber) {
            $managedDeviceId = (Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$SerialNumber'").AzureAdDeviceId 
        }
        #Generate a new correlation ID

        $correlationID = [System.Guid]::NewGuid()

        #Define the URI path
        $uri = 'beta/deviceLocalCredentials/' + $DeviceId
        $uri = $uri + '?$select=credentials'
    
        #Build the request header
        $headers = @{}
        $headers.Add('ocp-client-name', 'Get-LapsAADPassword Windows LAPS Cmdlet')
        $headers.Add('ocp-client-version', '1.0')
        $headers.Add('client-request-id', $correlationID)
    
        #Initation the request to Microsoft Graph for the LAPS password
        $Response = Invoke-MgGraphRequest -Method GET -Uri $URI -Headers $headers
    
        #Decode the LAPS password from Base64
        $passwordb64 = ($Response.credentials).PasswordBase64
        $passwordb64 | % { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }

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
        $device = Get-MgDevice -filter "DisplayName eq '$DeviceName'"
        $mgUser = Get-MgDeviceRegisteredOwner -DeviceId $device.id    
        Get-MgUser -userid $mguser.Id
    }
}

foreach ($device in $alldevices) {
    try {
        Get-AssignedEntraDevice -DeviceName $device.DisplayName
    }
    catch {
        Write-Error "No Registered User"
    }
}

function Export-M365LicensedUsers {
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

    switch ($license) {
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



    $allusers = Get-mgUser -All -Property Id, DisplayName, UserPrincipalName, AssignedLicenses

    $License = Get-MgSubscribedSku | WHere SkuPartNumber -eq $LicenseSkuPartNumber
    $SkuID = $license.skuid

    $licensedUsers = foreach ($user in $allusers) {
        $user.where({ $_.AssignedLicenses.SkuID -eq $SkuID })
    }
    [PSCustomObject]@{
        Name              = $licensedUsers.displayName
        UserPrincipalName = $licensedUsers.UserPrincipalName
        ID                = $licensedUsers.ID
        License           = $productName
    }

}

function Get-IntuneApps {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Platform,
        [switch]$All
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph -NoWelcome
        }

        $URI = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/"
        
        $value = Invoke-MgGraphRequest -Uri $URI -Method GET | Select -expand Value
        
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
            "macOS" { $value | Where "@odata.type" -in $macOS }
            "Windows" { $value | Where "@odata.type" -in $Win32 }
            "Android" { $value | Where "@odata.type" -in $Android }
            "iOS" { $value | Where "@odata.type" -in $iOS_iPadOS }
        }

        if ($All) {
            $value
        }   
            
        
    }
}

<#
.SYNOPSIS
    Assigns an Intune mobile app to a specified group with a given intent.

.DESCRIPTION
    This function assigns a mobile app in Microsoft Intune to a specified group using the Microsoft Graph API. 
    It requires the group name, assignment intent, and app ID as parameters.

.PARAMETER GroupName
    The display name of the group to which the app will be assigned.

.PARAMETER Intent
    The assignment intent for the app. Possible values include 'available', 'required', 'uninstall', etc.

.PARAMETER AppID
    The ID of the mobile app to be assigned.

.EXAMPLE
    New-IntuneAppAssignment -GroupName "Sales Team" -Intent "required" -AppID "12345"

.NOTES
    Ensure you have the necessary permissions to access Microsoft Graph API and manage Intune app assignments.
    This function uses the Microsoft Graph PowerShell SDK.

#>
function New-IntuneAppAssignment {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$GroupName,
        [string]$Intent,
        [string]$AppID
    )
    BEGIN {
        $group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"
        $target = @{
            "@odata.type" = "microsoft.graph.groupAssignmentTarget"    
            "groupId"     = $group.Id
        }
    }
    PROCESS {
        try {
            New-MgDeviceAppManagementMobileAppAssignment -MobileAppId $AppID -Intent $Intent -Target $target -ErrorAction Stop
        }
        catch {
            $_.Exception.Message
        }
    }
}

function Get-IntuneConfigProfiles {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Platform,
        [switch]$All
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
            "microsoft.graph.sharedPCConfiguration"
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

        $URI = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=100"
        $result = Invoke-MgGraphRequest -Uri $URI -Method GET | Select -expand Value
        $configlist += $result

        $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$count=true&`$top=100" #displayName, #@odata.type
        $result = Invoke-MgGraphRequest -Uri $URI2 -Method GET | Select -expand Value
        $configlist += $result
    }
    END {
        if ($All) {
            $configlist
        }
    
        if ($Platform -eq "Windows") {
            $configlist | Where { $_.platforms -in $Windows -or $_.("@odata.type") -in $Windows }
        }
        else {
            $configlist
        }
        #if ($macOS) {}
        #if ($iOS) {}
        #if ($Android) {}
    }
    
}

function Remove-Win32Hash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $appId
    )

   
    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | sort LastWriteTime -Descending | select -ExpandProperty FullName
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
                $Hash = Get-Content $intuneLog | Select-Object -Skip $LineNumber -First 1
                if ($hash) {
                    $hash = $hash.Replace("Hash = ", "")
                }
            }
        }
    }

    #Remove folder that matches hash name from registry
    remove-item -Recurse -Force -Path $regpath\$Hash

    Write-Verbose "Restarting IntuneManagementExtension service" -Verbose

    Restart-Service IntuneManagementExtension

}