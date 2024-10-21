if ($regkeys.AutoAdminLogon -ne 1 -and $regkeys.DefaultUserName -ne "kioskUser0" -and $regkeys.isConnectedAutoLogon -ne 0) {
    Write-Output "Autologon keys are not set to proper values"
} 