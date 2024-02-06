param

(
[Parameter(Mandatory)]$Name,
[Parameter(Mandatory)]$SwitchName,
[Parameter(Mandatory)]$OS
)


$VM = New-VM  `
-Name $Name `
-MemoryStartupBytes 1GB `
-SwitchName $SwitchName `
-NewVHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$Name.vhdx" `
-NewVHDSizeBytes 60GB `
-Generation 2 `

Set-VM `
-Name $Name `
-DynamicMemory `
-MemoryMinimumBytes 1GB `

Add-VMDvdDrive -VMName $Name -Path "C:\Users\udeh.ndukwe\$OS.iso" 

$DVD = Get-VMDvdDrive -VMName $Name

Set-VMFirmware -VM $VM -FirstBootDevice $DVD



