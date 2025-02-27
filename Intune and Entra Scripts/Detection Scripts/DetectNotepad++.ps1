$item = Test-Path 'C:\Program Files\Notepad++\notepad++.exe' 
$item2 = Test-Path 'C:\Program Files (x86) \Notepad++\notepad++.exe' 



if (($item -eq "True") -or ($item2 -eq "True")) {
    Write-Output "Notepad Detected"
    exit 1
}
else {
    Write-Output "N/A"
}