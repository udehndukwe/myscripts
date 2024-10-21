function Get-IntuneAppAssignments {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object[]]$Apps
    )
    PROCESS {
        $obj = foreach ($app in $apps) {
            $assignment = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.id
            foreach ($assign in $assignment) {
                $GroupID = $assign.Id -replace "_.*", ""
                try {
                    $group = Get-MgGroup -groupId $GroupID -ErrorAction Stop
                    $name = $group.DisplayName
                }
                catch {
                    if ($GroupID -eq 'acacacac-9df4-4c7d-9d50-4ef0226f57a9') {
                        $name = "All users"
                        $GroupID = "N/A"
                    }
                    elseif ($GroupID -eq 'adadadad-808e-44e2-905a-0b7873a8a531') {
                        $name = "All devices"
                        $GroupID = "N/A"
                    }
                }
    
                [PSCustomObject]@{
                    AppName         = $app.displayName
                    GroupAssignment = $Name
                    GroupID         = $GroupID
                    Intent          = $assign.Intent
                    AppID           = $app.id
                    AppAssignmentId = $assign.Id
            
                }
            } 
        }
    }
    END {
        Write-Output $obj
    }
}
$obj
#Remove any available assignments to Test - UdehNdukwe
<#Steps:
1. Get apps via Get-IntuneApps function
2. Filter that list down to what you actually want to modify
3. Get Assignments and generate your object 
#>
$Array = @(
    "Crowdstrike (with post-script)"
)

foreach ($app in $obj) {
    #if ($app.AppName -in $Array) {
    Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.AppID -MobileAppAssignmentId $app.AppAssignmentId
    #}
}

#Remove any required assignments to "Test - Mac Devices"

$changeList = $obj | Where-Object GroupAssignment -eq "Test - Mac Devices"

$array = @(
    "Crowdstrike (with post-script)",
    "Microsoft 365 Apps for macOS",
    "Microsoft Edge for macOS",
    "TeamViewer Host 15.33.3"
)

foreach ($app in $changeList) {
    if ($app.AppName -in $Array) {
        $name = $app.AppName
        Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.AppID -MobileAppAssignmentId $app.AppAssignmentId
        Write-Verbose -Message "Removing assignment for $Name" -Verbose
    }
}

#Add new assignment. Required for "Test - UdehNdukwe"

$array = @(
    "Crowdstrike (with post-script)",
    "Microsoft 365 Apps for macOS",
    "Microsoft Edge for macOS",
    "TeamViewer Host 15.33.3"
)


$appsToAssign = foreach ($app in $array) {
    $macApps | Where DisplayName -eq $app
}



foreach ($app in $appsToAssign) {
    New-IntuneAppAssignment -AppID $app.id -GroupName "ADE macOS Devices" -Intent "required"
}


$URI2 = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=100" #name, $platforms
$configlist2 = Invoke-MgGraphRequest -Uri $URI -Method GET | Select -expand Value  | Select displayName

$URI = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$count=true&`$top=100" #displayName, #@odata.type
$result3 = Invoke-MgGraphRequest -Uri $URI -Method GET






$macOSPolicies = @()

$macOSCustomPolicy = $result | select -ExpandProperty Value | Where DisplayName -like "*macOS*"
$macOSSettingsCatalog = $result2 | select -ExpandProperty Value | Where Name -like "*macOS*"
$macOSDeviceFeatureSettings = $result3 | select -ExpandProperty Value | Where displayName -like "*macOS*"

$macOSCustomPolicy | Select-Object displayName
$macOSSettingsCatalog | Select-Object name

$list = @()
$list += foreach ($policy in $macOSCustomPolicy) {
    [PSCustomObject]@{
        Name = $policy.DisplayName
        ID   = $policy.Id
    }
}

$list += foreach ($policy in $macOSSettingsCatalog) {
    [PSCustomObject]@{
        Name = $policy.name
        ID   = $policy.Id
    }
}

$list += foreach ($policy in $macOSDeviceFeatureSettings) {
    [PSCustomObject]@{
        Name = $policy.displayName
        ID   = $policy.Id
    }
}

$deviceConfigurationId = "31547331-99ad-4617-a89a-52ad3634b488"
$params = @{
    Target = @{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        collectionId  = "210ffd8a-e711-4e0f-8445-d9b91f0d39d7"
    }
}

New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $deviceConfigurationId -BodyParameter $params




foreach ($app in $apps) {
    if (-not $app.owner) {
        "App lacks an owner"
        "Email "
    }
}