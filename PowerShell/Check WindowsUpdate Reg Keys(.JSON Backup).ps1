# Created by Mason Cushing
# On 6-26-2025

# Define the registry paths
$pathsToCheck = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
)

# Define expected keys per path
$expectedKeysMap = @{
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" = @()
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" = @("NoAutoUpdate", "AUOptions")
}

# Store unexpected keys
$unexpectedKeysList = @()

foreach ($path in $pathsToCheck) {
    Write-Output "`nChecking: $path"

    if (Test-Path $path) {
        try {
            $regProps = Get-ItemProperty -Path $path
            $actualKeys = $regProps.PSObject.Properties | Where-Object {
                $_.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")
            } | Select-Object -ExpandProperty Name

            $expectedKeys = $expectedKeysMap[$path]
            $unexpectedKeys = $actualKeys | Where-Object { $_ -notin $expectedKeys }

            if ($unexpectedKeys.Count -gt 0) {
                Write-Output "Unexpected keys found:"
                foreach ($key in $unexpectedKeys) {
                    Write-Output " - $key"

                    $unexpectedKeysList += [PSCustomObject]@{
                        Path = $path
                        Key  = $key
                    }
                }
            } else {
                Write-Output "No unexpected keys. Only expected values found."
            }
        } catch {
            Write-Output "Error reading $path $_"
        }
    } else {
        Write-Output "Registry path not found: $path"
    }
}

# Save unexpected keys list to JSON for the backup/removal script
$outputPath = "C:\RegistryBackups\UnexpectedKeys.json"
$outputFolder = Split-Path $outputPath
if (!(Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}
$unexpectedKeysList | ConvertTo-Json -Depth 3 | Set-Content -Path $outputPath

Write-Output "`nSaved unexpected key list to: $outputPath"

# Output summary and update NinjaRMM custom fields
Write-Output "`n--- Summary of Unexpected Keys ---"

# Group and count unexpected keys by registry path
$unexpectedKeyCounts = $unexpectedKeysList |
    Group-Object -Property Path |
    ForEach-Object {
        [PSCustomObject]@{
            Path  = $_.Name
            Count = [int]$_.Count
        }
    }

foreach ($entry in $unexpectedKeyCounts) {
    Write-Output "$($entry.Path): $($entry.Count)"

    switch ($entry.Path) {
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" {
            Ninja-Property-Set UnexpectedWindowsUpdateKeys $entry.Count | Out-Null
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" {
            Ninja-Property-Set UnexpectedAUKeys $entry.Count | Out-Null
        }
    }
}
