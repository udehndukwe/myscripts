$DisplayName = "IntuneBrew"

#Create Application
$app = new-MgApplication -DisplayName $DisplayName

#Create service principal
$svcPrincipal = New-MgServicePrincipal -AppID $app.AppId

Write-Output $app
Write-Output $svcPrincipal
