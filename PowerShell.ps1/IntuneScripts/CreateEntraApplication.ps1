function New-EntraApplication {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DisplayName
    )

    #Create Application
    $app = new-MgApplication -DisplayName "IntuneCD"

    #Create service principal
    $svcPrincipal = New-MgServicePrincipal -AppID $app.Id

    Write-Output $app
    Write-Output $svcPrincipal
}