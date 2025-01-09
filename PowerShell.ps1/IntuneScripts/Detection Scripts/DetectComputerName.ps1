$ComputerName = (Get-CimInstance -ClassName Win32_computerSystem).Name
$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber


if ($ComputerName -ne "RR-$SerialNumber") {
    Write-Output "Computer Name not set properly"
    exit 0
}
else {
    Write-Output "Computer name set properly"
    exit 1
}