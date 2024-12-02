# Set Value

function Set-CertificateUserIDMapping {
    param (
        [CmdletBinding()]
        [Parameter()]
        [string]$UserID
    )

    $module = Get-Module Microsoft.Graph.Authentication

    if (-not $module) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
        Connect-MgGraph
    }
    else {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
    }
  
    $certificates = Import-CSV $path

    $Issuer = "CN=ad-CA01-CA,DC=ad,DC=relrepairs,DC=com"
    foreach ($certificate in $certificates) {
    
        $certificate | Where UPN -eq "$UserID"
        $SerialNumber = $cert.SerialNumber
        $Info = "X509:<I>$Issuer<SR>$SerialNumber"    


        Invoke-MGGraphRequest -Method patch -Uri 'https://graph.microsoft.com/v1.0/users/$UserID/?`$select=authorizationinfo' -OutputType PSObject -Headers @{'ConsistencyLevel' = 'eventual' } -Body $params
    }

}

function f1 {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserID,
        [switch]$Serial,
        [switch]$SKI
    )

    $module = Get-Module Microsoft.Graph.Authentication

    if (-not $module) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
        Connect-MgGraph
    }
    else {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
    }

    #$ID = Invoke-MgGraphRequest -uri "https://graph.microsoft.com/v1.0/users/$UserID" | Select -expand Id
    if ($Serial) {
        $certificates = Import-CSV $path
        $Issuer = "DC=com,DC=relrepairs,DC=ad,CN=ad-CA01-CA"
        $cert = @()
        foreach ($certificate in $certificates) {
            $cert += $certificate | Where-Object UPN -eq "$UserID"
        }
        $SerialNumber = $cert | Where-Object SerialNumber | Select-Object -ExpandProperty SerialNumber
        $Info = @()
        foreach ($serial in $SerialNumber) {
            $Info += "X509:<I>$Issuer<SR>$serial" 
        }
    
        $params = @{
            authorizationInfo = @{
                certificateUserIds = @(
                    foreach ($item in $info) {
                        $item
                    }   
                )
            }
        }
    }

    if ($SKI) {
        $UserName = whoami -upn
        $mycert = ls cert:\CurrentUser\My\ | Where Subject -like "*E=$username*"
        $SubjectKeyID = $mycert.Extensions | Where { $_.Oid.FriendlyName -eq "Subject Key Identifier" }  | Select -expand SubjectKeyIdentifier    

        $params = @{
            authorizationInfo = @{
                certificateUserIds = @(
                    "X509:<SKI>$SubjectKeyID"
                )
            }
        }
    }

    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$UserID" -Body $params
    Get-EntraAuthorizationInfo -EntraUser $UserID
    
}





function Get-EntraAuthorizationInfo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EntraUser
    )

    $module = Get-Module Microsoft.Graph.Authentication

    if (-not $module) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
        Connect-MgGraph
    }
    else {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
    }

    Invoke-MGGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$EntraUser/?`$select=authorizationinfo" | Select -expand authorizationInfo | Select -expand certificateUserIds
}


