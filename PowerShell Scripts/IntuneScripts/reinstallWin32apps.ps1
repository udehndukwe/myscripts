$path = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\"
Remove-Item -Path "$path\b400d43b-687e-4adc-8c21-2d2dac338aa1" -Recurse -Force
Restart-Service IntuneManagementExtension
rmdir C:\programdata\Debloat -Recurse -Force
