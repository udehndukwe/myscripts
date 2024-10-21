$regpath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1033"
$value = Get-ItemProperty $regpath
$value.Version -ge 3.5