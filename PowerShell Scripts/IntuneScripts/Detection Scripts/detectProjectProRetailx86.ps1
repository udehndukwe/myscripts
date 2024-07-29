$regpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\"
$projectPath = (Get-ChildItem $regpath | Where-Object Name -like *ProjectProRetail*).Name.Replace("HKEY_LOCAL_MACHINE", "HKLM:")

if ( (Get-ChildItem $regpath | Where-Object Name -like *ProjectProRetail*) -and ( (get-ItemPropertyValue $projectPath -Name InstallLocation) -eq "C:\Program Files (x86)\Microsoft Office") ) {
   Write-Output "Project Retail x86 Detected"
   exit 0
} else {
   Write-Output "Proect Retail x86 not detected"
   exit 1
}
