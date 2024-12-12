function Clear-ApHash {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Id,
        [string]$SerialNumber
    )
    begin {
        if ($SerialNumber) {
            $hashes = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        }
    }
    process {
        if ($SerialNumber) {
            $Id = $hashes | Where-Object { $_.serialNumber -eq $SerialNumber } | Select-Object -ExpandProperty id
            if ($PSCmdlet.ShouldProcess("Device with ID $Id", "Remove")) {
                Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Device with ID $Id", "Remove")) {
                Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Id
            }
        }
    }
}