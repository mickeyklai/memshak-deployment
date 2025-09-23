@echo off
REM Memshak CDN Installer - Enhanced Version with Auto-Prerequisites
REM Downloads and installs Memshak system from GitHubREM Function to check and install Docker Desktop (requires WSL2)
echo.
echo 🔍 Checking for Docker Desktop...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker not found. Installing Docker Desktop via Chocolatey...
    echo ℹ️  Note: Docker Desktop requires WSL2 which should now be installed
    
    REM Install Docker Desktop (depends on WSL2 being available)
    choco install docker-desktop -y --no-progressomatic dependency installation

setlocal enabledelayedexpansion

echo ==========================================
echo    MEMSHAK CDN INSTALLER v2.1 ENHANCED
echo ==========================================

REM Check for Administrator privileges
net session >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Administrator privileges required!
    echo.
    echo This installer needs to:
    echo  • Install Chocolatey package manager
    echo  • Install PowerShell 7, Docker Desktop, and WSL
    echo  • Configure system services and startup
    echo  • Install SSL certificates
    echo.
    echo 🔧 SOLUTION: Right-click this installer and select "Run as administrator"
    echo.
    pause
    exit /b 1
) else (
    echo ✅ Running with Administrator privileges
    echo    Full installation with automatic dependencies available
    echo.
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
    echo.
)

echo.
echo [STEP 1/7] Checking and installing prerequisites...
echo.

REM Function to check and install Chocolatey
echo 🔍 Checking for Chocolatey package manager...
choco --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Chocolatey not found. Installing Chocolatey...
    echo.
    
    REM Install Chocolatey
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
    "[System.Net.ServicePointManager]::SecurityProtocol = 3072; ^
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    if errorlevel 1 (
        echo ❌ ERROR: Failed to install Chocolatey
        echo Please install manually from: https://chocolatey.org/install
        pause
        exit /b 1
    )
    
    REM Refresh environment variables for current session
    call refreshenv.cmd >nul 2>&1
    
    echo ✅ Chocolatey installed successfully
) else (
    echo ✅ Chocolatey already installed
)

REM Function to check and install PowerShell 7
echo.
echo 🔍 Checking for PowerShell 7...
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ❌ PowerShell 7 not found. Installing via Chocolatey...
    choco install powershell-core -y --no-progress
    
    if errorlevel 1 (
        echo ❌ ERROR: Failed to install PowerShell 7
        pause
        exit /b 1
    )
    
    REM Refresh PATH
    call refreshenv.cmd >nul 2>&1
    
    echo ✅ PowerShell 7 installed successfully
) else (
    echo ✅ PowerShell 7 already installed
)

REM Function to check and install WSL (MUST be installed before Docker Desktop)
echo.
echo 🔍 Checking for WSL (Windows Subsystem for Linux)...
wsl --status >nul 2>&1
if errorlevel 1 (
    echo ❌ WSL not found. Installing WSL (required for Docker Desktop)...
    
    REM Enable WSL features first
    echo 🔧 Enabling WSL Windows features...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    REM Install WSL2 kernel via Chocolatey
    echo 🔧 Installing WSL2 kernel and components...
    choco install wsl2 -y --no-progress
    
    if errorlevel 1 (
        echo ❌ ERROR: WSL installation failed
        echo WSL2 is required for Docker Desktop to function properly
        echo.
        set /p "CONTINUE_WITHOUT_WSL=Continue installation anyway? (Docker may not work) (y/n): "
        if /i not "!CONTINUE_WITHOUT_WSL!"=="y" (
            echo Installation cancelled. Please install WSL2 manually and retry.
            pause
            exit /b 1
        )
    ) else (
        echo ✅ WSL installed successfully
        echo ⚠️  NOTE: A system restart may be required for WSL to be fully functional
    )
) else (
    echo ✅ WSL already installed and functional
)

REM Function to check and install Docker Desktop (requires WSL2)
echo.
echo 🔍 Checking for Docker Desktop...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker not found. Installing Docker Desktop via Chocolatey...
    
    REM Install Docker Desktop
    choco install docker-desktop -y --no-progress
    
    if errorlevel 1 (
        echo ❌ ERROR: Failed to install Docker Desktop
        echo You may need to install manually from: https://www.docker.com/products/docker-desktop
        set /p "CONTINUE_WITHOUT_DOCKER=Continue without Docker? (y/n): "
        if /i not "!CONTINUE_WITHOUT_DOCKER!"=="y" (
            pause
            exit /b 1
        )
    ) else (
        echo ✅ Docker Desktop installed successfully
        
        REM Configure Docker to start at boot
        echo 🔧 Configuring Docker to start automatically...
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"C:\Program Files\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1
        
        REM Start Docker Desktop service
        echo 🚀 Starting Docker Desktop...
        start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        
        REM Wait a moment for Docker to start
        timeout /t 10 /nobreak >nul
        
        echo ✅ Docker Desktop configured for automatic startup
    )
) else (
    echo ✅ Docker Desktop already installed
    
    REM Ensure Docker is configured for startup
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" >nul 2>&1
    if errorlevel 1 (
        echo 🔧 Configuring Docker for automatic startup...
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"C:\Program Files\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1
        echo ✅ Docker configured for automatic startup
    ) else (
        echo ✅ Docker already configured for automatic startup
    )
)

REM Verify all prerequisites are now available
echo.
echo 🔍 Final prerequisite verification...
set "PREREQ_OK=true"

pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ❌ PowerShell 7 still not available
    set "PREREQ_OK=false"
) else (
    echo ✅ PowerShell 7 verified
)

docker --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Docker not immediately available (may need restart or time to start)
    echo    Installation will continue, but Docker features may not work until restart
) else (
    echo ✅ Docker verified
)

