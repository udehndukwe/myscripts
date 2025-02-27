$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VisioStd2019Volume - en-us"

if (Test-Path $regpath) {

    Write-Host "Perpetual Visio install detected"
    exit 1
} else {
    Write-Host "Perpetual Visio install not detected."
}