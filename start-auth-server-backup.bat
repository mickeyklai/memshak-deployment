@echo off
setlocal enabledelayedexpansion
REM Start PowerShell HTTP Authentication Server
REM Clean architecture without Node.js dependencies

echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

REM Check if PowerShell 7 is installed
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: PowerShell 7 not found, trying Windows PowerShell...
    powershell -Command "Get-Host | Select-Object Version"
    if errorlevel 1 (
        echo ERROR: No PowerShell installation found
        echo Please install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases
        pause
        exit /b 1
    )
    echo Using Windows PowerShell (legacy)
    set PS_COMMAND=powershell
) else (
    echo Using PowerShell 7
    set PS_COMMAND=pwsh
)

REM Check if certificate thumbprint is set, if not try to detect it automatically
if not defined CERT_THUMBPRINT (
    echo Certificate thumbprint not set, attempting automatic detection...
    echo Looking for PersonalID certificates with accessible private keys (USB device must be inserted)...
    echo.
    
    REM Display certificate information with online key testing
    %PS_COMMAND% -ExecutionPolicy Bypass -File cert-detect-display.ps1
    
    REM Get just the thumbprint
    for /f "delims=" %%i in ('%PS_COMMAND% -ExecutionPolicy Bypass -File cert-detect-thumbprint.ps1') do (
        set "CERT_THUMBPRINT=%%i"
    )
    
    if "%CERT_THUMBPRINT%"=="NO_ONLINE_CERTIFICATES_FOUND" (
        echo ERROR: No PersonalID certificates found with accessible private keys
        echo.
        echo Please ensure your Bituach Leumi certificate device is working properly:
        echo   1. Connect your Bituach Leumi USB certificate device
        echo   2. Ensure the device is properly recognized (check Device Manager)
        echo   3. Verify the PersonalID certificate is installed in Windows Certificate Store
        echo   4. Make sure the certificate has "Client Authentication" or "Smart Card Log-on" capability
        echo   5. Try removing and reconnecting the USB device
        echo.
        echo You can also run detect-certificate.bat for detailed detection and troubleshooting
        echo.
        set /p CERT_THUMBPRINT=Enter your certificate thumbprint manually: 
        if "%CERT_THUMBPRINT%"=="" (
            echo ERROR: Certificate thumbprint is required
            pause
            exit /b 1
        )
    ) else (
        echo SUCCESS: Successfully auto-detected PersonalID certificate with accessible private key!
        echo Certificate Thumbprint: %CERT_THUMBPRINT%
        
        REM Set system environment variable for future sessions
        setx CERT_THUMBPRINT "%CERT_THUMBPRINT%" >nul
        echo Environment variable set for future sessions
        
        REM Certificate details are already shown by the PowerShell script above
    )
)

echo.
echo Final Certificate Thumbprint: %CERT_THUMBPRINT%
echo.

REM Start the PowerShell HTTP server
echo Starting PowerShell HTTP Authentication Server...
echo.
echo The server will run on http://127.0.0.1:8888
echo.
echo Available endpoints:
echo   GET  /health - Health check
echo   POST /auth   - Certificate authentication
echo.
echo Press Ctrl+C to stop the server
echo.

%PS_COMMAND% -ExecutionPolicy Bypass -File host-auth-server.ps1