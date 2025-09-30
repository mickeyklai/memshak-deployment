@echo off
setlocal enabledelayedexpansion

echo ====================================
echo   PowerShell Authentication Server
echo ====================================
echo.

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
    set "PS_COMMAND=powershell"
) else (
    echo Using PowerShell 7
    set "PS_COMMAND=pwsh"
)

REM Always attempt auto-detect unless user sets SKIP_AUTO_CERT=1
if not "%SKIP_AUTO_CERT%"=="1" (
    echo.
    echo Running automatic certificate detection...
    echo Looking for PersonalID certificates with accessible private keys...
    echo.
    REM Clear variable first
    set "AUTO_CERT="

    REM Use PowerShell to emit only the last (thumbprint) line of the script's stdout
    for /f "usebackq delims=" %%i in (`!PS_COMMAND! -ExecutionPolicy Bypass -Command "(& '%~dp0detect-certificate-auto.ps1') 2^>$null | Select-Object -Last 1"`) do set "AUTO_CERT=%%i"

    REM Basic trim (remove surrounding quotes/spaces if any)
    for /f "tokens=*" %%i in ("!AUTO_CERT!") do set "AUTO_CERT=%%~i"

    REM Validate the captured result
    REM (Optional) Uncomment for debugging:
    REM echo Detected result: !AUTO_CERT!
    
    REM Determine if AUTO_CERT looks like a hex thumbprint (40+ hex chars typical for SHA1)
    set "_IS_HEX=0"
    echo !AUTO_CERT!| findstr /R /I "^[0-9A-F][0-9A-F][0-9A-F][0-9A-F]" >nul && (
        for /f "delims=" %%H in ("!AUTO_CERT!") do (
            set "_LEN=0"
            for /l %%L in (1,1,64) do if not "!AUTO_CERT:~%%L,1!"=="" set /a _LEN+=1
        )
    )
    REM Simple length threshold (>= 32) and hex-only check
    echo !AUTO_CERT!| findstr /R /I "^[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F].*$" >nul && set "_MAYBE_HEX=1"
    for /f "delims=0123456789ABCDEFabcdef" %%X in ("!AUTO_CERT!") do set "_HAS_NON_HEX=1"
    if not defined _HAS_NON_HEX if defined _MAYBE_HEX set "_IS_HEX=1"

    if "!_IS_HEX!"=="1" goto :CERT_SUCCESS
    if /I "!AUTO_CERT!"=="NO_CERTIFICATES_FOUND" goto :CERT_NONE
    if /I "!AUTO_CERT!"=="DETECTION_ERROR" goto :CERT_ERROR
    if not "!AUTO_CERT!"=="" goto :CERT_UNEXPECTED
    goto :CERT_UNEXPECTED
    echo.
)

goto :AFTER_DETECT

:CERT_SUCCESS
    set "CERT_THUMBPRINT=!AUTO_CERT!"
    echo.
    echo SUCCESS: Automatically selected certificate !CERT_THUMBPRINT!
    setx CERT_THUMBPRINT "!CERT_THUMBPRINT!" >nul 2>&1
    if !errorlevel! equ 0 echo Environment variable set for future sessions
    set "_MAYBE_HEX=" & set "_HAS_NON_HEX=" & set "_IS_HEX="
    goto :AFTER_DETECT

:CERT_NONE
    echo.
    echo ERROR: No PersonalID certificates found with accessible private keys
    echo Please verify device connection and try again.
    pause & exit /b 1

:CERT_ERROR
    echo.
    echo ERROR: Certificate detection encountered an error (device / provider issue)
    echo Try reconnecting the device or running detect-certificate.bat
    pause & exit /b 1

:CERT_UNEXPECTED
    echo.
    echo ERROR: Unexpected detection output: "!AUTO_CERT!"
    pause & exit /b 1

:AFTER_DETECT

echo.
echo Final Certificate Thumbprint: !CERT_THUMBPRINT!
if "!CERT_THUMBPRINT!"=="" (
    echo ERROR: CERT_THUMBPRINT not set. Cannot start server.
    pause
    exit /b 1
)
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

!PS_COMMAND! -ExecutionPolicy Bypass -File host-auth-server.ps1