# Installs Office 2021 Perpetual License 
# Created by Mason Cushing
# Created on 5-20-2025

# Define download URL and paths
$downloadUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18623-20156.exe"
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$targetFolder = Join-Path $documentsPath "ConfigFolder"
$exePath = Join-Path $targetFolder "officedeploymenttool.exe"
$xmlPath = Join-Path $targetFolder "config.xml"

# Create target folder if it doesn't exist
New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null

# Download the Office Deployment Tool EXE
Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath

# Extract the EXE silently to the folder
Start-Process -FilePath $exePath -ArgumentList "/quiet", "/extract:`"$targetFolder`"" -Wait

# OPTIONAL: Delete the EXE after extraction
Remove-Item $exePath -Force

# Create a basic Office configuration XML file (Replace the configuration ID and PIDKEY with the one were provided)
$xmlContent = @"
<Configuration ID="************">
  <Add OfficeClientEdition="64" Channel="PerpetualVL2021">
    <Product ID="standard2021Volume" PIDKEY="*********************************>
      <Language ID="MatchOS" />
      <ExcludeApp ID="Lync" />
    </Product>
  </Add>
  <Remove All="TRUE" />
  <RemoveMSI />
</Configuration>
"@

# Save the XML file
$xmlContent | Out-File -FilePath $xmlPath -Encoding UTF8

Write-Host "✅ Office Deployment Tool extracted and config.xml created in: $targetFolder"

# Define setup.exe path
$setupPath = Join-Path $targetFolder "setup.exe"

# Run: setup /download config.xml
Write-Host "📥 Starting Office files download..."
Start-Process -FilePath $setupPath -ArgumentList "/download config.xml" -Wait

# Run: setup /configure config.xml
Write-Host "⚙️ Starting Office installation..."
Start-Process -FilePath $setupPath -ArgumentList "/configure config.xml" -Wait

Write-Host "✅ Office installation process completed."