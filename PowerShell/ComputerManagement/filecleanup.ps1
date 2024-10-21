#Delete old files
#Organize files (by date or name)

Add-Type -AssemblyName System.Windows.Forms
##Code for File Browser borrowed from: https://4sysops.com/archives/how-to-create-an-open-file-folder-dialog-box-with-powershell/


$prompt1 = Read-Host "Do you want to arrange files by file type? Or do you want to delete old files? Enter 'Delete' to delete files, and 'arrange' to arrange files"


if ($prompt1 -like "delete") {
    $x = read-host -Prompt "Enter number of days. Files older than this amount of days will be listed for deletion"
    $date = Get-Date
    $chosendate = $date.AddDays(- + "$x")
    $name = ("deletereport" + $date.Month + "-" + $date.Year)

    ##Found through Microsoft's Website##
    $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    Description = "Select folder to delete files from"
            }    


    $null = $FileBrowser.ShowDialog()
    $deletereport = Get-ChildItem -Path $FileBrowser.SelectedPath -Recurse | Where-Object -Property LastWriteTime -LE $chosendate | Sort-Object -Property LastWriteTime -Descending

    ls $deletereport    
    $ans2 = Read-Host -Prompt "Delete these files? Enter 'Yes' or 'No' (DELETE AT YOUR OWN RISK)"
    if ($ans2 -like 'Yes') {
        $deletereport.FullName | ForEach-Object {
            Remove-Item -Path $_ -Force -Recurse
        }
    }


    $deletereport | Out-File ./$name.txt

}

if ($prompt1 -like "arrange") {

    $foldername = Read-Host -Prompt: "Enter Name of New Folder"
    $OneDrive = Read-Host -Prompt: "Scan OneDrive Folders? Enter Yes or No"

    $pdfs = New-Object System.Management.Automation.Host.ChoiceDescription '.&pdf', "PDF Files"
    $excel = New-Object System.Management.Automation.Host.ChoiceDescription '.&xlsx', "Excel Files"
    $text = New-Object System.Management.Automation.Host.ChoiceDescription '.&txt', "Text Files"

    ##Found through Microsoft's Website and https://4sysops.com/archives/read-host-and-the-choicedescription-class-prompt-for-user-input-in-powershell/##

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($pdfs, $excel, $text)

    $title = "Select File Type"
    $message = "Select file type you want to search for and organize"
    $result = $host.UI.PromptForChoice($title, $message, $options, 0)

    switch ($result) 
    {
        0 {$filetype = ".pdf"}
        1 {$filetype = ".xlsx"}
        2 {$filetype = ".txt"}
    }


    $directory = $env:HOMEPATH + "\" + "OneDrive"




    if ($OneDrive -like "No") {
    $items = Get-ChildItem $env:HOMEPATH -Recurse -Filter "*$filetype*" | Where Directory -NotLike "*$directory*"
    } else {
    $items = Get-ChildItem $env:HOMEPATH -Recurse -Filter "*$filetype*"  
    }

    mkdir $env:HOMEPATH\$foldername
    write $items

    $answer = Read-Host -Prompt "Make copies? Enter 'Yes' or 'No'"

    if ($answer -eq 'Yes') {

        $items.fullname | ForEach-Object {
       
            Copy-Item -Path $_ -Destination $env:HOMEPATH\$foldername

        }
    }

    write "Verifying that files were moved..."

    Start-Sleep -Seconds 3


    ls $env:HOMEPATH\$foldername


    $ans3 = Read-Host -Prompt "Delete Old files? Enter 'Yes' or 'No' (DELETE AT OWN RISK)"
        if ($ans3 -eq "Yes") {
            $items.FullName | ForEach-Object {
                Remove-Item -Path $_ -Force -Recurse
            }
        }
    if ($answer -eq 'No') {

        write "OK. Closing Program."

    }
}
