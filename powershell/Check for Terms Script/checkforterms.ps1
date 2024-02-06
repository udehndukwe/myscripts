Read-Host -Prompt "Press enter to sign in with O365 admin credentials"

Connect-MSOlservice #Sign in to the dialog box that appears using your O365 Admin credentials

Add-Type -AssemblyName System.Windows.Forms

Read-Host -Prompt "Select your CSV file. Press Enter to continue"

$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'SpreadSheet (*.csv)|*.csv'
}
$null = $FileBrowser.ShowDialog()

$file = Import-Csv $FileBrowser.FileName

#Used to make format of email/username suffixes uniform and lowercase
$users = $file.username.Replace("___", "___").Replace("___", "[company name]").Replace("__", "___").ToLower()

$allazureusers = $users | ForEach-Object { 
    Get-MsolUser -SearchString $_ 

}


$comparison = Compare-Object -DifferenceObject $users -ReferenceObject $allazureusers.UserPrincipalName | Select -ExpandProperty InputObject
$disabledusers = $users | ForEach-Object {
    Get-MSOluser -SearchString $_ -EnabledFilter DisabledOnly | Select -ExpandProperty UserPrincipalName
}


write "These users are disabled and their licenses can be removed:"
"`n"
$disabledusers
"`n"
write "Manually check these users as these accounts might be deleted in Azure or renamed:" "`n" $comparison
"`n"
Read-Host -Prompt "Operation completed. Press enter to exit"