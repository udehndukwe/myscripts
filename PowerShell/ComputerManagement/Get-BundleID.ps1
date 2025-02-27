## Gets Bundle ID of an application on macOS devices

function Get-BundleID {
   [CmdletBinding()]
   param (
       [Parameter()]
       [string]$Path,
       [string]$Value
   )


   $item = Get-ChildItem /Applications "*$value*"
   $path = $item.FullName
   $result = codesign -dr - $path

   Se

}

Get-BundleID -Value $Value