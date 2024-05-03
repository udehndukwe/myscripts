#Connect to MS Graph, MSIntuneGraph application, and Azure

if ($null -eq (Get-MgContext)) {
    Connect-MgGraph -Scopes DeviceManagementApps.Read.All
    Connect-MSIntuneGraph -TenantID (Get-MgContext).TenantId
}

if ($null -eq (Get-AzContext)) {
    Connect-AzAccount
}

$displayName = Read-Host -Prompt "Enter display name of app from Intune"
 
#Get the Id of the app you are looking for
$mobileAppId = (Get-IntuneWin32App -DisplayName $displayName).Id

#Get access token for Graph API call, set URI endpoint and headers
$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
$uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

invoke-RestMethod -Method Get -headers $headers -Uri $uri