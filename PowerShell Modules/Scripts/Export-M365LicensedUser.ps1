<#
.SYNOPSIS
    Exports users with specific Microsoft 365 licenses.

.DESCRIPTION
    This function exports users who have specific Microsoft 365 licenses based on the provided LicenseSkuPartNumber.

.PARAMETER LicenseSkuPartNumber
    The SKU part number of the license to filter users by.

.EXAMPLE
    Export-M365LicensedUser -LicenseSkuPartNumber "ENTERPRISEPACK"

.NOTES
    Author: Udeh Ndukwe
    Date: Today's Date
#>
function Export-M365LicensedUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LicenseSkuPartNumber
    )
    $licenseArray = @(
        "SPE_E5"
        "ENTERPRISEPACK"
        "SPE_F1"
        "DESKLESSPACK"
        "PROJECT_P1"
        "PROJECTPROFESSIONAL"
        "PROJECTPREMIUM"
        "VISIOCLIENT"
        "Microsoft_365_Copilot"
        "MCOMEETADV"
        "EMS"
        "MCOCAP"
        "MCOPSTN_5"
        "MCOEV"
        "EMSPREMIUM"
    )

    switch ($licenseArray) {
        "Microsoft_365_Copilot" {
            $productName = "Microsoft 365 Copilot"
        } "SPE_E5" {
            $productName = "Microsoft 365 E5"
        } "ENTERPRISEPACK" {
            $productName = "Office 365 E3"
        } "SPE_F1" {
            $productName = "Microsoft 365 F3"
        }"DESKLESSPACK" {
            $productName = "Office 365 F3"
        }"PROJECT_P1" {
            $productName = "Project Plan 1"
        }"PROJECTPROFESSIONAL" {
            $productName = "Project Plan 3"
        }"PROJECTPREMIUM" {
            $productName = "Project Plan 5"
        }"VISIOCLIENT" {
            $productName = "Visio Plan 2"
        } "MCOMEETADV" {
            $productName = "Microsoft 365 Audio Conferencing"
        } "EMS" {
            $productName = "Enterprise Mobility + Security E3"
        } "EMSPREMIUM" {
            $productName = "Enterprise Mobility + Security E5"
        } "MCOEV" {
            $productName = "Microsoft Teams Phone Standard"
        } "MCOCAP" {
            $productName = "Microsoft Teams Shared Devices"
        } "MCOPSTN_5" {
            $productName = "Microsoft Teams Domestic Calling Plan (120 min)"
        } 
    }

    $allusers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AssignedLicenses

    $License = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq $LicenseSkuPartNumber
    $SkuID = $license.skuid

    $licensedUsers = foreach ($user in $allusers) {
        $user.Where({ $_.AssignedLicenses.SkuID -eq $SkuID })
    }
    [PSCustomObject]@{
        Name              = $licensedUsers.DisplayName
        UserPrincipalName = $licensedUsers.UserPrincipalName
        ID                = $licensedUsers.ID
        License           = $productName
    }

}
