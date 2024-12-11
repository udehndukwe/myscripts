function New-ExtensionAttribute {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceID,

        [Parameter(Mandatory = $true)]
        [string]$ExtensionAttribute,

        [Parameter(Mandatory = $true)]
        [string]$ExtensionAttributeValue,

        [Parameter]
        [string]$ClearAll
    )

    $URI = "https://graph.microsoft.com/v1.0/devices/$DeviceID"

    if ($ClearAll) {
        $ClearURI = "https://graph.microsoft.com/v1.0/devices/$($DeviceID)"
        $body = @{
            extensionAttributes = @{}
        }
        Invoke-MgGraphRequest -Method PATCH -Uri $ClearURI
    }

    try {
        $device = Invoke-MgGraphRequest -Method GET -Uri $URI -ErrorAction Stop

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
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        Write-Verbose "Finished processing New-ExtensionAttribute function." -Verbose
    }
}
