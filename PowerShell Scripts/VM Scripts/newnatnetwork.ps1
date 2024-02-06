# $switchname = "LabSwitch"
# $switchtype = "Internal"
# New-VMSwitch -Name $switchname -SwitchType $switchtype
$netadapter = Get-NetAdapter -Name "*LabSwitch*"

$IPAddress = "10.0.0.1"
$Subnet = "24"

New-NetIPAddress -IPAddress $IPAddress -AddressFamily IPv4 -InterfaceAlias $netadapter.InterfaceAlias -PrefixLength $Subnet -DefaultGateway $IPAddress.Remove("7").Insert("7", "1")

New-NetNat -Name "RRNAT" -InternalIPInterfaceAddressPrefix 10.0.0.0/24

Get-NetNat


