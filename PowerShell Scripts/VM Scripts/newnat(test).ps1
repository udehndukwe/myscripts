param
(
[Parameter(Mandatory)]$SwitchName,
[Parameter(Mandatory)]$IPAddress,
[Parameter(Mandatory)]$IPAddress2,
[Parameter(Mandatory)]$NATNAME
)

$VMSWitch = New-VMSwitch -Name $SwitchName -SwitchType Internal
$IF = Get-NetAdapter -Name "vEthernet ($SwitchName)" | Select-Object -expand InterfaceIndex

New-NetIPAddress -IPAddress $IPAddress -PrefixLength 24 -InterfaceIndex $IF
New-NetNat -Name $NATNAME -InternalIPInterfaceAddressPrefix $IPAddress2"/24"