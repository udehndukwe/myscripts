function Merge-Sheets {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]$CSVPath,
        [string]$ExportPath = "C:\Users\undukwe\OneDrive - STERIS Corporation\Documents\Spreadsheets\PMPC Test Group Sheets",
        [string]$AppName,
        [switch]$Format
    )

    $compositeSheet = foreach ($path in $CSVPath) {
        Import-CSV -Path $path
    }
    $compositeSheet = $compositeSheet | Where EmailAddress
    $compositeSheet | Select-Object * | Export-Excel -Path $ExportPath\$appName.xlsx -AutoSize -WorksheetName "Users"
    
    $file = ls $ExportPath\$appName.xlsx
    IF ($Format) {
        # Format Sheet
        $excel = Open-ExcelPackage -Path $file
        $worksheet = $excel.Workbook.Worksheets["Users"]

        #Highlight cells in first 50 rows.
        $range = $worksheet.Cells["A2:D50"]
        $range.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
        $range.Style.Fill.BackgroundColor.SetColor(([System.Drawing.Color]::LightPink))

        $newRange = $worksheet.Cells
        foreach ($cell in $newRange) {
            $cell.Style.Border.BorderAround("Medium")
        }


        Close-ExcelPackage -ExcelPackage $excel 

        & $file
    }

    # Clean up

    $archiveFolder = "C:\Users\undukwe\OneDrive - STERIS Corporation\Documents\Spreadsheets\PMPC Test Group Sheets\Archive"
    foreach ($path in $CSVPath) {
        Move-Item -Path $path -Destination $archiveFolder
    }

}

function New-PMPCTestGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$groupName = "TEST - PMPC - SSMS 18",
        [object]$Sheet
    )
    

    $mailNickname = $groupName.Replace(" ", "")
  
    $groupExists = Get-MgGroup -filter "DisplayName eq '$groupname'"
    if (-not $groupExists) {
        $group = New-MgGroup -DisplayName $groupName -MailNickname $mailNickname -SecurityEnabled -ErrorAction Stop -MailEnabled:$false
    }
    else {
        $group = $groupExists
    }
        
    Write-Verbose -Message "Group already exists. Moving on to add members." -Verbose
    $sheet = $sheet | Select -First 50
    $members = foreach ($user in $sheet) {
        Get-MgUser -UserId $user.emailAddress
    }
    foreach ($member in $members) {
        New-MgGroupmember -GroupId $group.Id -DirectoryObjectId $member.Id
    }

}

function Expand-Zips {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Path = 'C:\Users\undukwe\OneDrive - STERIS Corporation\Documents\Spreadsheets\PMPC Test Group Sheets'
    )   
    $files = Get-ChildItem -Path $Path -Filter "*.zip*"
    Write-Verbose -Message "Unzipping the following files:"

    Write-Host -Message "Files to be unzipped:" -ForegroundColor "Yellow"
    foreach ($file in $files) {
        $file
    }
 

    foreach ($file in $files) {
        Expand-Archive -Path $file.FullName -DestinationPath $file.FullName.Replace(".zip", "")
        $newFile = ls $file.FullName.Replace(".zip", "") 
        $newFile | Rename-item -NewName $file.Name.replace(".zip", ".csv")
        $renamedFile = ls $file.FullName.Replace(".zip", "") 
        move-item $renamedFile.FullName -Destination $file.Directory
        Remove-Item -Path $file.FullName
        Remove-Item -Path $file.FullName.Replace(".zip", "") -Recurse -Force
    }
}


