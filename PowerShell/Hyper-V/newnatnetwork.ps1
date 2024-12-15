function New-NATNetwork {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$IPAddress,
        [string]$Subnet = "24",
        [string]$Name
    )

    $VMSwitch = Get-VMSwitch -SwitchType Internal | Where Name -NE "Default Switch"

    if (-not $VMSwitch) {
        Write-Verbose "No Internal VMSwitch found. Creating one..." -Verbose
        New-VMswitch -Name "InternalSwitch" -SwitchType Internal
        $netadapter = Get-NetAdapter | Where-Object Name -eq "vEthernet (InternalSwitch)"
    }
    else {
        $netadapter = Get-NetAdapter | Where-Object Name -eq "vEthernet ($($VMSwitch.Name))"
    }
}

$IPAddress = $IPAddress
$Subnet = $Subnet

New-NetIPAddress -IPAddress $IPAddress -AddressFamily IPv4 -InterfaceAlias $netadapter.InterfaceAlias -PrefixLength $Subnet -DefaultGateway $IPAddress.Remove("7").Insert("7", "1")

$networkAddress = [regex]::Replace($IPAddress, '\d+$', '0')
New-NetNat -Name $Name -InternalIPInterfaceAddressPrefix "$networkAddress/$Subnet"

Get-NetNat


