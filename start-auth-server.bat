@echo off
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
    echo Looking for certificates from USB devices and smart cards only...
    echo.
    
    REM Create temporary PowerShell script for USB certificate detection
    echo $allCerts = @^(^) > usb-cert-temp.ps1
    echo $allCerts += Get-ChildItem -Path Cert:\CurrentUser\My -ErrorAction SilentlyContinue ^| Where-Object { $_.HasPrivateKey -eq $true -and $_.NotAfter -gt ^(Get-Date^) } >> usb-cert-temp.ps1
    echo $allCerts += Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue ^| Where-Object { $_.HasPrivateKey -eq $true -and $_.NotAfter -gt ^(Get-Date^) } >> usb-cert-temp.ps1
    echo $usbCerts = $allCerts ^| Where-Object { >> usb-cert-temp.ps1
    echo     $cert = $_ >> usb-cert-temp.ps1
    echo     $isFromUSB = $false >> usb-cert-temp.ps1
    echo     try { if ^($cert.PrivateKey.CspKeyContainerInfo.ProviderName -match 'Smart Card^|Card^|USB^|Token^|eToken^|SafeNet^|Gemalto'^) { $isFromUSB = $true } } catch { } >> usb-cert-temp.ps1
    echo     try { if ^($cert.PrivateKey.CspKeyContainerInfo.Removable -or $cert.PrivateKey.CspKeyContainerInfo.HardwareDevice^) { $isFromUSB = $true } } catch { } >> usb-cert-temp.ps1
    echo     try { if ^($cert.Subject -match 'CN=[0-9]{8,9}' -or $cert.Subject -match 'Israeli^|Israel^|IL=' -or $cert.Issuer -match 'Israeli^|Israel^|Ministry^|Gov'^) { $isFromUSB = $true } } catch { } >> usb-cert-temp.ps1
    echo     if ^($cert.Subject -match '^CN=localhost$' -and $cert.Issuer -match '^CN=localhost$'^) { $isFromUSB = $false } >> usb-cert-temp.ps1
    echo     return $isFromUSB >> usb-cert-temp.ps1
    echo } >> usb-cert-temp.ps1
    echo if ^($usbCerts.Count -gt 0^) { ^($usbCerts ^| Sort-Object NotAfter -Descending ^| Select-Object -First 1^).Thumbprint } else { 'NO_USB_CERTIFICATES_FOUND' } >> usb-cert-temp.ps1
    
    for /f "delims=" %%i in ('pwsh -ExecutionPolicy Bypass -File usb-cert-temp.ps1') do (
        set "CERT_THUMBPRINT=%%i"
    )
    
    del usb-cert-temp.ps1 >nul 2>&1
    
    if "%CERT_THUMBPRINT%"=="NO_USB_CERTIFICATES_FOUND" (
        echo ❌ No certificates from USB devices or smart cards found
        echo.
        echo Please ensure your Bituach Leumi certificate USB disk is connected
        echo and the certificate is properly installed in the Windows Certificate Store
        echo.
        echo You can also run detect-certificate.bat for detailed detection
        echo.
        set /p CERT_THUMBPRINT=Enter your certificate thumbprint manually: 
        if "%CERT_THUMBPRINT%"=="" (
            echo ERROR: Certificate thumbprint is required
            pause
            exit /b 1
        )
    ) else (
        echo ✅ Successfully auto-detected USB certificate!
        echo Certificate Thumbprint: %CERT_THUMBPRINT%
        
        REM Set system environment variable for future sessions
        setx CERT_THUMBPRINT "%CERT_THUMBPRINT%" >nul
        echo Environment variable set for future sessions
        
        REM Display certificate details
        pwsh -Command "$cert = Get-ChildItem -Path Cert:\CurrentUser\My\%CERT_THUMBPRINT% -ErrorAction SilentlyContinue; if (-not $cert) { $cert = Get-ChildItem -Path Cert:\LocalMachine\My\%CERT_THUMBPRINT% -ErrorAction SilentlyContinue } if ($cert) { Write-Host \"Certificate Details:\" -ForegroundColor Green; Write-Host \"  Subject:\" $cert.Subject; Write-Host \"  Expires:\" $cert.NotAfter }"
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