$scriptPath = 'C:\users\undukwe\source\repos\myscripts\PowerShell Modules\Scripts'
$modulePath = 'C:\users\undukwe\source\repos\myscripts\PowerShell Modules\Module\EndpointManagementTools\EndpointManagementTools.psm1'

Get-ChildItem $scriptPath -Filter *.ps1 | Get-Content | Add-Content -Path $modulePath