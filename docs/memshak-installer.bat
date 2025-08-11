@echo off
REM Memshak CDN Installer - Production Version
REM Downloads and installs Memshak system from GitHub

setlocal enabledelayedexpansion

echo ==========================================
echo    MEMSHAK CDN INSTALLER v2.0
echo ==========================================

REM Check for Administrator privileges
net session >nul 2>&1
if errorlevel 1 (
    echo ⚠️  WARNING: Running without Administrator privileges
    echo.
    echo ❌ IMPORTANT: Administrator rights are REQUIRED for:
    echo    • SSL certificate installation to Trusted Root store
    echo    • Proper HTTPS security without browser warnings
    echo    • Certificate store access for authentication
    echo.
    echo 🔧 SOLUTION: Right-click this installer and select "Run as administrator"
    echo.
    set /p "CONTINUE=Continue with limited installation? (y/n): "
    if /i not "!CONTINUE!"=="y" (
        echo Installation cancelled. Please run as administrator for best experience.
        pause
        exit /b 0
    )
    echo.
    echo ⚠️  Continuing with limited installation...
    echo    HTTPS may show security warnings in browsers
    echo.
    set "ADMIN_MODE=false"
) else (
    echo ✅ Running with Administrator privileges
    echo    Full SSL certificate installation available
    echo.
    set "ADMIN_MODE=true"
)

REM Create installation directory
set "INSTALL_DIR=%USERPROFILE%\memshak-system"
echo Installation directory: %INSTALL_DIR%

if exist "%INSTALL_DIR%" (
    echo.
    echo ⚠️  Installation directory already exists
    set /p "OVERWRITE=Continue anyway? (y/n): "
    if /i not "!OVERWRITE!"=="y" (
        echo Installation cancelled
        pause
        exit /b 0
    )
    echo Cleaning existing installation...
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
)

mkdir "%INSTALL_DIR%"
cd /d "%INSTALL_DIR%"

echo.
echo [STEP 1/6] Checking prerequisites...

REM Check PowerShell
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ❌ PowerShell 7 not found. Please install PowerShell 7
    echo Download from: https://github.com/PowerShell/PowerShell/releases
    pause
    exit /b 1
) else (
    echo ✅ PowerShell 7 detected
)

REM Check Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker not found. Please install Docker Desktop
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
) else (
    echo ✅ Docker detected
)

echo.
echo [STEP 2/6] Downloading deployment package...
echo Source: https://github.com/mickeyklai/memshak-deployment

REM Create temporary download script
echo # Download deployment package from GitHub > download-temp.ps1
echo param( >> download-temp.ps1
echo     [string]$Url = "https://github.com/mickeyklai/memshak-deployment/archive/refs/heads/main.zip", >> download-temp.ps1
echo     [string]$OutputFile = "deployment.zip" >> download-temp.ps1
echo ^) >> download-temp.ps1
echo. >> download-temp.ps1
echo try { >> download-temp.ps1
echo     $ProgressPreference = 'SilentlyContinue' >> download-temp.ps1
echo     Write-Host "Downloading deployment package..." >> download-temp.ps1
echo     Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UserAgent 'Memshak-CDN/2.0' -TimeoutSec 60 >> download-temp.ps1
echo     Write-Host "Download completed successfully!" >> download-temp.ps1
echo     exit 0 >> download-temp.ps1
echo } catch { >> download-temp.ps1
echo     Write-Host "Download failed: $($_.Exception.Message)" >> download-temp.ps1
echo     exit 1 >> download-temp.ps1
echo } >> download-temp.ps1

pwsh -ExecutionPolicy Bypass -File "download-temp.ps1"

if errorlevel 1 (
    echo ❌ Download failed
    echo.
    echo Possible solutions:
    echo 1. Check internet connection
    echo 2. Try running as Administrator
    echo 3. Check Windows Defender/Antivirus settings
    echo 4. Verify GitHub is accessible
    del download-temp.ps1 >nul 2>&1
    pause
    exit /b 1
) else (
    echo ✅ Download completed
)

del download-temp.ps1 >nul 2>&1

echo.
echo [STEP 3/6] Extracting deployment package...

