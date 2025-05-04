#!/bin/bash

weburl="https://github.com/jamf/PPPC-Utility/releases/download/1.5.0/PPPC-Utility.zip"

# Download the file
echo "Downloading PPPC-Utility..."
if ! curl -f -s --connect-timeout 30 --retry 5 --retry-delay 60 -L -J -O "$weburl"; then
    echo "Error: Failed to download PPPC-Utility.zip" >&2
    exit 1
fi

# Unzip the file
echo "Unzipping PPPC-Utility.zip..."
if ! unzip -o PPPC-Utility.zip; then
    echo "Error: Failed to unzip PPPC-Utility.zip" >&2
    exit 1
fi

# Move the application to /Applications
echo "Moving PPPC-Utility.app to /Applications..."
if ! mv PPPC-Utility.app /Applications/PPPC-Utility.app; then
    echo "Error: Failed to move PPPC-Utility.app to /Applications" >&2
    exit 1
fi

echo "PPPC-Utility installed successfully."
