# PowerShell script for downloading Tesseract OCR for Windows

Write-Host "Starting download of Tesseract OCR for Windows..." -ForegroundColor Yellow

# Creating directories
$binDir = ".\bin\windows"
$tessdataDir = "$binDir\tessdata"

if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force
}

if (!(Test-Path $tessdataDir)) {
    New-Item -ItemType Directory -Path $tessdataDir -Force
}

# URL for download
$tesseractUrl = "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-5.5.0.20231217.exe"
$tesseractInstaller = ".\tesseract-installer.exe"

# Downloading installer
Write-Host "Downloading Tesseract installer..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $tesseractUrl -OutFile $tesseractInstaller

# Checking if 7-Zip exists
$7zipPath = "C:\Program Files\7-Zip\7z.exe"
if (!(Test-Path $7zipPath)) {
    Write-Host "7-Zip not found. Please install 7-Zip:" -ForegroundColor Red
    Write-Host "https://www.7-zip.org/download.html" -ForegroundColor Cyan
    exit 1
}

# Extracting files from the installer (it's a self-extracting archive)
Write-Host "Extracting files from installer..." -ForegroundColor Yellow
& $7zipPath x -o".\tesseract_temp" $tesseractInstaller

# Copying necessary files to the binary directory
Write-Host "Copying files to plugin directory..." -ForegroundColor Yellow

# Copying tesseract.exe and DLL files
Copy-Item ".\tesseract_temp\tesseract-ocr\tesseract.exe" -Destination "$binDir\"
Copy-Item ".\tesseract_temp\tesseract-ocr\*.dll" -Destination "$binDir\"

# Copying language data
Copy-Item ".\tesseract_temp\tesseract-ocr\tessdata\eng.traineddata" -Destination "$tessdataDir\" -ErrorAction SilentlyContinue
Copy-Item ".\tesseract_temp\tesseract-ocr\tessdata\rus.traineddata" -Destination "$tessdataDir\" -ErrorAction SilentlyContinue

# Checking for language data and additional download if necessary
if (!(Test-Path "$tessdataDir\eng.traineddata")) {
    Write-Host "English language file not found in installer. Downloading from GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata" -OutFile "$tessdataDir\eng.traineddata"
}

if (!(Test-Path "$tessdataDir\rus.traineddata")) {
    Write-Host "Russian language file not found in installer. Downloading from GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata" -OutFile "$tessdataDir\rus.traineddata"
}

# Creating wrapper script for running tesseract with correct paths
$wrapperContent = @"
@echo off
set SCRIPT_DIR=%~dp0
set TESSDATA_PREFIX=%SCRIPT_DIR%tessdata
"%SCRIPT_DIR%tesseract.exe" %*
"@

$wrapperContent | Out-File -FilePath "$binDir\run_tesseract.bat" -Encoding ascii

# Cleaning up temporary files
Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
Remove-Item -Path $tesseractInstaller -Force
Remove-Item -Path ".\tesseract_temp" -Recurse -Force

Write-Host "Download completed successfully!" -ForegroundColor Green
Write-Host "Binary files are available in $binDir directory" -ForegroundColor Green
Write-Host "To use Tesseract in the plugin, call $binDir\run_tesseract.bat" -ForegroundColor Yellow