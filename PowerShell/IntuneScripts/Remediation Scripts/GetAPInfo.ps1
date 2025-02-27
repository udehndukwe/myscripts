<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Takes code from the Get-WindowsAutopilotInfo.ps1 script to create a script that can either be deployed as a remediation in Intune, or packaged as a Win32 App to automate the process that the Get-WindowsAutopilotInfo script runs with the -Online parameter.

Uses an app registration in Entra to connect to Graph and upload Autopilot device information. Configure your app and retrieve your Tenant ID, App/Client ID, and your App Secret before attempting to run this script.


Original script: https://www.powershellgallery.com/packages/Get-WindowsAutopilotInfo/3.8

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

Start-Transcript C:\GetAPInfo.log

$packageProviders = Get-PackageProvider | select name

if (!($packageProviders.name -contains "nuget")) {
    Write-Host "NuGet not Found. Installing Package Provider"
    Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.208 -Force -Scope CurrentUser
}
else { Write-Host "NuGet Module Found" }

#Set Variables

$AppId = 
$TenantID =
$AppSecret =

# Get WindowsAutopilotIntune module (and dependencies)
$module = Import-Module WindowsAutopilotIntune -PassThru -ErrorAction Ignore
if (-not $module) {
    Write-Host "Installing module WindowsAutopilotIntune"
    Install-Module WindowsAutopilotIntune -Force
}
Import-Module WindowsAutopilotIntune -Scope Global

$graph = Connect-MSGraphApp -Tenant $TenantId -AppId $AppId -AppSecret $AppSecret
Write-Host "Connected to Intune tenant $TenantId using app-based authentication (Azure AD authentication not supported)"

# Get PC Info
$Name = "localhost"

$computers = @()

foreach ($comp in $Name) {
    $bad = $false

    # Get a CIM session
    if ($comp -eq "localhost") {
        $session = New-CimSession
    }
    else {
        $session = New-CimSession -ComputerName $comp -Credential $Credential
    }

    # Get the common properties.
    Write-Verbose "Checking $comp"
    $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber

    # Get the hash (if available)
    $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
    if ($devDetail -and (-not $Force)) {
        $hash = $devDetail.DeviceHardwareData
    }
    else {
        $bad = $true
        $hash = ""
    }

    # If the hash isn't available, get the make and model
    if ($bad -or $Force) {
        $cs = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem
        $make = $cs.Manufacturer.Trim()
        $model = $cs.Model.Trim()
        if ($Partner) {
            $bad = $false
        }
    }
    else {
        $make = ""
        $model = ""
    }

    # Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
    $product = ""

    # Depending on the format requested, create the necessary object
    if ($Partner) {
        # Create a pipeline object
        $c = New-Object psobject -Property @{
            "Device Serial Number" = $serial
            "Windows Product ID"   = $product
            "Hardware Hash"        = $hash
            "Manufacturer name"    = $make
            "Device model"         = $model
        }
        # From spec:
        #	"Manufacturer Name" = $make
        #	"Device Name" = $model

    }
    else {
        # Create a pipeline object
        $c = New-Object psobject -Property @{
            "Device Serial Number" = $serial
            "Windows Product ID"   = $product
            "Hardware Hash"        = $hash
        }
			
        if ($GroupTag -ne "") {
            Add-Member -InputObject $c -NotePropertyName "Group Tag" -NotePropertyValue $GroupTag
        }
        if ($AssignedUser -ne "") {
            Add-Member -InputObject $c -NotePropertyName "Assigned User" -NotePropertyValue $AssignedUser
        }
    }

    # Write the object to the pipeline or array
    if ($bad) {
        # Report an error when the hash isn't available
        Write-Error -Message "Unable to retrieve device hardware data (hash) from computer $comp" -Category DeviceError
    }
    elseif ($OutputFile -eq "") {
        $c
    }
    else {
        $computers += $c
        Write-Host "Gathered details for device with serial number: $serial"
    }

    Remove-CimSession $session
}

# Add the devices
$importStart = Get-Date
$imported = @()
$computers | % {
    $imported += Add-AutopilotImportedDevice -serialNumber $_.'Device Serial Number' -hardwareIdentifier $_.'Hardware Hash' -groupTag $_.'Group Tag' -assignedUser $_.'Assigned User'
}

# Wait until the devices have been imported
$processingCount = 1
while ($processingCount -gt 0) {
    $current = @()
    $processingCount = 0
    $imported | % {
        $device = Get-AutopilotImportedDevice -id $_.id
        if ($device.state.deviceImportStatus -eq "unknown") {
            $processingCount = $processingCount + 1
        }
        $current += $device
    }
    $deviceCount = $imported.Length
    Write-Host "Waiting for $processingCount of $deviceCount to be imported"
    if ($processingCount -gt 0) {
        Start-Sleep 30
    }
}
$importDuration = (Get-Date) - $importStart
$importSeconds = [Math]::Ceiling($importDuration.TotalSeconds)
$successCount = 0
$current | % {
    Write-Host "$($device.serialNumber): $($device.state.deviceImportStatus) $($device.state.deviceErrorCode) $($device.state.deviceErrorName)"
    if ($device.state.deviceImportStatus -eq "complete") {
        $successCount = $successCount + 1
    }
}
Write-Host "$successCount devices imported successfully.  Elapsed time to complete import: $importSeconds seconds"
		
# Wait until the devices can be found in Intune (should sync automatically)
$syncStart = Get-Date
$processingCount = 1
while ($processingCount -gt 0) {
    $autopilotDevices = @()
    $processingCount = 0
    $current | % {
        if ($device.state.deviceImportStatus -eq "complete") {
            $device = Get-AutopilotDevice -id $_.state.deviceRegistrationId
            if (-not $device) {
                $processingCount = $processingCount + 1
            }
            $autopilotDevices += $device
        }	
    }
    $deviceCount = $autopilotDevices.Length
    Write-Host "Waiting for $processingCount of $deviceCount to be synced"
    if ($processingCount -gt 0) {
        Start-Sleep 30
    }
}
$syncDuration = (Get-Date) - $syncStart
$syncSeconds = [Math]::Ceiling($syncDuration.TotalSeconds)
Write-Host "All devices synced.  Elapsed time to complete sync: $syncSeconds seconds"

$completeNotification = "This device has been registered to Autopilot successfuly"

Out-File C:\IntuneScriptLogs\complete.txt

$completeNotification >> C:\IntuneScriptLogs\complete.txt

Stop-Transcript



