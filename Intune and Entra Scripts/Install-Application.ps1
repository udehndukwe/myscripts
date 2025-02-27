# Install script that uses Chocolatey. Provide package name to install the application.

function Install-Application {
    param (
        [string]$PackageName
    )
    # Install the application
    choco install $PackageName --acceptlicense --yes
}

Install-Application -PackageName $PackageName