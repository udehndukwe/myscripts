$Value = Get-ChildItem -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdate.log

if ($value) {
    Write-Output "Update log file found"
    exit 0
} else {
    Write-Output "Update log file not found"
    exit 1
}