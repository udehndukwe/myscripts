connect-mggraph -Scopes Directory.ReadWrite.all, AppRoleAssignment.ReadWrite.All
$sp = Get-MgServicePrincipal -ServicePrincipalId 94393cd6-db14-479a-b5a3-078e8104b6ae

$graphAppId = "17df89c6-0f0b-4c52-ad08-39a3672ac6d9"
$ServicePrincipalId = "94393cd6-db14-479a-b5a3-078e8104b6ae"
$appRoleID = (Find-MgGraphPermission AuditLog.Read.all | Where PermissionType -eq Application | Select -ExpandProperty ID)
$PrincipalID = "0409c90e-69a3-4607-a222-1ba1c5508969"

$params = @{
    resourceID  = $GraphAppId
    appRoleID   = $appRoleID 
    principalID = $ServicePrincipalId
}

New-MgServicePrincipalAppRoleAssignment -BodyParameter $params -ServicePrincipalId $sp.Id




