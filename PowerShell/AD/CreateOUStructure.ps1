function New-ADOUStructure {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Path = "DC=ad,DC=relrepairs,DC=com",
        [string]$Path2 = "OU=RR,DC=ad,DC=relrepairs,DC=com"
    )


    # Create RR
    New-ADOrganizationalUnit -Name "RR" -DisplayName "RR" -Path $Path
    # Create Users, Groups, Computers
    New-ADOrganizationalUnit -Name "Users" -DisplayName "Users" -Path $Path2
    New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path $Path2
    New-ADOrganizationalUnit -Name "Computers" -DisplayName "Computers" -Path $Path2
}

New-ADOUStructure

