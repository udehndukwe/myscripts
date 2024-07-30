function Clear-VM {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$VMName
    )

    BEGIN {
        $VM = Get-VM -Name $VMName
        $VHD = Get-VHD -VMId $vm.Id
    }

    PROCESS {
        try {
            Remove-VM -VM $VM -ErrorAction Stop
        }
        catch {
            Write-Verbose -Message $_.Exception.Message -Verbose
        }
        finally {
            Remove-item -Path $vhd.Path
        }
    }
}