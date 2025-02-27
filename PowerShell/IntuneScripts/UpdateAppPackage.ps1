$jsonData = @{
    "@odata.type" = "#microsoft.graph.win32LobApp"
    "displayName" = "PowerShell 7"
    "description" = "This is PowerShell 7"
    "publisher" = "Microsoft"
    "largeIcon" = @{
        "@odata.type" = "microsoft.graph.mimeContent"
        "type" = ""
        "value" = ""
    }
    "isFeatured" = $true
    "privacyInformationUrl" = "https://example.com/privacyInformationUrl/"
    "informationUrl" = "https://example.com/informationUrl/"
    "owner" = "Udeh Ndukwe"
    "developer" = "Microsoft"
    "notes" = "N/A"
    "publishingState" = "processing"
    "committedContentVersion" = "7.5.0"
    "fileName" = "$filename"
    "size" = 4
    "installCommandLine" = 'msiexec /i "PowerShell-7.5.0-win-x64.msi" /qn'
    "uninstallCommandLine" = 'msiexec /x "{D012DCD1-67EA-4627-938F-19FD677FC03A}" /qn'
    "applicableArchitectures" = "x64"
    "minimumFreeDiskSpaceInMB" = 8
    "minimumMemoryInMB" = 1
    "minimumNumberOfProcessors" = 9
    "minimumCpuSpeedInMHz" = 4
    "rules" = @(
        @{
            "@odata.type" = "#microsoft.graph.win32LobAppProductCodeRule"
            "ruleType" = "detection"
            "productCode" = "{046D50AC-89E4-4694-8701-5120BF24BA4C}"
            "productVersionOperator" = "notConfigured"
        }
    )
    "installExperience" = @{
        "@odata.type" = "microsoft.graph.win32LobAppInstallExperience"
        "runAsAccount" = "user"
        "deviceRestartBehavior" = "allow"
    }
    "returnCodes" = @(
        @{
            "@odata.type" = "microsoft.graph.win32LobAppReturnCode"
            "returnCode" = 0
            "type" = "success"
        }
    )
    "msiInformation" = @{
        "@odata.type" = "microsoft.graph.win32LobAppMsiInformation"
        "productCode" = "{D012DCD1-67EA-4627-938F-19FD677FC03A}"
        "productVersion" = "7.5.0.0"
        "upgradeCode" = "{31AB5147-9A97-4452-8443-D9709F0516E1}"
        "requiresReboot" = $false
        "packageType" = "perMachine"
        "productName" = "PowerShell 7-x64"
        "publisher" = "Microsoft Corporation"
    }
    "setupFilePath" = "PowerShell7.msi"
    "minimumSupportedWindowsRelease" = "Minimum Supported Windows Release value"
}

New-MgDeviceAppManagementMobileApp -BodyParameter $jsonData