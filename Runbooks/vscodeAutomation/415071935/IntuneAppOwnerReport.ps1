#Set Teams Webhook URI

$URI = 'https://prod-25.westus.logic.azure.com:443/workflows/86e5bd316cf84a289242b20a5836e175/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=caRx4nAlSwRpCspGDPprYBxmDO_HH48uRK5N_BEFZpQ'

#Set App endpoint URI
$appEndpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=(microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true)"

$apps = Invoke-MgGraphRequest -Method GET $appEndpoint | Select-Object -expand value | Select-Object Displayname, Id, Owner

$appList = New-Object System.Collections.Generic.List[System.String]
foreach ($app in $apps) {
    $appList.Add($app.displayName)
}

$json = @"
    {
        "type": "message",
        "attachments": [
            {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "contentUrl": null,
            "content": {
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.2",
                "body": [
                {
                    "type": "TextBlock",
                    "text": "$($appList -join '\n\n' )"
                },
                {
                    "type": "TextBlock",
                    "title": "Intune Apps without an owner"
                }
                ]
            }
            }
        ]
        }
"@

Invoke-RestMethod -Method POST -Uri $URI -ContentType application/json -Body $json






Invoke-MgGraphRequest -Method GET $appEndpoint | Select-Object -expand value | Select Displayname, appAvailability, Id, Owner