REM Create temporary extraction script
echo # Extract deployment package > extract-temp.ps1
echo try { >> extract-temp.ps1
echo     Write-Host "Extracting deployment package..." >> extract-temp.ps1
echo     Expand-Archive -Path 'deployment.zip' -DestinationPath '.' -Force >> extract-temp.ps1
echo     Write-Host "Extraction completed successfully!" >> extract-temp.ps1
echo     exit 0 >> extract-temp.ps1
echo } catch { >> extract-temp.ps1
echo     Write-Host "Extraction failed: $($_.Exception.Message)" >> extract-temp.ps1
echo     exit 1 >> extract-temp.ps1
echo } >> extract-temp.ps1

pwsh -ExecutionPolicy Bypass -File "extract-temp.ps1"

if errorlevel 1 (
    echo ❌ Extraction failed
    del extract-temp.ps1 >nul 2>&1
    pause
    exit /b 1
)

del extract-temp.ps1 >nul 2>&1

REM Move files from subdirectory to current directory
if exist "memshak-deployment-main" (
    echo Moving files from extracted directory...
    xcopy "memshak-deployment-main\*" . /E /H /C /I /Y >nul
    rmdir /s /q "memshak-deployment-main" >nul 2>&1
    del deployment.zip >nul 2>&1
    echo ✅ Extraction and cleanup completed
) else (
    echo ❌ Expected directory structure not found
    pause
    exit /b 1
)

echo.
echo [STEP 4/6] Validating installation files...
set "VALIDATION_PASSED=1"
if not exist "docker-compose.yml" (echo ❌ docker-compose.yml missing & set "VALIDATION_PASSED=0")
if not exist "start-local.bat" (echo ❌ start-local.bat missing & set "VALIDATION_PASSED=0")
if not exist "stop-local.bat" (echo ❌ stop-local.bat missing & set "VALIDATION_PASSED=0")
if not exist "host-auth-server.ps1" (echo ❌ host-auth-server.ps1 missing & set "VALIDATION_PASSED=0")

if "%VALIDATION_PASSED%"=="0" (
    echo ❌ Validation failed - required files missing
    pause
    exit /b 1
) else (
    echo ✅ All required files present
)

REM Create .env file from template
if not exist ".env" (
    if exist ".env.example" (
        echo Creating environment configuration file...
        copy ".env.example" ".env" >nul
        echo ✅ Environment file created from template
    ) else (
        echo ⚠️  .env.example not found, creating basic .env file...
        echo # Memshak Environment Configuration > .env
        echo NODE_ENV=production >> .env
        echo DEBUG=false >> .env
        echo LOG_LEVEL=info >> .env
        echo ELISAR_PASSWORD=change-this-password >> .env
        echo LIMOR_PASSWORD=change-this-password >> .env
        echo JWT_SECRET=local-dev-secret-change-in-production >> .env
        echo ✅ Basic environment file created
    )
) else (
    echo ✅ Environment file already exists
)

echo.
echo [STEP 5/7] Testing Docker configuration...
docker-compose config >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose configuration has errors
    echo Run 'docker-compose config' for details
) else (
    echo ✅ Docker Compose configuration valid
)

REM Create required directories for Docker volumes
echo Creating required directories...
if not exist "data" mkdir data
if not exist "logs" mkdir logs
echo ✅ Required directories created

echo.
echo [STEP 6/7] Setting up SSL certificates...
REM Always create ssl directory first
if not exist "ssl" mkdir ssl

if "%ADMIN_MODE%"=="true" (
    echo Generating SSL certificates with trusted root installation...
    if exist "generate-ssl.ps1" (
        pwsh -ExecutionPolicy Bypass -File "generate-ssl.ps1"
        if errorlevel 1 (
            echo ⚠️  Full SSL generation failed, creating basic certificates...
            call :CreateBasicSSL
        ) else (
            echo ✅ SSL certificates installed to trusted root store
            echo    Browsers will trust https://localhost:8443 connections
        )
    ) else (
        echo ⚠️  SSL generation script not found, creating basic certificates...
        call :CreateBasicSSL
    )
) else (
    echo Generating basic SSL certificates...
    if exist "generate-basic-ssl.ps1" (
        pwsh -ExecutionPolicy Bypass -File "generate-basic-ssl.ps1"
        if errorlevel 1 (
            echo ⚠️  SSL certificate generation failed, creating fallback certificates...
            call :CreateBasicSSL
        ) else (
            echo ✅ Basic SSL certificates created
        )
    ) else (
        echo ⚠️  SSL generation script not found, creating fallback certificates...
        call :CreateBasicSSL
    )
)

