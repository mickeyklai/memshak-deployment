@echo off
setlocal enabledelayedexpansion

echo ====================================
echo   PowerShell Authentication Server  
echo ====================================
echo.

pwsh --version >nul 2>&1
if errorlevel 1 (
    echo Using Windows PowerShell
    set "PS_COMMAND=powershell"
) else (
    echo Using PowerShell 7
    set "PS_COMMAND=pwsh"
)

if not defined CERT_THUMBPRINT (
    echo Certificate not set, detecting...
    
    echo Running: !PS_COMMAND! -ExecutionPolicy Bypass -File cert-detect-display.ps1
    !PS_COMMAND! -ExecutionPolicy Bypass -File cert-detect-display.ps1
    
    echo Getting thumbprint...
    for /f "tokens=*" %%i in ('!PS_COMMAND! -ExecutionPolicy Bypass -File cert-detect-thumbprint.ps1') do set "CERT_THUMBPRINT=%%i"
    
    if "!CERT_THUMBPRINT!"=="NO_ONLINE_CERTIFICATES_FOUND" (
        echo ERROR: No certificates found
        set /p "CERT_THUMBPRINT=Enter thumbprint manually: "
        if "!CERT_THUMBPRINT!"=="" (
            echo ERROR: Thumbprint required
            pause
            exit /b 1
        )
    ) else (
        echo SUCCESS: Found certificate !CERT_THUMBPRINT!
        setx CERT_THUMBPRINT "!CERT_THUMBPRINT!" >nul 2>&1
    )
)

echo.
echo Final thumbprint: !CERT_THUMBPRINT!
echo.
echo Starting server...
!PS_COMMAND! -ExecutionPolicy Bypass -File host-auth-server.ps1