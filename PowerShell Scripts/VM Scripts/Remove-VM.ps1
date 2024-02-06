param([Parameter(Mandatory)]$Name)

Remove-VM $Name -Confirm:$false
Remove-Item -Path "C:\Prod\VHDs\$Name.vhdx" -Confirm:$false -Recurse