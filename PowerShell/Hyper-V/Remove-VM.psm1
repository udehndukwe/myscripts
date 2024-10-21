function Clear-VM {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$VMName
    )

    BEGIN {
        $VM = Get-VM -Name $VMName
        $VHD = Get-VHD -VMId $vm.Id
        Stop-VM -vm $VM -Force
    }

    PROCESS {
        try {
            Remove-VM -VM $VM -ErrorAction Stop
        }
        catch {
            Write-Verbose -Message $_.Exception.Message -Verbose
        }
        try {
            Remove-item -Path $vhd.Path -erroraction Stop
        }
        catch {
            $path = Read-Host -Prompt "Enter proper VHD path here"
            Remove-Item -Path $path
        }
    }
}