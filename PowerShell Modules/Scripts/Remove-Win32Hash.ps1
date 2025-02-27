function Remove-Win32Hash {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $appId
    )

   
    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName
    $regpath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\b400d43b-687e-4adc-8c21-2d2dac338aa1\GRS\"
    if (!$intuneLogList) {
        Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\]\[GRSManager\] App with id: $appId is not expired." -Context 0, 1
        if ($appMatch) {
            foreach ($match in $appMatch) {
                $Hash = '“”'
                $LineNumber = 0
                $LineNumber = $match.LineNumber
                $Hash = Get-Content -Path $intuneLog | Select-Object -Skip $LineNumber -First 1
                if ($hash) {
                    $hash = $hash.Replace("Hash = ", "")
                }
            }
        }
    }

    if ($PSCmdlet.ShouldProcess("Registry path $regpath\$Hash", "Remove")) {
        #Remove folder that matches hash name from registry
        Remove-Item -Recurse -Force -Path $regpath\$Hash

        Write-Verbose "Restarting IntuneManagementExtension service" -Verbose

        Restart-Service -Name IntuneManagementExtension
    }
}