$cim = Get-CimInstance -Class Win32_Product | Where Name -like "*Powershell*"
$hash = @{"Vendor" = $cim.Vendor; "Version" = $cim.Version; "Name" = $cim.Name }
return $hash | ConvertTo-Json -Compress