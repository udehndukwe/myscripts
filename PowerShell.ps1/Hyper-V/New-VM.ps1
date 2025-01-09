function Deploy-VM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$SwitchName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("WinClient", "WinServer", "PFSENSE")]
        [string]$OS
    )
    
    if ($OS -eq "WinClient") {
        $Path = 'C:\Users\udeh.ndukwe\OneDrive - corpreliablerepairs\Intune Deployment Files\OS Deployment Files\Win10.iso'
    }
    elseif ($OS -eq "WinServer") {
        $Path = 'C:\Users\udeh.ndukwe\OneDrive - corpreliablerepairs\Intune Deployment Files\OS Deployment Files\WinServer2022.iso'
    }
    elseif ($OS -eq "PFSENSE") {
        $Path = 'C:\Users\udeh.ndukwe\OneDrive - corpreliablerepairs\Intune Deployment Files\OS Deployment Files\pfSense-CE-2.7.2-RELEASE-amd64.iso'
    }
    $VM = New-VM `
        -Name $Name `
        -MemoryStartupBytes 1GB `
        -SwitchName $SwitchName `
        -NewVHDPath "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$Name.vhdx" `
        -NewVHDSizeBytes 60GB `
        -Generation 2
    
    Set-VM `
        -Name $Name `
        -DynamicMemory `
        -MemoryMinimumBytes 1GB

    Add-VMDvdDrive -VMName $Name -Path $Path

    $DVD = Get-VMDvdDrive -VMName $Name

    Set-VMFirmware -VM $VM -FirstBootDevice $DVD
}

