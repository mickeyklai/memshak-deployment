@echo off
REM Bituach Leumi Certificate Detection and Configuration Utility
REM Automatically detects and configures Bituach Leumi certificates for Memshak

setlocal enabledelayedexpansion

echo ================================================
echo   Bituach Leumi Certificate Detection Utility
echo ================================================

echo Scanning certificate store: Cert:\CurrentUser\My
echo Looking for PersonalID Supervised Operational certificates with accessible private keys...

REM Detect certificates using PowerShell with online key testing
echo Detecting certificates with accessible private keys (USB device must be inserted)...

REM First run - display certificate information with online key testing
pwsh -Command "& { function Test-CertKeyOnline { param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert); try { $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert); if ($rsa) { $null = $rsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1); return $true } } catch { } try { $ecdsa = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Cert); if ($ecdsa) { $null = $ecdsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256); return $true } } catch { } return $false }; function Get-ProviderName { param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert); try { $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert); if ($rsa -and $rsa.Key -and $rsa.Key.Provider) { return $rsa.Key.Provider.Provider } } catch {} try { if ($Cert.PrivateKey -and $Cert.PrivateKey.CspKeyContainerInfo) { return $Cert.PrivateKey.CspKeyContainerInfo.ProviderName } } catch {} return 'N/A' }; Write-Host 'Searching for online PersonalID Supervised Operational certificates in Cert:\CurrentUser\My...'; $online = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object { if (Test-CertKeyOnline -Cert $_) { $ku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension] }).KeyUsages; $eku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.FriendlyName -join ', '; [pscustomobject]@{ Subject = $_.Subject; Issuer = $_.Issuer; NotBefore = $_.NotBefore; NotAfter = $_.NotAfter; Thumbprint = $_.Thumbprint; SerialNumber = $_.SerialNumber; FriendlyName = $_.FriendlyName; HasPrivateKey = $_.HasPrivateKey; Provider = Get-ProviderName -Cert $_; KeyUsage = $ku; EnhancedKeyUsage = $eku; RawCertificate = $_ } } }; $patternCN = '(?i)CN=.*PersonalID Supervised Operational'; $patternEKU = '(?i)(Client Authentication|Smart Card Log[- ]?on|אימות לקוח|כניסה של כרטיס חכם)'; $validCerts = $online | Where-Object { (($_.Subject + '|' + $_.Issuer) -match $patternCN) -and ($_.EnhancedKeyUsage -match $patternEKU) }; if ($validCerts) { Write-Host 'Found online PersonalID certificate(s) with accessible private keys:'; $validCerts | ForEach-Object { Write-Host \"  Subject: $($_.Subject)\"; Write-Host \"  Issuer: $($_.Issuer)\"; Write-Host \"  Thumbprint: $($_.Thumbprint)\"; Write-Host \"  Expires: $($_.NotAfter)\"; Write-Host \"  Provider: $($_.Provider)\"; Write-Host \"  Key Usage: $($_.KeyUsage)\"; Write-Host \"  Enhanced Key Usage: $($_.EnhancedKeyUsage)\"; Write-Host ''; }; $selectedCert = $validCerts | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1; if ($selectedCert) { Write-Host \"Selected certificate thumbprint: $($selectedCert.Thumbprint)\"; Write-Host \"Subject: $($selectedCert.Subject)\"; Write-Host \"Expires: $($selectedCert.NotAfter)\"; Write-Host \"Provider: $($selectedCert.Provider)\"; } else { Write-Host 'No valid non-expired certificate found'; } } else { Write-Host 'No PersonalID Supervised Operational certificates found with accessible private keys'; Write-Host 'Please ensure your Bituach Leumi certificate USB device is connected and working'; } }"

REM Second run - get just the thumbprint
for /f "tokens=*" %%i in ('pwsh -Command "& { function Test-CertKeyOnline { param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert); try { $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert); if ($rsa) { $null = $rsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1); return $true } } catch { } try { $ecdsa = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Cert); if ($ecdsa) { $null = $ecdsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256); return $true } } catch { } return $false }; $online = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object { if (Test-CertKeyOnline -Cert $_) { $ku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension] }).KeyUsages; $eku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.FriendlyName -join ', '; [pscustomobject]@{ Subject = $_.Subject; Issuer = $_.Issuer; NotAfter = $_.NotAfter; Thumbprint = $_.Thumbprint; EnhancedKeyUsage = $eku; RawCertificate = $_ } } }; $patternCN = '(?i)CN=.*PersonalID Supervised Operational'; $patternEKU = '(?i)(Client Authentication|Smart Card Log[- ]?on|אימות לקוח|כניסה של כרטיס חכם)'; $validCerts = $online | Where-Object { (($_.Subject + '|' + $_.Issuer) -match $patternCN) -and ($_.EnhancedKeyUsage -match $patternEKU) }; $selectedCert = $validCerts | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1; if ($selectedCert) { $selectedCert.Thumbprint } }"') do (
    set "DETECTED_CERT_THUMBPRINT=%%i"
)
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
        echo No PersonalID Supervised Operational certificate found with accessible private key.
        echo Please ensure your Bituach Leumi certificate device is connected and working.
        echo.
        echo Troubleshooting steps:
        echo 1. Connect your Bituach Leumi USB certificate device
        echo 2. Ensure the device is properly recognized (check Device Manager)
        echo 3. Verify the PersonalID certificate is installed in Windows Certificate Store (CurrentUser\My)
        echo 4. Make sure the certificate has Client Authentication/אימות לקוח or Smart Card Log-on/כניסה של כרטיס חכם capability
        echo 5. Try removing and reconnecting the USB device
        echo 6. Run this script again or set CERT_THUMBPRINT manually
    )

echo.
pause
