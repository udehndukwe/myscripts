<#
.SYNOPSIS
    Creates a new Microsoft Entra dynamic group.

.DESCRIPTION
    This function creates a new Microsoft Entra dynamic group using the Microsoft Graph API. 
    Required Microsoft.Graph.Authentication module for the Invoke-MgGraphRequest command. Function checks for presence of module and installs it if not found.
    The function takes a display name, a flag to indicate if the group is mail-enabled, and a membership rule as parameters.

.PARAMETER displayName
    The display name of the new dynamic group.

.PARAMETER mailEnabled
    Indicates if the group is mail-enabled. Default is $false.

.PARAMETER membershipRule
    The membership rule for the dynamic group. Single quotes must be on the outside and double quotes must be used to wrap the attribute value. Example format: '(device.extensionAttribute1 -eq "bridged_adapter")'

.EXAMPLE
    New-EntraDynamicGroup -displayName "Test Group" -membershipRule '(user.department -eq "Sales")'

.NOTES
    Author: Udeh Ndukwe
    Date: 12/11/2024
#>
function New-EntraDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$displayName,
        [string]$mailEnabled = $false,
        [string]$membershipRule
    )
    BEGIN {
        #Check for Microsoft.Graph.Authentication module. If not found, install and import module.
        $module = Get-Module Microsoft.Graph.Authentication -ListAvailable

        if (-not $module) {
            Install-Module -Name Microsoft.Graph.Authentication -Force -AllowClobber -Scope CurrentUser
            Import-Module Microsoft.Graph.Authentication
        }

        $URI = "https://graph.microsoft.com/beta/groups"

        $body = @{
            displayName                   = $displayName
            mailEnabled                   = $false
            mailNickname                  = $displayName.Replace(" ", "")
            securityEnabled               = $true
            groupTypes                    = @(
                "DynamicMembership"
            )
            membershipRule                = $membershipRule
            membershipRuleProcessingState = "On"
        }
    }
    PROCESS {
        try {
            Invoke-MgGraphRequest -Method POST -Uri $URI -body $body -ErrorAction Stop
        }
        catch {
            Write-Verbose "Dynamic Group Not Created. See error below:"
            if (Write-Output $_.Exception.Message -match "Invalid characters found in the rule") {
                Write-Error "Dynamic membership rule is not formatted properly. Review syntax for errors such as misplaced single and double quotation marks, missing dashes, etc."
            }
            else {
                Write-Error $_.Exception.Message
            }
        }
    }
}