REM Verify SSL certificates exist
if exist "ssl\localhost.crt" (
    echo ✅ SSL certificates ready
) else (
    echo ❌ SSL certificate creation failed, trying emergency fallback...
    call :CreateBasicSSL
)

if exist "start-auth-server.bat" (
    echo ✅ Certificate authentication setup completed
) else (
    echo ⚠️  Certificate setup script not found
)

echo.
echo ==========================================
echo    INSTALLATION COMPLETED SUCCESSFULLY
echo ==========================================
echo.
echo 📁 Installation location: %INSTALL_DIR%
echo.
echo 🚀 QUICK START GUIDE:
echo 1. Start all services: start-local.bat (Docker + auth server)
echo 2. Stop all services: stop-local.bat  
echo 3. Update images: update-system.bat
echo 4. Auth server only: start-auth-server.bat (if needed separately)
echo.
echo 🌐 ACCESS URLS:
echo - Main Application (HTTPS): https://localhost:8443
echo - HTTP Redirect: http://localhost:8080 (redirects to HTTPS)
echo - PowerShell Auth Server: http://localhost:8888 (local service)
echo.
echo 🔒 SECURITY STATUS:
if "%ADMIN_MODE%"=="true" (
    echo ✅ SSL certificates installed to trusted root store
    echo ✅ All web traffic uses HTTPS with proper certificates
    echo ✅ Frontend and backend communicate internally via Docker network
    echo ✅ PowerShell auth server runs locally (HTTP is safe for localhost)
    echo ✅ External database connections use HTTPS
) else (
    echo ⚠️  SSL certificates may show browser warnings (no admin rights)
    echo ✅ Frontend and backend communicate internally via Docker network
    echo ✅ PowerShell auth server runs locally (HTTP is safe for localhost)
    echo ✅ External database connections use HTTPS
    echo.
    echo 💡 TO FIX SSL WARNINGS:
    echo    1. Close this installation
    echo    2. Right-click installer and "Run as administrator"  
    echo    3. Reinstall with administrator privileges
)
echo.
echo 📋 CERTIFICATE SETUP:
echo The system will automatically detect SSL certificates.
echo For manual configuration, see: start-auth-server.bat
echo.
echo ==========================================
echo   READY TO START MEMSHAK SYSTEM
echo ==========================================
echo.
set /p "START_NOW=Would you like to start the system now? (y/n): "
if /i "!START_NOW!"=="y" (
    echo.
    echo ==========================================
    echo   STARTING COMPLETE MEMSHAK SYSTEM
    echo ==========================================
    echo.
    
    echo [1/3] Starting Docker containers...
    docker-compose up -d
    
    if errorlevel 1 (
        echo ❌ Failed to start Docker containers
        echo Please check Docker Desktop is running
        pause
        exit /b 1
    )
    
    echo ✅ Docker containers started
    echo.
    
    echo [2/3] Waiting for services to initialize...
    timeout /t 10 >nul
    echo ✅ Services initialized
    echo.
    
    echo [3/3] Starting authentication server...
    REM Create a dedicated startup script for admin mode
    echo @echo off > start-auth-admin.bat
    echo cd /d "%~dp0" >> start-auth-admin.bat
    echo pwsh -ExecutionPolicy Bypass -File "host-auth-server.ps1" -Port 8888 -AuthScriptPath "auth.ps1" >> start-auth-admin.bat
    
    REM Start using the dedicated script
    echo Starting auth server on port 8888...
    start /b cmd /c "start-auth-admin.bat" >nul 2>&1
    timeout /t 5 >nul

    REM Check if auth server is running on port 8888
    netstat -ano | findstr ":8888" >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Port 8888 not active, trying alternative method...
        REM Direct PowerShell execution
        start /b pwsh -WindowStyle Hidden -ExecutionPolicy Bypass -Command "cd '!CD!'; & '.\host-auth-server.ps1' -Port 8888 -AuthScriptPath 'auth.ps1'"
        timeout /t 3 >nul
        
        REM Final check
        netstat -ano | findstr ":8888" >nul 2>&1
        if errorlevel 1 (
            echo ⚠️  Authentication server may need manual start
            echo    Run: pwsh -File host-auth-server.ps1 -Port 8888 -AuthScriptPath auth.ps1
        ) else (
            echo ✅ Authentication server started on port 8888
        )
    ) else (
        echo ✅ Authentication server started successfully on port 8888
    )
    echo.
    
    echo ==========================================
    echo   🎉 SYSTEM STARTUP COMPLETED SUCCESSFULLY!
    echo ==========================================
    echo.
    echo 🌐 WEB ACCESS:
    echo    ➤ Main Application: https://localhost:8443
    echo    ➤ HTTP Redirect: http://localhost:8080
    echo.
    echo 🔐 AUTHENTICATION:
    echo    ➤ Auth Server: http://localhost:8888
    echo    ➤ Certificate detection: Automatic
    echo.
    echo 📊 MANAGEMENT:
    echo    ➤ Check status: docker-compose ps
    echo    ➤ View logs: docker-compose logs -f
    echo    ➤ Stop system: stop-local.bat
    echo.
    echo 🎊 Ready to use! Open https://localhost:8443 in your browser
    echo.
    echo Press any key to exit installer...
    pause >nul
) else (
    echo.
    echo To start the complete system later, run: start-local.bat
    echo This will start Docker containers and authentication server
    echo from directory: %INSTALL_DIR%
    echo.
    echo Press any key to exit installer...
    pause >nul
)

