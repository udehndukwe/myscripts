$regpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\"
$visioPath = (Get-ChildItem $regpath | Where-Object Name -like *VisioProRetail*).Name.Replace("HKEY_LOCAL_MACHINE", "HKLM:")

if ( (Get-ChildItem $regpath | Where-Object Name -like *VisioProRetail*) -and ( (get-ItemPropertyValue $visioPath -Name InstallLocation) -eq "C:\Program Files (x86)\Microsoft Office") ) {
   Write-Output "Visio Retail x86 Detected"
   exit 0
} else {
   Write-Output "Visio Retail x86 not detected"
   exit 1
}
