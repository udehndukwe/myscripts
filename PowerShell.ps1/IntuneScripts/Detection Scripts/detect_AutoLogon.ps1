$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$AutoAdminLogon = Get-ItemProperty -Path $RegPath -Name AutoAdminLogon
$DefaultUserName = Get-ItemProperty -name DefaultUserName -Path $regpath 
$isConnectedAutoLogon = Get-ItemProperty -name isConnectedAutoLogon $RegPath 


$Name = $DefaultUserName.DefaultUserName
$IsConnectedvalue = $isConnectedAutoLogon.isConnectedAutoLogon
$AutoAdminValue = $AutoAdminLogon.AutoAdminLogon

if ($AutoAdminValue -ne 1 -and $Name -ne "kioskUser0" -and $IsConnectedvalue -ne '0') {
    Write-Output "Autologon reg keys not set properly"
    exit 0
}
else {
    exit 1
}