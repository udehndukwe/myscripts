$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$AutoAdminLogon = Get-ItemProperty -Path $RegPath -Name AutoAdminLogon
$DefaultUserName = Get-ItemProperty -name DefaultUserName -Path $regpath 
$isConnectedAutoLogon = Get-ItemProperty -name isConnectedAutoLogon $RegPath 


$Name = $DefaultUserName.DefaultUserName
$IsConnectedvalue = $isConnectedAutoLogon.isConnectedAutoLogon
$AutoAdminValue = $AutoAdminLogon.AutoAdminLogon

if ($AutoAdminValue -eq 1 -and $Name -eq "kioskUser0" -and $IsConnectedvalue -eq '0') {
    Write-Output "AutoLogon configured properly on this Kiosk machine."
}