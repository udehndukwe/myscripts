$regpath = "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot"

$value = Get-ItemProperty -Path $regpath -Name CloudAssignedTenantId

if ($value.CloudAssignedTenantId -ne "6d798b83-1769-4a29-9f77-8b9fae1560df") {
    Write-Output "Not AP Registered"
    exit 1
}
else {
    Write-Output "AP Registered"
    exit 0
}