##Create New Group
#default properites are: -AccessType Private -UnifiedGroupWelcomeMessageEnabled:$false -HiddenFromExchangeClientsEnabled:$true -HiddenFromAddressListsEnabled:$false -AutoSubscribeNewMembers:$True -RequireSenderAuthenticationEnabled:$True -SubscriptionEnabled
#displayname, mailnickname, mailaddress are required, description is optional

$groupparams = @{
    DisplayName = "DL-IT Operations Team"
    PrimarySmtpAddress = "itoperationsteam@relrepairs.com"
    Notes = ''
    Alias = 'itoperationsteam'
}

$groupsettings = @{
    DisplayName = "DL-IT Operations Team"
    AccessType = "Private"
    UnifiedGroupWelcomeMessageEnabled = "false"
    HiddenFromExchangeClientsEnabled = "true"
    HiddenFromAddressListsEnabled = "false"
    AutoSubscribeNewMembers = "true"
    RequireSenderAuthenticationEnabled = "$true"
    SubscriptionEnabled = ''
}




New-UnifiedGroup @groupparams
Set-UnifiedGroup @groupsettings