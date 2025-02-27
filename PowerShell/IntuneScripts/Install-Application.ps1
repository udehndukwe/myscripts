function Install-Application {
    param (
        [string]$PackageName
    )
    # Install the application
    choco install $PackageName --acceptlicense --yes
}

Install-Application -PackageName $PackageName