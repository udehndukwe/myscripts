$PDFS = Read-Host -Prompt: "Enter Name of New Folder"
$OneDrive = Read-Host -Prompt: "Scan OneDrive Folders? Enter Yes or No"


$directory = $env:HOMEPATH + "\" + "OneDrive"


mkdir $env:HOMEPATH\$PDFS

if ($OneDrive -eq "No") {
$items = Get-ChildItem $env:HOMEPATH -Recurse -Filter "*.pdf" | Where Directory -NotLike "*$directory*"
} else {

$items = Get-ChildItem $env:HOMEPATH -Recurse -Filter "*.pdf"  

}

write $items

$answer = Read-Host -Prompt "Make copies? Enter 'Yes' or 'No'"

if ($answer -eq 'Yes') {

$items.fullname | ForEach-Object {

Copy-Item -Path $_ -Destination $env:HOMEPATH\COPIEDPDFS

}

    $ans2 = Read-Host -Prompt "Delete Old files? Enter 'Yes' or 'No' (DELETE AT OWN RISK)"
    if ($ans2 -eq 'Yes') {

        $items.FullName | ForEach-Object {
            Remove-Item -Path $_ -Force -Recurse
        }
    }


}

if ($answer -eq 'No') {

    Write "OK. Closing Program."
}


