Start-Transcript C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GetUpdates.log

$module = get-module PSWindowsUpdate -ListAvailable

if (-not $module) {
    Write-Output "WindowsUpdate module not found."
	Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers -AcceptLicense
}

$WUHistory = Get-WUHistory

$WUHistory | Select ComputerName, Title, Date, Result | Sort Title | Out-File C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdate.log


Stop-Transcript
