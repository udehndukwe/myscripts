function New-NetNatConfig {
[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $IPAddress,
    [String]
    $AddressFamily ='IPv4',
    [String]
    $PrefixLength = 24,
    [string]
    $Name

)

#Get net adapter
$adapter = Get-NetAdapter *vEthernet*

#New IP Address
New-NetIPAddress -IPAddress $IPAddress -InterfaceAlias $adapter.ifAlias -AddressFamily $AddressFamily -PrefixLength $PrefixLength

#Config NAT
New-NetNat -InternalIPInterfaceAddressPrefix 10.0.0.0/24 -Name $Name


}
