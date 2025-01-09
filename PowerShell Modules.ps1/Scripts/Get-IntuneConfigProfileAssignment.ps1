function Get-IntuneConfigProfileAssignment {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DeviceConfigurationID,
        [string]$DeviceConfigurationAssignmentID
    ) 

    BEGIN {
        $URI = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($deviceConfigurationId)/assignments"
    }

    PROCESS {
        Invoke-MgGraphRequest -Method DELETE -uri $URI
    }
}


foreach ($intuneProfile in $profiles) {
    Get-IntuneConfigProfileAssignment -DeviceConfigurationID $intuneProfile.id -DeviceConfigurationAssignmentID $intuneProfile.Assignments.id
}

$URI = "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/b23f680e-ae7f-4a09-a681-77304b543e81/assignments"
Invoke-MgGraphRequest -Method GET -Uri $URI