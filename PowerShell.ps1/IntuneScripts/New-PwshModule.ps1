function New-PwshModule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name
    )
    BEGIN {
        $pwshModulePath = "C:\windows\system32\WindowsPowerShell\v1.0\Modules"
    }
    PROCESS {
        $module = New-PSModule -Name $Name
        Move-Item -Path $module.FullName -Destination $pwshModulePath
    }

}
