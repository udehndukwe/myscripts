<#function Get-AllCertificateReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$IssuerName = 'CN=RR-SubCA, O=Reliable Repairs, L=Cleveland, S=OH, C=US'
    )
    #$Date = (Get-Date).AddMonths(6)
    $URI = 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurationsAllManagedDeviceCertificateStates'
    Invoke-MgGraphRequest -Method GET -Uri $URI | Select-Object -expand Value 
}#>

function Get-IntuneCertificateReport {
    Add-Type -AssemblyName System.Collections
    $certificates = [System.Collections.Generic.List[PSObject]]::new()

    # Get report for Windows SCEP Certificates
    $FileName = 'WindowsCertReport.zip'

    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('CertificatesByRAPolicy_83d72540-0481-42d9-b56c-401a954b0d77')"

    $value = Invoke-MgGraphRequest -Method GET -Uri $URI

    try {
        Invoke-RestMethod -Uri $value.url -OutFile $FileName -ErrorAction Stop
        try {
            Expand-Archive -Path $FileName -DestinationPath $FileName.Replace('.zip', '') -ErrorAction Stop
            $reportCSV = Get-ChildItem $FileName.Replace('.zip', '') -Filter '*.csv'
            $windowsCertificateReport = Import-Csv $reportCSV

        }
        catch {
            Write-Host 'Error extracting the file'
            break
        }
    }
    catch {
        Write-Host 'Error downloading the file'
        break
    }

    # Get report for macOS SCEP Certificates

    $FileName = 'MacOSCertReport.zip'
    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('CertificatesByRAPolicy_d413727c-94d9-4565-b1a6-990df14daeb6')"
    $value = Invoke-MgGraphRequest -Method GET -Uri $URI
    try {
        Invoke-RestMethod -Uri $value.url -OutFile $FileName -ErrorAction Stop
        try {
            Expand-Archive -Path $FileName -DestinationPath $FileName.Replace('.zip', '') -ErrorAction Stop
            $reportCSV = Get-ChildItem $FileName.Replace('.zip', '') -Filter '*.csv'
            $macOSCertificateReport = Import-Csv $reportCSV
        }
        catch {
            Write-Host 'Error extracting the file'
            break
        }
    }
    catch {
        Write-Host 'Error downloading the file'
        break
    }

    # Compile composiste list
    $certificates.add($windowsCertificateReport)
    $certificates.ADd($macCertificateReport)

    $certificates

    Write-Verbose 'Keep downloaded files? (Y/N)' -Verbose
    $input = Read-Host
    if ($input -eq 'N') {
        Remove-Item *$FileName* -Force
        Remove-Item *macOSFileName* -Force 
    }

}function Get-EntraAuthorizationInfo {
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

    Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$EntraUser/?`$select=authorizationinfo" | Select-Object -expand authorizationInfo | Select-Object -expand certificateUserIds
}


function Set-CertificateUserIDMapping {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserID,
        [switch]$Serial,
        [switch]$SKI,
        [switch]$SHA1,
        [string]$path
    )

    $module = Get-Module Microsoft.Graph.Authentication -ListAvailable

    if (-not $module) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
        Connect-MgGraph
    }
    else {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
    }

    <#$ID = Invoke-MgGraphRequest -uri "https://graph.microsoft.com/v1.0/users/$UserID" | Select -expand Id
    if ($Serial) {
        $certificates = Get-CertificateReport
        $Issuer = $certificates.IssuerName
        $cert = @()
        foreach ($certificate in $certificates) {
            $cert += $certificate | Where-Object UPN -EQ "$UserID"
        }
        $SerialNumber = $cert | Where-Object SerialNumber | Select-Object -ExpandProperty SerialNumber
        $Info = @()
        foreach ($serialno in $SerialNumber) {
            $Info += "X509:<I>$Issuer<SR>$serialno" 
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
    }#>

    if ($SKI) {
        $mycert = Get-hildItem cert:\CurrentUser\My\ | Where-Object Subject -Like "*E=$UserID*"
        $SubjectKeyID = $mycert.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Key Identifier' } | Select-Object -expand SubjectKeyIdentifier    

        $params = @{
            authorizationInfo = @{
                certificateUserIds = @(
                    "X509:<SKI>$SubjectKeyID"
                )
            }
        }
    }

    if ($SHA1) {
        #$certificates = Get-CertificateReport | Where-Object userPrincipalName -EQ "$UserID"
        #$Thumbprints = $certificates.certificateThumbprint
        $certificates = Get-IntuneCertificateReport
        $Thumbprints = $certificates.Thumbprint

        $info = [System.Collections.Generic.List[string]]::new()
        foreach ($thumbprint in $Thumbprints) {
            $info.add("X509:<SHA1-PUKEY>$thumbprint")
        }

        $params = @{
            authorizationInfo = @{
                certificateUserIds = @(
                    $Info               
                )
            }
        } 
    

        Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$UserID" -Body $params -Headers @{'ConsistencyLevel' = 'eventual' } -OutputType PSObject
        
        Get-EntraAuthorizationInfo -EntraUser $UserID
    
    }
}