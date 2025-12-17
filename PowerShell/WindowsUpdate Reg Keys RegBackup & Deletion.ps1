# Requires TOOL - Check WindowsUpdate Reg Keys(.JSON Backup) to have been ran already
# Created by Mason Cushing
# On 8-6-2025

# Load unexpected keys
$jsonPath = "C:\RegistryBackups\UnexpectedKeys.json"
if (!(Test-Path $jsonPath)) {
    Write-Error "Unexpected key list not found: $jsonPath"
    exit
}

$unexpectedKeys = Get-Content $jsonPath | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "C:\RegistryBackups\Backups_$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

foreach ($entry in $unexpectedKeys) {
    $regPath = $entry.Path
    $keyName = $entry.Key

    Write-Output "Processing $keyName in $regPath"

    # Backup using PowerShell (export key and value to file)
    try {
        $value = Get-ItemPropertyValue -Path $regPath -Name $keyName
        $backupObject = [PSCustomObject]@{
            Path  = $regPath
            Key   = $keyName
            Value = $value
        }

        $safeFileName = ($regPath -replace '[\\:\*?\"<>|]', '_') + "_$keyName.json"
        $backupFile = Join-Path $backupDir $safeFileName
        $backupObject | ConvertTo-Json -Depth 3 | Set-Content -Path $backupFile

        Write-Output "✔ Backup saved: $backupFile"
    } catch {
        Write-Warning "✖ Failed to backup $keyName in ${regPath}: $_"
        continue
    }

    # Delete the registry value
    try {
        Remove-ItemProperty -Path $regPath -Name $keyName -Force
        Write-Output "✔ Deleted $keyName from $regPath"
    } catch {
        Write-Warning "✖ Failed to delete $keyName: ${_}"
    }
}
