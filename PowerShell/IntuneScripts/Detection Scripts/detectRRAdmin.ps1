$account = Get-LocalGroupMember -Group "Administrators" -Member "RRADMIN"

if ($account) {
    Write-Output "RRADMIN account detected"
    exit 1
}
else {
    Write-Output "RRADMIN account not detected"
    exit 0
}