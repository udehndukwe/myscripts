<#
.SYNOPSIS
Creates a new dynamic group in Microsoft Entra ID (Azure AD).

.DESCRIPTION
The New-EntraDynamicGroup function creates a new dynamic group in Microsoft Entra ID (Azure AD) using Microsoft Graph API. 
The group will have dynamic membership based on the provided membership rule.

.PARAMETER DisplayName
Specifies the display name of the new group.

.PARAMETER MembershipRule
Specifies the membership rule for the dynamic group. This rule determines the criteria for membership in the group.

.EXAMPLE
PS C:\> New-EntraDynamicGroup -DisplayName "Engineering Team" -MembershipRule "(user.department -eq 'Engineering')"

This example creates a new dynamic group named "Engineering Team" where the membership rule includes users whose department is "Engineering".

.NOTES
Requires the Microsoft Graph PowerShell module and appropriate permissions to create groups in Microsoft Entra ID.
#>
function New-EntraDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DisplayName,
        [string]$MembershipRule
    )

    $URI = "https://graph.microsoft.com/beta/groups"
    $body = @{
        displayName                   = $DisplayName
        mailEnabled                   = $false
        mailNickname                  = $DisplayName.Replace(" ", "")
        securityEnabled               = $true
        groupTypes                    = @(
            "DynamicMembership"
        )
        membershipRule                = $MembershipRule
        membershipRuleProcessingState = "On"
    }
    Invoke-MgGraphRequest -Method POST -Uri $URI -body $body
}