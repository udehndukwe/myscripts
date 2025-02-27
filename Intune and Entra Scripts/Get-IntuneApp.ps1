function Get-UnassignedApps {
    ###Hashtables for grouping apps by platform

    $macOS = @(
        '#microsoft.graph.macOsVppApp',
        '#microsoft.graph.macOSLobApp',
        '#microsoft.graph.macOSPkgApp',
        '#microsoft.graph.macOSOfficeSuiteApp',
        '#microsoft.graph.macOSMicrosoftEdgeApp'
    )    
    $Android = @(
        '#microsoft.graph.managedAndroidStoreApp', 
        '#microsoft.graph.androidManagedStoreApp',
        '#microsoft.graph.androidLobApp',
        '#microsoft.graph.androidStoreApp'
    )
    $iOS_iPadOS = @(
        '#microsoft.graph.iosVppApp',
        '#microsoft.graph.iosLobApp',
        '#microsoft.graph.iosStoreApp'
    )
    $Win32 = @(
        '#microsoft.graph.win32LobApp',
        '#microsoft.graph.winGetApp', 
        '#microsoft.graph.windowsMobileMSI', 
        '#microsoft.graph.officeSuiteApp', 
        '#microsoft.graph.windowsWebApp', 
        '#microsoft.graph.windowsMicrosoftEdgeApp'
    )

    Write-Verbose -Message 'Getting unassigned apps' -Verbose
    $appEndpoint = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=(microsoft.graph.managedApp/appAvailability eq null)"
    $apps = Invoke-MgGraphRequest -Method GET $appEndpoint | Select-Object -expand Value | Select-Object displayName, Id, '@odata.type', isAssigned, Owner

    $object = foreach ($app in $apps) {
        switch ($app.'@odata.type') {
            { $_ -in $macOS } { $Platform = 'macOS'; break }
            { $_ -in $Android } { $Platform = 'Android'; break }
            { $_ -in $iOS_iPadOS } { $Platform = 'iOS/iPadOS'; break }
            { $_ -in $Win32 } { $Platform = 'Win32'; break }
            default { $Platform = 'Unknown' }
        }
        [PSCustomObject]@{
            'App Name' = $app.displayName
            'App ID'   = $app.Id
            'Platform' = $Platform
        }
    }

    $object
}

### Get Audit Log for App Creation

$URI = 'https://graph.microsoft.com/beta/deviceManagement/auditEvents?$top=50&$filter=activityDateTime%20gt%202025-02-09T22:08:52.073Z%20and%20activityDateTime%20le%202025-02-10T22:08:52.073Z&$orderby=activityDateTime%20desc'
$values = Invoke-MgGraphRequest -Method GET -Uri $URI | Select -expand Value | Where activityType -like "*MobileApp*" 

foreach ($value in $values) {
    ## Extract actor (person who made the app)
    $actor = $value.actor.userPrincipalName

    ## Query graph to get the user's displayName and the application's id
    $URI2 = "https://graph.microsoft.com/v1.0/users/$($actor)"
    $displayName = Invoke-MgGraphRequest -Method GET -Uri $URI2 | Select -expand DisplayName

    $appID = $value.resources.resourceId

    ## Get app to extract @odata.type
    $URI3 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($appID)"
    $app = Invoke-MgGraphRequest -Method GET -Uri $URI3
    $dataType = $app."@odata.type"

    ## Set owner for application
    $body = @{
        "@odata.type" = $dataType
        "owner" = $displayName
    }
    $URI4 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($appID)"
    Invoke-MgGraphRequest -Method PATCH -Uri $URI4 -body $body
}
