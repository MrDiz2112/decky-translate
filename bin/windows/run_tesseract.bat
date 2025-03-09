@echo off
set SCRIPT_DIR=%~dp0
set TESSDATA_PREFIX=%SCRIPT_DIR%tessdata
"%SCRIPT_DIR%tesseract.exe" %*
