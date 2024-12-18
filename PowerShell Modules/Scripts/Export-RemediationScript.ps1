<#
.SYNOPSIS
    Exports remediation and detection scripts from Intune.

.DESCRIPTION
    This function exports remediation and detection scripts from Intune using their script IDs.

.PARAMETER scriptID
    The IDs of the scripts to export.

.EXAMPLE
    Export-RemediationScript -scriptID "script1", "script2"

.NOTES
    Author: Udeh Ndukwe
    Date: 10/10/2023
#>
function Export-RemediationScript {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$scriptID
    )

    PROCESS {
        foreach ($id in $scriptID) {
            #SET URI
            $URI2 = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/{$id}?$select=remediationScriptContent,detectionScriptContent"
            #Export detection Script
            $value = Invoke-MgGraphRequest -Uri $URI2 -Method GET
            ##Get script content (encoded)
            $detectionScriptContent = $value | Select-Object -expand detectionScriptContent
            $remediationScriptContent = $value | Select-Object -expand remediationScriptContent
            ##Decode script content
            $decodedDetection = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($detectionScriptContent))
            $decodedRemediation = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($remediationScriptContent))
            ##Set filename
            $foldername = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "")
            try {
                $path = New-Item -Path $env:USERPROFILE\$foldername -ItemType Directory -ErrorAction Stop
            }
            catch {
                $path = Get-Item $env:USERPROFILE\$foldername
            }
            $detectionFilename = $value.displayName.replace(" ", "").Replace("\", "").Replace("/", "") + "Remediation.ps1"
            $remediationFileName = $value.displayName.replace(" ", "").Replace("/", "") + "_Detection.ps1"
            ##Export filename
            $decodedDetection | Out-File -FilePath "$env:USERPROFILE\$foldername\$detectionFilename"
            Write-Verbose -Message "$detectionFilename has been exported successfully to: $($path)"
            
            $decodedRemediation | Out-File "$env:USERPROFILE\$foldername\$remediationFileName"
            Write-Verbose -Message "$remediationFileName has been exported successfully to: $($path)"

        }
    }

}