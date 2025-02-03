$Serial = (Get-WmiObject Win32_BIOS).SerialNumber

$NewName = "RR-$Serial"

Rename-Computer -NewName $NewName