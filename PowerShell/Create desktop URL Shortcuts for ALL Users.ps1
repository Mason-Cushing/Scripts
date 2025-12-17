#Created by Mason Cushing
#Created on 4-7-25

# Define the URL and shortcut name
$websiteURL = "*****"
$shortcutName = "*****"

# Get all user profiles from C:\Users (excluding the default system profiles) NOTE: It may need to be modified to support users who only utilize desktop through OneDrive.
$userProfiles = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notin @("Default", "Public", "All Users") }

# Loop through each user profile
foreach ($user in $userProfiles) {
    $desktopPath = "C:\Users\$($user.Name)\Desktop"
    
    # Check if the Desktop folder exists, if not, create it
    if (-not (Test-Path $desktopPath)) {
        # Create the Desktop folder if it doesn't exist
        New-Item -Path $desktopPath -ItemType Directory
    }
    
    # Define the path to the shortcut file
    $shortcutPath = "$desktopPath\$shortcutName.url"

    # Create the .url shortcut file content
    $urlContent = @"
    [InternetShortcut] 
    URL=$websiteURL
"@

    # Write the content to the shortcut file
    $urlContent | Out-File -FilePath $shortcutPath -Encoding ASCII
}

Write-Host "URL shortcuts have been created on user desktops."
