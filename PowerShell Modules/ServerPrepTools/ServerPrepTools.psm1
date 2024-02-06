function Set-InitialInfo {
   $IPAddress = Read-host -Prompt "Enter IP Address"
    Set-TimeZone -Id "Eastern Standard Time" 
    $adapter = Get-NetAdapter Ethernet
    New-NetIPAddress -IPAddress $IPAddress -InterfaceAlias $adapter.ifAlias -DefaultGateway 10.0.0.1 -AddressFamily IPv4 -PrefixLength 24
    Set-DnsClientServerAddress -InterfaceAlias $adapter.ifAlias -ServerAddresses 10.0.0.6 
    
 }

 function Join-Domain {
   param(
      [string]$name
   )
   Add-Computer -NewName $name -Credential (Get-Credential) -DomainName "corp.relrepairs.com" -Restart
 }

 function Enable-RemotingSettings {
    Enable-PSRemoting -Force
    winrm quickconfig 
 }
 
 function Enable-AutoUpdates  {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\AUoptions" -Name newproperty  -Value "4"

 }

 function Install-DomainTools {
    Install-WindowsFeature AD-Domain-Services,DHCP -IncludeAllSubFeature -IncludeManagementTools -restart
 }

 function New-DomainController {
    param(
        [string] $DomainNetbiosName,
        [string] $DomainName
    )
    $hash = @{
        Confirm = $false
        SafeModeAdministratorPassword = (ConvertTo-SecureString -AsPlainText -force "Drake416!#")
    }

    Install-ADDSForest @hash
 }

 function Add-NetworkSettings {
    #Authorize DHCP Server in AD
    Add-DHCPServerinDC

    Add-DHCPServerv4Scope -Name "CORP" -StartRange 10.0.0.10 -EndRange 10.0.0.150 -SubnetMask 255.255.255.0
    Set-DhcpServerv4OptionValue -DnsServer 10.0.0.6  -DnsDomain "relrepairs.com" -Router 10.0.0.1 


 }

 function Set-ADInfra {
      $RR = "RR"
      $UsersOU = "Users"
      $GroupOU = "Groups"
      $WorkstationOU = "Workstations"
      $ServerOU = "Servers"
      $Path = "DC=corp,dc=relrepairs,dc=com"
      $OUPath = "OU=RR,DC=corp,dc=relrepairs,dc=com"


      #Create OU Structure
      New-ADOrganizationalUnit -Name $RR -DisplayName $RR -Path $Path
      
      $UsersOU, $GroupOU, $ServerOU, $WorkstationOU | ForEach-Object { 
         New-ADOrganizationalUnit -Name "$_" -DisplayName "$_" -Path $OUPath
      }

      #Create AD Users
      $userpath = (Get-ADOrganizationalUnit -Filter 'Name -eq "Users"').DistinguishedName

      $name = @()

      "Udeh Ndukwe", "Klyde Johnson", "Ryan Kelsey", "John Rogers", "Melissa Bradley", "Antiona Weatherspoon" | ForEach-Object {
         $name += $_
      }

 
      $name | ForEach-Object {
         New-AdUser -Name $_ -Path $userpath -Enabled $true -Company "Reliable Repairs" -SamAccountName $_.Replace(" ", ".").ToLower() -UserPrincipalName ($_.Replace(" ", ".").ToLower() + '@relrepairs.com') -AccountPassword (ConvertTo-SecureString -AsPlainText -Force "Drake416!#")
      } 

      #Create AD Groups

      "IT", "Sales", "HR" | ForEach-Object {
         New-ADGroup -DisplayName $_ -Name $_ -GroupScope Global
         
      }

      #AD Group Memberships -- Udeh and Klyde

      $adusers = get-aduser -filter * | Where-Object {($_.Name -eq "Klyde Johnson") -or ($_.Name -eq "Udeh Ndukwe")}
      "Domain Admins", "Schema Admins", "Enterprise Admins", "Group Policy Creator Owners" | ForEach-Object {
         Add-ADGroupMember -Identity $_ -Members $adusers
      }
      
      function Install-MECMPrerequisites {
         Install-WindowsFeature BITS,NET-Framework-Features
      }


      }


         
 
 