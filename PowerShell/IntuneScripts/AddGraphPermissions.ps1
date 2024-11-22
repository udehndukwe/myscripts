function Add-GraphAppPermissions {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$principalID,
        [object]$permissionList,
        [string]$AppDisplayName

    )

# Get all app IDs for Microsoft Graph API	

$graphServicePrincipal = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"	
	

foreach ($permission in $permissionList)
{
    # Find all enabled Application permissions for Graph

    $appRole = $graphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application"}

    if ($AppDisplayName) {
        $app = Get-MgServicePrincipal -Filter "DisplayName eq '$AppDisplayName' "

        $params = @{
            principalID = $app.Id
            resourceID = $graphServicePrincipal.Id
            appRoleID = $appRole.id

        }

        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $app.Id -BodyParameter $params
        
    } else {

    $params = @{
        principalID = $principalID
        resourceid = $graphServicePrincipal.id
        appRoleID = $appRole.ID
    }

      New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $principalID -BodyParameter $params

    
        }
    }

}