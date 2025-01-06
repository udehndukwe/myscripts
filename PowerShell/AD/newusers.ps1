#Import CSV with New Hire information that we normally fill out manually for each user

$users = Import-CSV -Path \\labdc01\Software\NewUsers\NewHires.csv

#Command to create user accounts with all of the information that we usually fill out manually (Manager, Address, Company, etc)

$users | ForEach-Object {
    New-ADUser `
        -Name $($_.FirstName + " " + $_.LastName) `
        -GivenName $_.FirstName `
        -Surname $_.LastName `
        -Department $_.Department `
        -State $_.State `
        -EmployeeID $_.EmployeeID `
        -DisplayName $($_.FirstName + " " + $_.LastName) `
        -Office $_.Office `
        -MobilePhone $_.MobilePhone `
        -Manager $_.Manager `
        -StreetAddress $_.StreetAddress `
        -EmailAddress $_.EmailAddress `
        -Company $_.Company `
        -City $_.City `
        -Country $_.Country `
        -Description $_.Description `
        -UserPrincipalName $_.UserPrincipalName `
        -SamAccountName $_.SamAccountName `
        -PostalCode $_.PostalCode `
        -Title $_.Title `
        -AccountPassword $(ConvertTo-SecureString $_.Password -AsPlainText -Force) `
        -path "OU=Users,OU=Reliable Repairs,DC=ndukweuh,DC=com" `
        -Enabled $True
    
    #Sets the phone number for user on main page to be equivalent to the phone number listed in the CSV as "Mobile Phone"    
    Set-ADUser $_.SamAccountName -Add @{telephonenumber=$_.MobilePhone}
    
    #Sets AD user's password to be changed on logon
    Set-ADUser -identity $_.SamAccountName -ChangePasswordAtLogon $true

    #Adds AD Users to group based on their department/extension attribute 1
    if ($_.Department -eq "xxx-Managed Services") {
    Add-ADGroupMember -Identity 'Managed Services' -Members $_.SamAccountName
    }
    elseif ($_.Department -eq "xxx-Sales") {
    Add-ADGroupMember -Identity 'Sales' -Members $_.SamAccountName
    }

    #Pulls group membership information for newly created AD Users and plugs it into variable
    $group = Get-ADPrincipalGroupMembership $_.SamAccountName | select -exp name

    #Pulls the OU location for newly created AD Users and plugs it into variable
    $property = Get-ADUser -Identity $_.SamAccountName | Select-Object -Property DistinguishedName
    
    #Statements that check to see if the AD Users are in a specified group, and if so, then moves them to the OU corresponding with that group
    if ($group -contains "Sales"){
    Move-ADObject -Identity $property.DistinguishedName -TargetPath "OU=Sales,OU=Reliable Repairs,DC=ndukweuh,DC=com"
    }
    elseif ($group -contains "Managed Services"){
    Move-ADObject -Identity $property.DistinguishedName -TargetPath "OU=Managed Services,OU=Reliable Repairs,DC=ndukweuh,DC=com"
    }
    elseif($group -contains "Cloud Delivery Team") {
    Move-ADObject -Identity $property.DistinguishedName -TargetPath "OU=Cloud Delivery Team,OU=Reliable Repairs,DC=ndukweuh,DC=com"
    }

    #Sample of what is needed to modify extension Attribute 5
    $ThisUser = Get-ADUser -Identity $_.SamAccountName -Properties extensionName
        Set-ADUser –Identity $ThisUser -add @{"extensionname"=$_.EmailAddress}

    #Sample for extension Attribute 1    
    $ThisUser = Get-ADUser -Identity $_.SamAccountName -Properties employeeType 
      Set-ADUser –Identity $ThisUser -add @{"employeetype"=$_.Department}

    #Sample for extension Attribute 15
    
    $ThisUser = Get-ADUser -Identity $_.SamAccountName -Properties gecos 
      Set-ADUser  –Identity $ThisUser -add @{"gecos"=$_.SamAccountName + "@thinkahead.com"}


}