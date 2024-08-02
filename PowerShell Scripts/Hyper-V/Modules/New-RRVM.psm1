function New-RRVM {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string]$Name,
        [string]$Path = "C:\Users\udeh.ndukwe.CORP\OneDrive - corpreliablerepairs\Intune Deployment Files\OS Deployment Files\Win10.iso"
    )
    BEGIN {

        $vm = Get-VM CLIENT1
        $switch = (Get-VMNetworkAdapter -VMName CLIENT1).SwitchName
        $params = @{
            Name = $Name
            MemoryStartupBytes = $vm.MemoryStartup
            NewVHDPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$Name.vhdx"
            NewVHDSizeBytes = 20GB
            Generation = $vm.Generation

        }
    }

    PROCESS {
        $newVM = New-VM @params
        Add-VMDvdDrive -VMName $newVM.Name -Path $Path -ControllerLocation 1 
    } 

    END {
        Start-VM -VM $newVM
    }
}