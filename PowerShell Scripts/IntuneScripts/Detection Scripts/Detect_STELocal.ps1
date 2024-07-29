if (Get-LocalUser STELocal) {
    Write-Output "N/A"
} else {
    Write-Host "Account not detected"
    exit 1
}



