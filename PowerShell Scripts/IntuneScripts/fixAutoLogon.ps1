$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -name AutoAdminLogon -Path $regpath -Value 1
Set-ItemProperty -name DefaultUserName -Path $regpath -Value kioskUser0
Set-ItemProperty -name isConnectedAutoLogon $RegPath -Value 0


