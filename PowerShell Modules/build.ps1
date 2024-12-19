$scriptPath = 'C:\users\undukwe\source\repos\myscripts\PowerShell Modules\Scripts'
$modulePath = 'C:\Users\undukwe\source\repos\myscripts\PowerShell Modules\Modules\EndpointManagementTools\1.3\EndpointManagementTools.psm1'

Get-ChildItem $scriptPath -Filter *.ps1 | Get-Content | Out-File $modulePath -Force