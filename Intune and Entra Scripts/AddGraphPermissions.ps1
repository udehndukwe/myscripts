function Add-GraphAppPermissions {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$principalID,
        [object]$permissionList,
        [string]$AppDisplayName

    )

    # Get all app IDs for Microsoft Graph API	

    try {
        $URI = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq 'Microsoft Graph'"
        $graphServicePrincipal = (Invoke-MgGraphRequest -Method GET -Uri $URI).value

    }
    catch {
        Write-Output $_.Exception.Message
    }
	    
    foreach ($permission in $permissionList) {
        # Find all enabled Application permissions for Graph

        $appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains 'Application' }

        if ($AppDisplayName) {
            $URI = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq '$AppDisplayName'"
            $app = (Invoke-MgGraphRequest -Method GET -Uri $URI).value

            $params = @{
                principalId = $app.Id
                resourceId  = $graphServicePrincipal.Id
                appRoleId   = $appRole.id
            }
            $URI = "https://graph.microsoft.com/v1.0/servicePrincipals/$($app.Id)/appRoleAssignments"
            Invoke-MgGraphRequest -Method POST -Uri $URI -Body $params 
        }

    }

}
