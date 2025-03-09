# PowerShell script for building and sending the plugin to Steam Deck
# without automatic installation

# Settings for Steam Deck connection
param (
    [string]$DeckIP = "192.168.1.100",  # Steam Deck IP address (can be passed as first argument)
    [string]$DeckUser = "deck",         # Username
    [string]$RemotePath = "/home/deck/_dev"  # Path on Steam Deck where to save the archive
)

# Plugin name (taken from package.json)
$PluginName = (Get-Content package.json | ConvertFrom-Json).name
$ArchiveName = "decky-translate.zip"
$DeployDir = "deploy"
$HomeDir = [Environment]::GetFolderPath("UserProfile")
$DevDir = Join-Path -Path $HomeDir -ChildPath "_dev"

# Create deploy directory if it doesn't exist
if (!(Test-Path $DeployDir)) {
    New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null
    Write-Host "Created deploy directory" -ForegroundColor Green
}

# Create _dev directory in user's home if it doesn't exist
if (!(Test-Path $DevDir)) {
    New-Item -ItemType Directory -Path $DevDir -Force | Out-Null
    Write-Host "Created _dev directory in user's home folder" -ForegroundColor Green
}

# Check if archive already exists and remove it
$ArchivePath = Join-Path -Path $DeployDir -ChildPath $ArchiveName
if (Test-Path $ArchivePath) {
    Remove-Item -Path $ArchivePath -Force
    Write-Host "Removed existing archive" -ForegroundColor Yellow
}

Write-Host "Building plugin for Decky Loader..." -ForegroundColor Yellow
# Ensure we have a clean build
if (Test-Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
}
pnpm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error building plugin!" -ForegroundColor Red
    exit 1
}

Write-Host "Creating plugin package structure..." -ForegroundColor Yellow
$TempDir = "build_tmp"
if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Recurse -Force
}

# Create proper Decky plugin structure
$PluginDir = "$TempDir/$PluginName"
New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null

# Copy required files
Write-Host "Copying files to package..." -ForegroundColor Yellow
Copy-Item -Path "dist" -Destination "$PluginDir/" -Recurse

# Create bin directory and copy Tesseract binaries
if (Test-Path "bin/steamos") {
    New-Item -ItemType Directory -Path "$PluginDir/bin" -Force | Out-Null
    Copy-Item -Path "bin/steamos" -Destination "$PluginDir/bin/" -Recurse
    Write-Host "SteamOS binaries copied to package" -ForegroundColor Green
} else {
    Write-Host "Warning: SteamOS binaries not found. Make sure to build them first." -ForegroundColor Yellow
    Write-Host "Run .\build_steamos.sh in Linux/WSL environment to build them." -ForegroundColor Yellow
}

# Copy other required files
Copy-Item -Path "plugin.json" -Destination "$PluginDir/"
Copy-Item -Path "package.json" -Destination "$PluginDir/"
Copy-Item -Path "main.py" -Destination "$PluginDir/"
Copy-Item -Path "LICENSE" -Destination "$PluginDir/"
Copy-Item -Path "requirements.txt" -Destination "$PluginDir/" -ErrorAction SilentlyContinue

# Check if all required files exist
$RequiredFiles = @("plugin.json", "package.json", "main.py", "LICENSE")
$MissingFiles = $false
foreach ($File in $RequiredFiles) {
    if (!(Test-Path "$PluginDir/$File")) {
        Write-Host "Error: Required file $File is missing from plugin package!" -ForegroundColor Red
        $MissingFiles = $true
    }
}
if ($MissingFiles) {
    Write-Host "Please ensure all required files are present in your project" -ForegroundColor Red
    exit 1
}

# Check if dist directory has content
if (!(Test-Path "$PluginDir/dist/*")) {
    Write-Host "Error: dist directory is empty! Build may have failed." -ForegroundColor Red
    exit 1
}

Write-Host "Creating plugin archive..." -ForegroundColor Yellow

# Create archive using 7-zip if available, otherwise use built-in
$CurrentDir = Get-Location
Set-Location $TempDir
if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
    & "C:\Program Files\7-Zip\7z.exe" a -tzip "../$DeployDir/$ArchiveName" "$PluginName" | Out-Null
} else {
    Compress-Archive -Path "$PluginName" -DestinationPath "../$DeployDir/$ArchiveName" -Force
}
Set-Location $CurrentDir

# Copy archive to _dev directory in user's home folder
Write-Host "Copying plugin archive to _dev directory..." -ForegroundColor Yellow
Copy-Item -Path "$DeployDir/$ArchiveName" -Destination "$DevDir/" -Force
Write-Host "Archive copied to $DevDir/$ArchiveName" -ForegroundColor Green

Write-Host "Copying plugin archive to Steam Deck..." -ForegroundColor Yellow
# Copy to Steam Deck using scp
scp "$DeployDir/$ArchiveName" "${DeckUser}@${DeckIP}:${RemotePath}/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error copying plugin to Steam Deck!" -ForegroundColor Red
    exit 1
}

Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "Plugin archive successfully created and sent to Steam Deck!" -ForegroundColor Green
Write-Host "Archive location on Steam Deck: ${RemotePath}/${ArchiveName}" -ForegroundColor Green
Write-Host "Local archive location: ${DeployDir}/${ArchiveName}" -ForegroundColor Green
Write-Host "Archive also copied to: ${DevDir}/${ArchiveName}" -ForegroundColor Green
Write-Host "Installation instructions:" -ForegroundColor Yellow
Write-Host "1. On your Steam Deck, press the ... button and open the QAM (Quick Access Menu)" -ForegroundColor Cyan
Write-Host "2. Find the Decky icon and open it" -ForegroundColor Cyan
Write-Host "3. Open the gear icon (Decky settings)" -ForegroundColor Cyan
Write-Host "4. Enable Developer Mode if not already enabled" -ForegroundColor Cyan
Write-Host "5. Select 'Install Plugin' and then 'From File'" -ForegroundColor Cyan
Write-Host "6. Navigate to $RemotePath and select ${ArchiveName}" -ForegroundColor Cyan
Write-Host "7. The plugin should install and appear in the plugins list" -ForegroundColor Cyan
Write-Host ""
Write-Host "To check logs if something goes wrong:" -ForegroundColor Yellow
Write-Host "  ssh $DeckUser@$DeckIP 'journalctl --user -u plugin_loader -f'" -ForegroundColor Cyan