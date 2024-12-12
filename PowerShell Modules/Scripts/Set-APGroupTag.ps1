function Set-APGroupTag {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$SerialNumber,
        [string]$GroupTag
    )
    BEGIN {
        $context = Get-MgContext
        if (-not $context) {
            Connect-MgGraph
        }
        if (-not $apDevices) {
            $apDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
        }
    }

    PROCESS {
        $HashID = $apDevices.Where({ $_.SerialNumber -eq $SerialNumber }).ID
        if ($PSCmdlet.ShouldProcess("Device with Serial Number $SerialNumber", "Update Group Tag to $GroupTag")) {
            try {
                Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $HashID -GroupTag $GroupTag -ErrorAction Stop
                Write-Verbose -Message "Group Tag successfully updated. Allow 5-10 minutes for changes to reflect" 
            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }
}