@echo off
REM Memshak Authentication Server Startup Script
REM Starts the PowerShell authentication server with certificate auto-detection

setlocal enabledelayedexpansion

echo ================================================
echo    MEMSHAK AUTHENTICATION SERVER
echo ================================================
echo.

REM Check if PowerShell 7 is available
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell 7 is required but not found
    echo Please install PowerShell 7 from: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
    pause
    exit /b 1
)

echo Detecting certificate configuration...

REM Auto-detect certificate if not set
if not defined CERT_THUMBPRINT (
    echo CERT_THUMBPRINT not set, attempting auto-detection...
    
    REM Run certificate detection
    pwsh -Command "& { try { Write-Host 'Searching for Bituach Leumi certificate in Cert:\LocalMachine\My...'; $certs = Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.Subject -match 'CN=' -and $_.HasPrivateKey -eq $true -and $_.NotAfter -gt (Get-Date) }; if ($certs.Count -eq 0) { Write-Host 'No valid certificates with private keys found in LocalMachine\My store'; exit 1 }; $selectedCert = $certs | Sort-Object NotAfter -Descending | Select-Object -First 1; Write-Host \"Auto-detected certificate: $($selectedCert.Subject)\"; Write-Host \"Thumbprint: $($selectedCert.Thumbprint)\"; Write-Host \"Expires: $($selectedCert.NotAfter)\"; $selectedCert.Thumbprint } catch { Write-Host 'Certificate detection failed:' $_.Exception.Message; exit 1 } }" > "%TEMP%\cert_thumbprint.txt" 2>nul
    
    if exist "%TEMP%\cert_thumbprint.txt" (
        for /f "delims=" %%i in ('type "%TEMP%\cert_thumbprint.txt"') do (
            if not "%%i"=="" if not "%%i"=="Auto-detected certificate:" if not "%%i"=="Thumbprint:" if not "%%i"=="Expires:" (
                set "DETECTED_THUMBPRINT=%%i"
            )
        )
        del "%TEMP%\cert_thumbprint.txt" >nul 2>&1
        
        if not "!DETECTED_THUMBPRINT!"=="" (
            set "CERT_THUMBPRINT=!DETECTED_THUMBPRINT!"
            echo Successfully auto-detected certificate: !DETECTED_THUMBPRINT!
        ) else (
            echo Certificate auto-detection failed
            goto :manual_entry
        )
    ) else (
        echo Certificate auto-detection failed
        goto :manual_entry
    )
) else (
    echo Using configured certificate: %CERT_THUMBPRINT%
)

goto :start_server

:manual_entry
echo.
echo Please enter your Bituach Leumi certificate thumbprint:
echo (You can find this in Windows Certificate Manager or by running detect-certificate.bat)
set /p CERT_THUMBPRINT="Certificate thumbprint: "

if "%CERT_THUMBPRINT%"=="" (
    echo ERROR: Certificate thumbprint is required
    pause
    exit /b 1
)

:start_server
echo.
echo Starting PowerShell authentication server...
echo Certificate: %CERT_THUMBPRINT%
echo Server URL: http://localhost:8888
echo.
echo Available endpoints:
echo   GET  /health - Health check
echo   POST /auth   - Certificate authentication
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the PowerShell HTTP server
pwsh -ExecutionPolicy Bypass -File "host-auth-server.ps1" -Port 8888 -AuthScriptPath "auth.ps1"

if errorlevel 1 (
    echo.
    echo ERROR: Authentication server failed to start
    echo Please check:
    echo   1. Certificate is installed and accessible
    echo   2. PowerShell 7 is properly installed
    echo   3. Port 8888 is not in use by another application
    echo   4. auth.ps1 script is present
    pause
)

echo.
echo Authentication server stopped
pause
