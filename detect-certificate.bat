@echo off
REM Bituach Leumi Certificate Detection and Configuration Utility
REM Automatically detects and configures Bituach Leumi certificates for Memshak

setlocal enabledelayedexpansion

echo ================================================
echo   Bituach Leumi Certificate Detection Utility
echo ================================================

echo Scanning certificate store: Cert:\LocalMachine\My
echo Looking for certificates with private keys...

REM Detect certificates using PowerShell
echo Detecting certificates...
pwsh -Command "& { try { Write-Host 'Searching for Bituach Leumi certificate in Cert:\LocalMachine\My...'; $certs = Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.Subject -match 'CN=' -and $_.HasPrivateKey -eq $true -and $_.NotAfter -gt (Get-Date) }; if ($certs.Count -eq 0) { Write-Host 'No valid certificates with private keys found in LocalMachine\My store'; Write-Host 'Please ensure your Bituach Leumi certificate USB disk is connected and certificate is installed'; exit 1 }; Write-Host 'Found certificate(s):'; foreach ($cert in $certs) { $issuer = $cert.Issuer; $subject = $cert.Subject; $thumbprint = $cert.Thumbprint; $expiry = $cert.NotAfter; Write-Host \"  Subject: $subject\"; Write-Host \"  Issuer: $issuer\"; Write-Host \"  Thumbprint: $thumbprint\"; Write-Host \"  Expires: $expiry\"; Write-Host ''; }; $selectedCert = $certs | Sort-Object NotAfter -Descending | Select-Object -First 1; Write-Host \"Selected certificate thumbprint: $($selectedCert.Thumbprint)\"; Write-Host \"Subject: $($selectedCert.Subject)\"; Write-Host \"Expires: $($selectedCert.NotAfter)\"; $selectedCert.Thumbprint } catch { Write-Host 'Certificate detection failed:' $_.Exception.Message; Write-Host 'Will proceed without setting CERT_THUMBPRINT - you may need to set it manually'; exit 0 } }" > "%TEMP%\cert_detection_output.txt" 2>&1

REM Process the output
if exist "%TEMP%\cert_detection_output.txt" (
    type "%TEMP%\cert_detection_output.txt"
    
    REM Extract just the thumbprint from the last line
    for /f "tokens=*" %%i in ('type "%TEMP%\cert_detection_output.txt" ^| findstr /E /C:"A B C D E F 0 1 2 3 4 5 6 7 8 9"') do (
        set "DETECTED_CERT_THUMBPRINT=%%i"
    )
    
    del "%TEMP%\cert_detection_output.txt" >nul 2>&1
    
    if not "!DETECTED_CERT_THUMBPRINT!"=="" (
        echo.
        echo ================================================
        echo   CERTIFICATE DETECTION SUCCESSFUL
        echo ================================================
        echo Detected Certificate Thumbprint: !DETECTED_CERT_THUMBPRINT!
        
        echo Setting CERT_THUMBPRINT environment variable...
        setx CERT_THUMBPRINT "!DETECTED_CERT_THUMBPRINT!" >nul
        if not errorlevel 1 (
            echo Environment variable set successfully
            set "CERT_THUMBPRINT=!DETECTED_CERT_THUMBPRINT!"
        ) else (
            echo Warning: Failed to set system environment variable
            echo You may need to run as Administrator for system-wide settings
        )
        
        echo.
        echo ================================================
        echo   CONFIGURATION COMPLETE
        echo ================================================
        echo The certificate is now configured for Memshak authentication.
        echo You can now start the authentication server with:
        echo   start-auth-server.bat
        echo.
        echo Current CERT_THUMBPRINT: !DETECTED_CERT_THUMBPRINT!
    ) else (
        echo.
        echo ================================================
        echo   CERTIFICATE DETECTION INCOMPLETE
        echo ================================================
        echo No suitable certificate thumbprint found in output.
        echo Please ensure your Bituach Leumi certificate is properly installed.
        echo.
        echo Manual configuration steps:
        echo 1. Connect your Bituach Leumi USB certificate
        echo 2. Install the certificate in Windows Certificate Store
        echo 3. Run this script again or set CERT_THUMBPRINT manually
    )
) else (
    echo ERROR: Failed to run certificate detection
    echo Please ensure PowerShell 7 is installed and certificates are accessible
)

echo.
pause
