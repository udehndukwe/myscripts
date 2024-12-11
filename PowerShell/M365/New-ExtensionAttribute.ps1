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
            $filteredDevice.extensionAttributes.GetEnumerator() | Where-Object { $_.Value -ne $null } | ForEach-Object { @{ $_.Key = $_.Value } }
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
                $filteredDevice.extensionAttributes.GetEnumerator() | Where-Object { $_.Value -ne $null } | ForEach-Object { @{ $_.Key = $_.Value } }
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
