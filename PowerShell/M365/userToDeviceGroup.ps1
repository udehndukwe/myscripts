[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$Path
)

#Pull all Intune managed devices
$IntuneDevices = Get-MgDeviceManagementManagedDevice -All -Property DeviceName, SerialNumber, Id, AzureAdDeviceId, UserPrincipalName
$EntraDevices = Get-MGdevice -All -Property RegisteredOwners, RegisteredUsers, Id, DeviceID
#Import CSV that contains list of users
$users = Import-csv -Path $Path

#Find Intune managed devices that are owned by users in the list (NOTE: If user has 5 devices in Intune it will return all 5 devices)
$devices = foreach ($user in $users) {
    $IntuneDevices.Where({ $_.UserPrincipalName -eq $user.additionalPRoperties.userPrincipalName }) | Select-Object ID, SerialNumber, UserPrincipalName, DeviceName, AzureAdDeviceId
}



#Create MG Group based on name that was entered when prompted and add devices to it
$group = New-MgGroup -DisplayName $Name -MailEnabled:$false  -SecurityEnabled -MailNickname $name.Replace(" ", "")

#Retrieve Entra object that matches Intune Device
$finalDeviceList = foreach ($device in $devices) {
    $EntraDevices.Where({ $_.DeviceId -eq $device.AzureAdDeviceId })
}
# Add to Group
foreach ($device in $finalDeviceList) {
    New-MGGroupMember -GroupId $group.Id -DirectoryObjectId $device.Id
}