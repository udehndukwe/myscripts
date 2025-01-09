$Path = "C:\Program Files\WindowsApps\Microsoft.CompanyPortal_11.2.1002.0_x64__8wekyb3d8bbwe\CompanyPortal.exe"

$value = Test-Path $Path

if ($value -eq "True") {
    Write-Output "Company Portal exists"
    exit 1
} else {
    Write-Output "Company Portal does not exist"
    exit 0
}