$adapter = Get-NetAdapter

$WiFiAdapter = $adapter | Where { $_.InterfaceName -like "*wireless_32768*" -and $_.Status -eq "Up" }
$BridgedAdapter = $adapter | Where { $_.Name -eq "Network Bridge" -and $_.Status -eq "Up" }

if ($WiFiAdapter -and $BridgedAdapter) {
    Write-Host "Wi-Fi adapter is connected and bridged"
    exit 1
}
else {
    Write-Output "Wi-Fi adapter is not connected or not bridged"
    exit 0
}