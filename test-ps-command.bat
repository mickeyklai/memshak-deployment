@echo off
echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

REM Check if PowerShell 7 is installed
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: PowerShell 7 not found, trying Windows PowerShell...
    set PS_COMMAND=powershell
) else (
    echo Using PowerShell 7
    set PS_COMMAND=pwsh
)

echo PS_COMMAND is set to: %PS_COMMAND%

REM Test the PowerShell command
echo About to run: %PS_COMMAND% -ExecutionPolicy Bypass -File cert-detect-display.ps1
echo Test completed
pause