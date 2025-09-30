@echo off
setlocal enabledelayedexpansion

echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

REM Check if PowerShell 7 is installed
echo Before pwsh version check
pwsh --version >nul 2>&1
echo After pwsh version check
if errorlevel 1 (
    echo PowerShell 7 not found
    set PS_COMMAND=powershell
) else (
    echo Using PowerShell 7
    set PS_COMMAND=pwsh
)
echo PS command set

echo Test completed successfully
pause