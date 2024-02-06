This script is an expansion of the Project 1 script I created that moved all PDFs scanned in the user profile directory to a centralized location. This script has two separate functions. The first function is an expanded version of the move pdfs script, except you can select excel (.xlsx) and txt files in addition to PDF files. 

Steps (Enter "arrange" when prompted)
1. Prompts for folder name for folder creation. If a folder already exists that you want to use, enter that folder's name
2. Asks if you want to include the OneDrive folder in the query
3. Presents three options that you can interact with using the specified buttons as input (P for PDF, X for XLSX, T for TXT) and then it will search the user profile directory for all files of the specified type.
4. Script will then ask if you want to copy these files to a centralized location, and then will list the files that copied before copying them, and list the directory contents after copying for verification, then it will ask if you want to scrub the original files.

The second part is a new addition that allows you to select a folder from a Windows folder menu that will then search for and delete files older than an amount of days specified by the user.

Steps (Enter "delete" when prompted")
1. Asks how many days old files you want to get rid of
2. Opens the folder dialog box so you can select a folder
3. Will prompt for a yes or no if you want to delete files (after listing the files to be deleted
4. Deletes files, lists files and then outputs a report of deleted files to a text file
