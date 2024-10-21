$role = Get-MgRoleManagementDirectoryRoleDefinition -filter "DisplayName eq 'User Administrator'"

$permissions = $role | Select -expand RolePermissions
$newRolePermissions = $permissions.AllowedResourceActions -notlike "*License*"

#make role

$DisplayName = "RR - User Admin"
$Description = "Can manage users, but not manage license assignments"
$templateID = (New-Guid).Guid

$allowedResourceAction = 
@(
    $newRolePermissions
)
$customRolePermissions = @(@{AllowedResourceActions = $allowedResourceAction })

# New Admin Role

$customRole = New-MgRoleManagementDirectoryRoleDefinition -RolePermissions $rolePermissions -DisplayName $displayName -IsEnabled -Description $description -TemplateId $templateId