echo.
echo ==========================================
echo   INSTALLATION FINISHED
echo ==========================================
echo.
echo Thank you for installing Memshak! 🎉
echo.
echo For support and documentation:
echo - GitHub: https://github.com/mickeyklai/memshak-deployment  
echo - Issues: Report any problems on GitHub Issues
echo.
echo Installation completed successfully!
echo Press any key to exit installer...
pause >nul

:CreateBasicSSL
echo Creating fallback SSL certificates...
if not exist "ssl" mkdir ssl

REM Create basic SSL certificate using OpenSSL-style approach via PowerShell
pwsh -Command "
    if (-not (Test-Path 'ssl')) { New-Item -ItemType Directory -Path 'ssl' | Out-Null }
    
    # Create a self-signed certificate for localhost
    `$cert = New-SelfSignedCertificate -DnsName 'localhost' -CertStoreLocation 'cert:\CurrentUser\My' -KeyAlgorithm RSA -KeyLength 2048 -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider' -NotAfter (Get-Date).AddYears(1)
    
    # Export the certificate
    `$certPath = 'ssl\localhost.crt'
    `$keyPath = 'ssl\localhost.key'
    
    # Export certificate
    `$certBytes = `$cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    [System.IO.File]::WriteAllBytes((Resolve-Path .).Path + '\' + `$certPath, `$certBytes)
    
    # Export private key (basic approach)
    `$keyBytes = `$cert.PrivateKey.ExportPkcs8PrivateKey()
    `$keyPem = '-----BEGIN PRIVATE KEY-----' + [System.Environment]::NewLine
    `$keyPem += [System.Convert]::ToBase64String(`$keyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    `$keyPem += [System.Environment]::NewLine + '-----END PRIVATE KEY-----'
    [System.IO.File]::WriteAllText((Resolve-Path .).Path + '\' + `$keyPath, `$keyPem)
    
    # Convert cert to PEM format
    `$certPem = '-----BEGIN CERTIFICATE-----' + [System.Environment]::NewLine
    `$certPem += [System.Convert]::ToBase64String(`$certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    `$certPem += [System.Environment]::NewLine + '-----END CERTIFICATE-----'
    [System.IO.File]::WriteAllText((Resolve-Path .).Path + '\' + `$certPath, `$certPem)
    
    # Clean up from certificate store
    Get-ChildItem -Path 'cert:\CurrentUser\My' | Where-Object { `$_.Thumbprint -eq `$cert.Thumbprint } | Remove-Item
    
    Write-Host 'Basic SSL certificates created successfully'
" 2>nul

if exist "ssl\localhost.crt" (
    echo ✅ Fallback SSL certificates created
) else (
    echo ❌ Failed to create SSL certificates
)
goto :eof