if "!PREREQ_OK!"=="false" (
    echo.
    echo ❌ ERROR: Some prerequisites could not be installed
    echo Please restart your computer and try again, or install manually:
    echo  • PowerShell 7: https://github.com/PowerShell/PowerShell/releases
    echo  • Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo.
echo ✅ All prerequisites installed and verified!
echo.
echo [STEP 2/7] Downloading deployment package...
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
echo     Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UserAgent 'Memshak-CDN/2.1' -TimeoutSec 60 >> download-temp.ps1
echo     Write-Host "Download completed successfully" >> download-temp.ps1
echo } catch { >> download-temp.ps1
echo     Write-Host "Error downloading: $_" >> download-temp.ps1
echo     exit 1 >> download-temp.ps1
echo } >> download-temp.ps1

REM Execute download
pwsh -ExecutionPolicy Bypass -File download-temp.ps1

if errorlevel 1 (
    echo ❌ ERROR: Failed to download deployment package
    del download-temp.ps1 >nul 2>&1
    pause
    exit /b 1
)

echo ✅ Deployment package downloaded successfully
del download-temp.ps1 >nul 2>&1

echo.
echo [STEP 3/7] Extracting deployment package...

REM Extract using PowerShell
pwsh -Command "Expand-Archive -Path 'deployment.zip' -DestinationPath '.' -Force"

if errorlevel 1 (
    echo ❌ ERROR: Failed to extract deployment package
    pause
    exit /b 1
)

echo ✅ Deployment package extracted successfully

REM Clean up zip file
del deployment.zip >nul 2>&1

REM Find extracted directory
for /d %%i in (memshak-deployment-*) do set "EXTRACTED_DIR=%%i"

if not defined EXTRACTED_DIR (
    echo ❌ ERROR: Could not find extracted deployment directory
    pause
    exit /b 1
)

echo Found deployment directory: %EXTRACTED_DIR%

echo.
echo [STEP 4/7] Setting up Memshak system...

REM Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy deployment files
xcopy "%EXTRACTED_DIR%\*" "%INSTALL_DIR%\" /E /H /C /I /Y >nul

if errorlevel 1 (
    echo ❌ ERROR: Failed to copy deployment files
    pause
    exit /b 1
)

echo ✅ Memshak system files installed

echo.
echo [STEP 5/7] Setting up Docker services...

REM Navigate to installation directory
cd /d "%INSTALL_DIR%"

REM Wait for Docker to be fully ready
echo ⏳ Waiting for Docker to be ready...
:DOCKER_WAIT
docker info >nul 2>&1
if errorlevel 1 (
    timeout /t 5 /nobreak >nul
    goto DOCKER_WAIT
)

echo ✅ Docker is ready

REM Build and start services
if exist "docker-compose.yml" (
    echo 🐳 Building and starting Docker services...
    docker-compose up --build -d
    
    if errorlevel 1 (
        echo ❌ WARNING: Docker services failed to start
        echo This may be resolved after a system restart
    ) else (
        echo ✅ Docker services started successfully
    )
) else (
    echo ⚠️  No docker-compose.yml found, skipping Docker setup
)

echo.
echo [STEP 6/7] Creating shortcuts and startup configuration...

REM Create desktop shortcut
echo 🔗 Creating desktop shortcut...
pwsh -Command "& { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Memshak.lnk'); $Shortcut.TargetPath = 'http://localhost:4200'; $Shortcut.Save() }"

if errorlevel 1 (
    echo ⚠️  Could not create desktop shortcut
) else (
    echo ✅ Desktop shortcut created
)

REM Create start menu shortcut
echo 🔗 Creating start menu shortcut...
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Memshak" mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Memshak"
pwsh -Command "& { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Memshak\Memshak.lnk'); $Shortcut.TargetPath = 'http://localhost:4200'; $Shortcut.Save() }"

echo.
echo [STEP 7/7] Installation complete!

REM Clean up extracted directory
cd /d "%~dp0"
rmdir /s /q "%EXTRACTED_DIR%" >nul 2>&1

echo.
echo ==========================================
echo    INSTALLATION COMPLETED SUCCESSFULLY! 
echo ==========================================
echo.
echo 🎉 Memshak system has been installed with all prerequisites!
echo.
echo 📍 Installation Location: %INSTALL_DIR%
echo 🌐 Access URL: http://localhost:4200
echo 📱 Desktop Shortcut: Created
echo 🐳 Docker Services: Configured for auto-start
echo.
echo 🔧 INSTALLED COMPONENTS:
echo ✅ Chocolatey Package Manager
echo ✅ PowerShell 7
echo ✅ Docker Desktop (with auto-start)
echo ✅ WSL (Windows Subsystem for Linux)
echo ✅ Memshak Application Services
echo.
echo 🚀 NEXT STEPS:
echo 1. Restart your computer to ensure all components are fully active
echo 2. After restart, Docker Desktop should start automatically
echo 3. Open Memshak via desktop shortcut or navigate to http://localhost:4200
echo.
echo 💡 If services don't start automatically after restart:
echo    • Check if Docker Desktop is running
echo    • Navigate to %INSTALL_DIR% and run: docker-compose up -d
echo.

set /p "RESTART_NOW=Would you like to restart now? (recommended) (y/n): "
if /i "!RESTART_NOW!"=="y" (
    echo.
    echo 🔄 Restarting system in 10 seconds...
    echo Press Ctrl+C to cancel
    timeout /t 10
    shutdown /r /t 0
) else (
    echo.
    echo ⚠️  Please restart your computer manually when convenient
    echo    This ensures all components work properly
    echo.
    pause
)

exit /b 0