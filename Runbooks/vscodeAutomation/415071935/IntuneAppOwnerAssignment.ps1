##################################################################################################################################################################
# Runbook that pulls audit logs to find out who created an application Intune and assigns them as the owner of that application. Once assigned, an email is sent to the user to notify them of the assignment.

# Scopes required:
## DeviceManagementApps.ReadWrite.All
## User.Read.All
## Mail.Send

##################################################################################################################################################################




function Send-Mail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserID,
        [switch]$Application
    )
    if ($Application) {
        $UserID = 'endpoint.engineering@relrepairs.com'
        Invoke-MgGraphRequest -Method POST -Uri "v1.0/users/$($UserID)/sendMail" -Body $params
    }
    else {
        $UserID = 'udeh.ndukwe@relrepairs.com'
        Invoke-MgGraphRequest -Method POST -Uri 'v1.0/me/sendMail' -Body $params
    }
    Write-Verbose -Message 'Mail sent' -Verbose
}

function Set-IntuneAppOwner {
    Connect-MgGraph -Identity

    $URI = "https://graph.microsoft.com/beta/deviceManagement/auditEvents?`$filter=activityType eq 'Create MobileApp'"
    $values = Invoke-MgGraphRequest -Method GET -Uri $URI | Select-Object -expand Value | Where-Object activityDateTime -GT $date | Sort-Object activityDateTime
    foreach ($value in $values) {
        ## Extract actor (person who made the app)
        $actor = $value.actor.userPrincipalName

        ## Query graph to get the user's displayName and the application's id
        $URI2 = "https://graph.microsoft.com/v1.0/users/$($actor)"
        $displayName = Invoke-MgGraphRequest -Method GET -Uri $URI2 | Select-Object -expand DisplayName

        $appID = $value.resources.resourceId | Select-Object -Unique

        ## Get app to extract @odata.type
        try {
            $URI3 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($appID)"
            $app = Invoke-MgGraphRequest -Method GET -Uri $URI3
            $dataType = $app.'@odata.type'

            ## Set owner for application
            if (-not $app.owner) {
                $body = @{
                    '@odata.type' = $dataType
                    'owner'       = $displayName
                }
                $URI4 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($appID)"
                $jsonBody = $body | ConvertTo-Json -Depth 10

                Invoke-MgGraphRequest -Method PATCH -Uri $URI4 -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop
        
                # Send email to owner letting them know they've been assigned as owner of this application
                $params = @{
                    message         = @{
                        subject      = 'Intune App Owner Assignment'
                        body         = @{
                            contentType = 'HTML'
                            content     = "You have been assigned as the owner of the application: $($app.displayName)"
                        }
                        toRecipients = @(
                            @{
                                emailAddress = @{
                                    address = $actor
                                }
                            }
                        )
                    }
                    saveToSentItems = 'true'
                }

                Send-Mail -UserID $UserID -Application
            }
            else {
                Write-Output "Owner already set for $($app.displayName)"
            }
        }
        catch {
            Write-Output $_
        }
    }
}

$date = (Get-Date).AddDays(-7)

Set-IntuneAppOwner

