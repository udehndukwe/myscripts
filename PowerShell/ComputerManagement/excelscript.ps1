Add-Type -AssemblyName System.Windows.Forms

#Import any filetype Excel spreadsheet to PowerShell and save as a variable
##Code for File Browser borrowed from: https://4sysops.com/archives/how-to-create-an-open-file-folder-dialog-box-with-powershell/


$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'SpreadSheet (*.xlsx)|*.xlsx'
}
$null = $FileBrowser.ShowDialog()

$file = Import-Excel $FileBrowser.FileName

#Get Services and Get DiskSpace and save to variables

$servicedata = Get-Service | Select Name, DisplayName, Status
$diskdata = Get-Volume C | Select-Object @{name="Free Space";Expression={[math]::Round($_.SizeRemaining / 1GB)}}, @{Name="Total Size";Expression={[math]::Round($_.Size / 1GB)}}

#Pipe variables to Export-Excel cmdlet which creates an excel workbook file with the above information. Each set of info is created in it's own sheet in the same workbook. If you picked an excel file to import when prompted, it will appear as a separate spreadsheet.

$diskdata | Export-Excel -Path .\computerinfo.xlsx -WorksheetName "Storage Info" -AutoSize -ClearSheet
$servicedata | Export-Excel .\computerinfo.xlsx -WorksheetName "Services" -Show -AutoSize -ClearSheet
$file | Export-Excel .\computerinfo.xlsx -WorksheetName "UserPickedSheet" -ClearSheet -Show -AutoSize

$conditional = New-ConditionalText -Text "Stopped" -BackgroundColor "Red" -ConditionalType Equal -ConditionalTextColor White

#Script sleeps for 10 seconds while the first version of the Excel file opens

Start-Sleep -Seconds 10

#Closes Excel

kill -processname EXCEL

#Asks if you want to run the script again to apply conditional formatting, which will fill any Cell with the specified text to Red background/White text
$ans = Read-Host -Prompt "Run Script again to apply conditional formatting to Excel? Enter 'Yes' or 'No'"

if ($ans -eq 'Yes') {

$diskdata | Export-Excel -Path .\computerinfo.xlsx -WorksheetName "Storage Info" -AutoSize
$servicedata | Export-Excel .\computerinfo.xlsx -WorksheetName "Services" -ClearSheet -Show -AutoSize -ConditionalText $conditional

}