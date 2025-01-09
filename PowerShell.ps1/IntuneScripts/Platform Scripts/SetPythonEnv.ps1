# Path to the Python installation directory
$pythonPath = "C:\Program Files\Python311\python.exe" # Change this to your actual Python installation path

# Get the current PATH environment variable
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Check if Python path is already in the PATH environment variable
if ($currentPath -notlike "*$pythonPath*") {
    # Add Python path to the PATH environment variable
    $newPath = "$currentPath;$pythonPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Python path added to the system PATH environment variable."
}
else {
    Write-Output "Python path is already in the system PATH environment variable."
}

# To reflect the changes, you might need to restart your session or machine.
