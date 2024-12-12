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
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
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
