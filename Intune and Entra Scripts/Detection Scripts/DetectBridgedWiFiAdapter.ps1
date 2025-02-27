Start-Transcript C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DetectBridgedWiFiAdapter.log

$adapter = Get-NetAdapter

Write-Verbose "Getting WiFi Adapter.." -Verbose
$WiFiAdapter = $adapter | Where { $_.InterfaceName -like "*wireless_32768*" -and $_.Status -eq "Up" }
Write-Verbose "Getting Bridged Adapter.." -Verbose
$BridgedAdapter = $adapter | Where { $_.Name -eq "Network Bridge" -and $_.Status -eq "Up" }
Write-Verbose "Checking variable values..." -Verbose
if ($WiFiAdapter -and $BridgedAdapter) {
    Write-Host "Wi-Fi adapter is connected and bridged."
    Stop-Transcript
    exit 1
}
else {
    Write-Output "Wi-Fi adapter is not connected or not bridged."
    Stop-Transcript
    exit 0
}