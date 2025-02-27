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
            Expand-Archive -Path $FileName -DestinationPath $FileName.Replace('.zip', '') -Force -ErrorAction Stop
            $reportCSV = Get-ChildItem $FileName.Replace('.zip', '') -Filter '*.csv'
            $windowsCertificateReport = Import-Csv $reportCSV

        }
        catch {
            $_.Exception.Message
            Write-Host 'Error extracting Windows report file'
            break
        }
    }
    catch {
        $_.Exception.Message
        Write-Host 'Error downloading Windows report' 
        break
    }

    # Get report for macOS SCEP Certificates

    $FileName = 'MacOSCertReport.zip'
    $URI = "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs('CertificatesByRAPolicy_d413727c-94d9-4565-b1a6-990df14daeb6')"
    $value = Invoke-MgGraphRequest -Method GET -Uri $URI
    try {
        Invoke-RestMethod -Uri $value.url -OutFile $FileName -ErrorAction Stop
        try {
            Expand-Archive -Path $FileName -DestinationPath $FileName.Replace('.zip', '') -Force -ErrorAction Stop
            $reportCSV = Get-ChildItem $FileName.Replace('.zip', '') -Filter '*.csv'
            $macOSCertificateReport = Import-Csv $reportCSV
        }
        catch {
            $_.Exception.Message

            Write-Host 'Error extracting macOS report file'
            break
        }
    }
    catch {
        $_.Exception.Message

        Write-Host 'Error downloading macOS report'
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

}




