$Serial = (Get-WmiObject Win32_BIOS).SerialNumber

$NewName = "RR-$Serial"

if ($env:COMPUTERNAME -ne $NewName) {
    Write-Output 'Computer name is not correct.'
    exit 1
}
else {
    Write-Output 'It is fine'
    exit 0
}