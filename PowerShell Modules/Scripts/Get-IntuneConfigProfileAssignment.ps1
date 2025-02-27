function Get-IntuneConfigProfileAssignment {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DeviceConfigurationID,
        [string]$DeviceConfigurationAssignmentID
    ) 

    BEGIN {
        $DCURIs = @(
            "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$DeviceConfigurationID/assignments",
            "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$DeviceConfigurationID/assignments/",
            "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations/$DeviceConfigurationID/assignments,"
            "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations/$DeviceConfigurationID/assignments/"
        )    
    }

    PROCESS {
        foreach ($uri in $DCURIs) {
            Invoke-MgGraphRequest -Method GET -Uri $uri
        }
    }
}


foreach ($intuneProfile in $profiles) {
    Get-IntuneConfigProfileAssignment -DeviceConfigurationID $intuneProfile.id -DeviceConfigurationAssignmentID $intuneProfile.Assignments.id | Select-Object -expand value
}

$configID = 'e4fcd85b-d843-4f44-a56c-1fd94d261bb6'
$assignmentID = 'e4fcd85b-d843-4f44-a56c-1fd94d261bb6_acacacac-9df4-4c7d-9d50-4ef0226f57a9'
$URI = "v1.0/deviceManagement/deviceConfigurations/$configID/assignments/$assignmentID"
$URI = 'v1.0/deviceManagement/deviceConfigurations/e4fcd85b-d843-4f44-a56c-1fd94d261bb6/assignments/e4fcd85b-d843-4f44-a56c-1fd94d261bb6_acacacac-9df4-4c7d-9d50-4ef0226f57a9'

Invoke-MgGraphRequest -Method GET -Uri $URI