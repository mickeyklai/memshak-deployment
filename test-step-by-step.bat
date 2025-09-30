@echo off
setlocal enabledelayedexpansion

echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

REM Check if PowerShell 7 is installed
pwsh --version >nul 2>&1
if errorlevel 1 (
    set PS_COMMAND=powershell
) else (
    echo Using PowerShell 7
    set PS_COMMAND=pwsh
)

REM Check if certificate thumbprint is set
if not defined CERT_THUMBPRINT (
    echo Certificate thumbprint not set, attempting automatic detection...
    echo.
    
    REM Display certificate information
    echo Calling: !PS_COMMAND! -ExecutionPolicy Bypass -File cert-detect-display.ps1
    !PS_COMMAND! -ExecutionPolicy Bypass -File cert-detect-display.ps1
    echo Display completed
    
    pause
)