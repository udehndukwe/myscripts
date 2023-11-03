The module used in this script is the ImportExcel module. To install and import this module, run the following command in PowerShell:
Install-Module ImportExcel
Import-Module Import-Excel

The script displays 3 tasks performed by commands that are a part of the ImportExcel module. 

-The initial part opens a File Explorer window that allows you to search for an excel spreadsheet to import and contain in a variable using the Import-Excel command.
-The next part of the script gets the disk space information for the system the script is running on, and it gets the service information (Name, Display Name and Status) and saves them to two variables.

-The second major part of the script uses the Export-Excel command to export the data contained in these variables to an .xlsx spreadsheet file. Unlike 'Export-CSV', it will add the info contained in each variable to the same file, separated as different Sheets. It will also export the spreadsheet file you selected when the script first ran as well. It then opens the spreadsheet for you to view, but will close in 10 seconds.

-In the third major part, the script will ask you to select Yes or No to the question of wanting to export the information again, but with conditional formatting for the spreadsheet. Selecting Yes will reopen the spreadsheet, but every cell with the word "Stopped" in it will be colored red with white text. This highlights all stopped Services.

