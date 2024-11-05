function New-DiagnosticReportRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SerialNumber,
        [object]$ManagedDeviceID
    )
    if ($SerialNumber) {
        foreach ($serial in $SerialNumber) {
            $ManagedDeviceEndpoint = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$Serial'"
            Invoke-MgGraphRequest -Method GET -Uri $ManagedDeviceEndpoint | Select -ExpandProperty Value | Select -expand Id
        }
        $CollectionEndpoint = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$DeviceID')/createDeviceLogCollectionRequest"
    }

    if ($ManagedDeviceID) {
        foreach ($ID in $ManagedDeviceID) {
            $CollectionEndpoint = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ID')/createDeviceLogCollectionRequest"
            Invoke-MgGraphRequest -Method POST -Uri $CollectionEndpoint
        }
    }   
}

function Get-IntuneConfigurationReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $PolicyID
    )

    Import-Module Microsoft.Graph.Beta.DeviceManagement.Actions

    $params = @{
        select  = @(
            "DeviceName"
            "UPN"
            "ReportStatus"
            "AssignmentFilterIds"
            "PspdpuLastModifiedTimeUtc"
            "IntuneDeviceId"
            "UnifiedPolicyPlatformType"
            "UserId"
            "PolicyStatus"
            "PolicyBaseTypeName"
        )
        skip    = 0
        top     = 50
        filter  = "((PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceConfiguration') or (PolicyBaseTypeName eq 'DeviceManagementConfigurationPolicy') or (PolicyBaseTypeName eq 'DeviceConfigurationAdmxPolicy')) and (PolicyId eq '$PolicyID')"
        orderBy = @(
        )
    }
    
    Get-MgBetaDeviceManagementReportConfigurationPolicyDeviceReport -BodyParameter $params -OutFile test.json
    
    
    # Load the JSON content from the file
    $jsonContent = Get-Content -Path ".\test.json" -Raw | ConvertFrom-Json
    $jsonContent = $jsonContent.Values
    
    $table = foreach ($item in $jsonContent) {
        $DeviceName = $item[1]
        $ManagedDeviceID = $item[2]
        $Date = $item[5]
        $User = $item[10]
        $Status = $item[6]
    
        [PSCustomObject]@{
            DeviceName      = $DeviceName
            ManagedDeviceID = $ManagedDeviceID
            Date            = $Date
            User            = $User
            Status          = $Status
        }
    }
    
    $table
    

}