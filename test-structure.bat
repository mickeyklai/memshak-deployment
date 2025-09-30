@echo off
setlocal enabledelayedexpansion

echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

pwsh --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: PowerShell 7 not found, trying Windows PowerShell...
    set "PS_COMMAND=powershell"
) else (
    echo Using PowerShell 7
    set "PS_COMMAND=pwsh"
)

if not defined CERT_THUMBPRINT (
    echo Certificate thumbprint not set
    echo Would detect certificate here
    set "CERT_THUMBPRINT=TEST123"
)

echo Final Certificate Thumbprint: !CERT_THUMBPRINT!
echo Starting server...
echo Would start: !PS_COMMAND! -ExecutionPolicy Bypass -File host-auth-server.ps1
echo Done
pause