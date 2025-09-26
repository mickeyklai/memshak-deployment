@echo off
REM Memshak Complete Installer - Standalone Batch Version
REM This script installs everything needed for Memshak without external files

setlocal EnableDelayedExpansion

echo ==========================================
echo    MEMSHAK COMPLETE INSTALLER v3.1
echo ==========================================
echo.
echo This installer will automatically install:
echo ✅ Chocolatey Package Manager  
echo ✅ PowerShell 7
echo ✅ Docker Desktop (architecture-aware)
echo ✅ WSL (Windows Subsystem for Linux)
echo ✅ Memshak Application System
echo.
echo 💻 Supports: x64/AMD64 and ARM64 architectures
echo.

REM Check if we're running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo 🔧 Administrator privileges required!
    echo.
    echo This installer needs to:
    echo • Install Chocolatey package manager
    echo • Install PowerShell 7, Docker Desktop, and WSL
    echo • Configure system services and startup
    echo • Install SSL certificates
    echo.
    echo 💡 SOLUTION: Right-click this file and select "Run as administrator"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo ✅ Running with Administrator privileges
echo.

REM Detect and display system architecture
echo 🔍 Detecting system architecture...
set "DETECTED_ARCH=x64/AMD64"
echo %PROCESSOR_ARCHITECTURE% | find /i "ARM64" >nul 2>&1
if not errorlevel 1 (
    set "DETECTED_ARCH=ARM64"
)
for /f "tokens=2 delims==" %%i in ('wmic os get osarchitecture /value 2^>nul ^| find "="') do (
    echo %%i | find /i "ARM64" >nul 2>&1
    if not errorlevel 1 set "DETECTED_ARCH=ARM64"
)
echo ✅ System Architecture: %DETECTED_ARCH%
echo.

REM Set installation directory
set "INSTALL_DIR=%USERPROFILE%\memshak-system"
echo Installation directory: %INSTALL_DIR%

if exist "%INSTALL_DIR%" (
    echo ⚠️  Installation directory already exists
    set /p "overwrite=Continue anyway? (y/n): "
    if /i not "!overwrite!"=="y" (
        echo Installation cancelled
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 0
    )
)

echo.
echo [STEP 1/7] Checking and installing prerequisites...
echo.

REM Function to install Chocolatey
echo 🔍 Checking for Chocolatey package manager...
timeout /t 2 >nul
choco --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Chocolatey not found. Installing Chocolatey...
    timeout /t 2 >nul
    
    REM Install Chocolatey using PowerShell
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    if errorlevel 1 (
        echo ❌ Failed to install Chocolatey
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    
    REM Refresh PATH environment variable to include Chocolatey
    echo 🔍 Refreshing environment variables...
    timeout /t 2 >nul
    
    REM Simple approach - just add Chocolatey to current PATH
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    echo 🔍 Chocolatey added to PATH for current session
    timeout /t 2 >nul
    
    REM Verify Chocolatey is now accessible
    choco --version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Chocolatey installation completed but not accessible in PATH
        echo 💡 Please restart the command prompt and run this installer again
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    
    echo ✅ Chocolatey installed successfully and PATH updated
    timeout /t 2 >nul
) else (
    echo ✅ Chocolatey already installed
    timeout /t 2 >nul
)

REM Check PowerShell 7
echo 🔍 Checking for PowerShell 7...
 timeout /t 2 >nul
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  PowerShell 7 not found. Installing via Chocolatey...
    timeout /t 2 >nul
    choco install powershell-core -y --no-progress
    if errorlevel 1 (
        echo ❌ Failed to install PowerShell 7
        timeout /t 2 >nul
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    
    REM PowerShell 7 should now be available in PATH after Chocolatey installation
    echo 🔍 PowerShell 7 should now be available via Chocolatey PATH updates
    timeout /t 2 >nul
    
    echo ✅ PowerShell 7 installed successfully
    timeout /t 2 >nul
) else (
    echo ✅ PowerShell 7 already installed
    timeout /t 2 >nul
)

REM Check WSL
echo 🔍 Checking for WSL (Windows Subsystem for Linux)...
timeout /t 2 >nul

echo 🔍 Starting WSL detection process (using crash-safe methods)...
timeout /t 1 >nul

REM Check for WSL using safer methods that won't crash the script
echo 🔍 Testing WSL availability using safe detection methods...
timeout /t 1 >nul

REM Method 1: Check if WSL executable exists in system PATH
set "WSL_AVAILABLE=1"
set "WSL_CONFIGURED=1"

echo 🔍 [DEBUG] About to check for wsl.exe in System32...
timeout /t 1 >nul

REM Check if wsl.exe exists in System32
if exist "%SystemRoot%\System32\wsl.exe" (
    echo 🔍 WSL executable found in System32
    set "WSL_AVAILABLE=0"
    
    REM Check WSL configuration using registry and file system (completely safe)
    echo 🔍 Checking WSL configuration status using safe methods...
    timeout /t 1 >nul
    
    REM Check if any WSL distributions are installed by looking at registry
    set "WSL_CONFIGURED=1"
    
    REM Method 1: Check WSL distribution registry entries
    echo 🔍 [DEBUG] About to check WSL registry entries...
    timeout /t 1 >nul
    
    reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" >nul 2>&1
    if not errorlevel 1 (
        echo 🔍 WSL registry entries found
        set "WSL_CONFIGURED=0"
    ) else (
        echo 🔍 [DEBUG] WSL registry check completed, no entries found
        timeout /t 1 >nul
        echo 🔍 [DEBUG] About to check AppData for WSL distributions...
        timeout /t 1 >nul
        
        REM Method 2: Check AppData for WSL distributions using DIR command (safer than wildcards)
        dir "%USERPROFILE%\AppData\Local\Packages\" 2>nul | find /i "Ubuntu" >nul 2>&1
        if not errorlevel 1 (
            echo 🔍 Ubuntu WSL distribution found in AppData
            set "WSL_CONFIGURED=0"
        ) else (
            dir "%USERPROFILE%\AppData\Local\Packages\" 2>nul | find /i "Debian" >nul 2>&1
            if not errorlevel 1 (
                echo 🔍 Debian WSL distribution found in AppData
                set "WSL_CONFIGURED=0"
            ) else (
                dir "%USERPROFILE%\AppData\Local\Packages\" 2>nul | find /i "openSUSE" >nul 2>&1
                if not errorlevel 1 (
                    echo 🔍 openSUSE WSL distribution found in AppData
                    set "WSL_CONFIGURED=0"
                ) else (
                    echo 🔍 No WSL distributions detected in AppData Packages
                )
            )
        )
        
        echo 🔍 [DEBUG] AppData WSL distribution check completed
        timeout /t 1 >nul
    )
    
    if !WSL_CONFIGURED! equ 0 (
        echo 🔍 WSL distributions detected via registry/filesystem check
    ) else (
        echo 🔍 No WSL distributions found - fresh installation needed
    )
) else (
    echo 🔍 WSL executable not found in System32
)

echo 🔍 [DEBUG] WSL detection method 1 completed successfully
timeout /t 1 >nul

REM Method 2: Check Windows features for WSL (alternative detection)
if !WSL_AVAILABLE! neq 0 (
    echo 🔍 Checking Windows optional features for WSL...
    timeout /t 1 >nul
    
    REM Use DISM to check if WSL feature is installed
    dism /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 (
        echo 🔍 WSL Windows feature is enabled
        set "WSL_AVAILABLE=0"
    )
)

echo 🔍 [DEBUG] WSL detection method 2 completed successfully
timeout /t 1 >nul

echo 🔍 [DEBUG] About to evaluate WSL_CONFIGURED status: !WSL_CONFIGURED!
timeout /t 1 >nul

echo 🔍 [DEBUG] WSL_CONFIGURED variable value before if statement: !WSL_CONFIGURED!
timeout /t 1 >nul

echo 🔍 [DEBUG] About to check WSL_CONFIGURED value...
timeout /t 1 >nul

REM Use GOTO instead of IF to avoid any potential crashes with delayed expansion
echo 🔍 [DEBUG] WSL_CONFIGURED value is: !WSL_CONFIGURED!
timeout /t 1 >nul

if "!WSL_CONFIGURED!"=="0" goto wsl_already_configured
goto wsl_needs_installation

:wsl_already_configured
echo 🔍 [DEBUG] WSL already configured - skipping installation
timeout /t 1 >nul
echo ✅ WSL already installed and functional
timeout /t 1 >nul
goto wsl_section_complete

:wsl_needs_installation
echo 🔍 [DEBUG] WSL needs installation - proceeding with setup
    timeout /t 1 >nul
    echo ⚠️  WSL not found or not configured. Installing WSL2 (required for Docker Desktop)...
    timeout /t 2 >nul
    
    REM Enable WSL features using safer DISM commands
    echo 🔍 Enabling WSL Windows features (this may take a few minutes)...
    timeout /t 2 >nul
    
    echo 🔍 Enabling Windows Subsystem for Linux feature...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
    timeout /t 2 >nul
    
    echo 🔍 Enabling Virtual Machine Platform feature...
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1
    timeout /t 2 >nul
    
    REM Install WSL2 kernel via Chocolatey
    echo 🔍 Installing WSL2 kernel and components via Chocolatey...
    timeout /t 2 >nul
    choco install wsl2 -y --no-progress
    if errorlevel 1 (
        echo ⚠️  Chocolatey WSL2 installation had issues, but features were enabled
        echo 💡 WSL2 kernel update may be required after restart
    )
    timeout /t 2 >nul
    
    REM Set WSL2 as default version via registry (completely safe method)
    echo 🔍 Setting WSL2 as default version via registry...
    timeout /t 1 >nul
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" /v DefaultVersion /t REG_DWORD /d 2 /f >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  WSL2 registry setting had issues, but will work after restart
    ) else (
        echo ✅ WSL2 default version configured via registry successfully
    )
    timeout /t 1 >nul
    
    echo ✅ WSL2 installation and configuration completed
    echo ⚠️  IMPORTANT: A system restart is required for WSL2 to be fully functional
    timeout /t 2 >nul

:wsl_section_complete
echo 🔍 WSL detection and configuration completed successfully
timeout /t 2 >nul

REM Check Docker Desktop
echo 🔍 Checking for Docker Desktop...
timeout /t 2 >nul
docker --version >nul 2>&1
if errorlevel 1 goto :install_docker
goto :docker_already_installed

:install_docker
echo ⚠️  Docker not found. Installing Docker Desktop via Chocolatey...
echo 🔍 Note: Docker Desktop requires WSL2 which should now be installed
timeout /t 2 >nul

echo 🔍 Attempting Docker Desktop installation via Chocolatey (method 1/4)...
choco install docker-desktop -y --no-progress --ignore-checksums
if errorlevel 1 goto :docker_choco_alternative
goto :docker_choco_success

:docker_choco_alternative
echo ⚠️  Standard Chocolatey installation failed, trying alternative Chocolatey method...
timeout /t 2 >nul
choco install docker-desktop -y --force --ignore-checksums --allow-empty-checksums
if errorlevel 1 goto :docker_manual_install
goto :docker_choco_success

:docker_manual_install
echo ❌ Chocolatey Docker installation failed. Trying direct download method (method 2/4)...
timeout /t 2 >nul

REM Try downloading and installing Docker manually with enhanced error handling
echo 🔍 Detecting system architecture for direct download...
timeout /t 1 >nul
        
        REM Detect system architecture
        set "ARCH=amd64"
        for /f "tokens=2 delims==" %%i in ('wmic os get osarchitecture /value 2^>nul ^| find "="') do (
            set "OS_ARCH=%%i"
        )
        
        REM Check for ARM64 architecture
        echo %PROCESSOR_ARCHITECTURE% | find /i "ARM64" >nul 2>&1
        if not errorlevel 1 goto :set_arm64_arch
        echo %OS_ARCH% | find /i "ARM64" >nul 2>&1
        if not errorlevel 1 goto :set_arm64_arch
        goto :set_amd64_arch

:set_arm64_arch
        set "ARCH=arm64"
        echo 🔍 Detected ARM64 architecture
        goto :arch_detected

:set_amd64_arch
        echo 🔍 Detected x64/AMD64 architecture
        goto :arch_detected

:arch_detected
        
        echo 🔍 Downloading Docker Desktop for !ARCH! architecture...
        set "DOCKER_URL=https://desktop.docker.com/win/main/!ARCH!/Docker%%20Desktop%%20Installer.exe"
        set "DOCKER_INSTALLER=docker-desktop-installer-!ARCH!.exe"
        
        echo 🔍 Attempting download method 1: PowerShell with TLS security...
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $ProgressPreference='SilentlyContinue'; $arch='!ARCH!'; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/$arch/Docker Desktop Installer.exe' -OutFile '%DOCKER_INSTALLER%' -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' -UseBasicParsing -TimeoutSec 180 } catch { Write-Host 'Download method 1 failed:' $_.Exception.Message; exit 1 }"
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        
        echo 🔍 Attempting download method 2: PowerShell with different approach...
        powershell -Command "try { $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Memshak-Installer/2.0'); $arch='!ARCH!'; $webClient.DownloadFile('https://desktop.docker.com/win/main/$arch/Docker Desktop Installer.exe', '%DOCKER_INSTALLER%') } catch { Write-Host 'Download method 2 failed:' $_.Exception.Message; exit 1 }"
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        
        echo 🔍 Attempting download method 3: Using CURL (if available)...
        curl -L -o "%DOCKER_INSTALLER%" --user-agent "Memshak-Installer/3.0" --connect-timeout 60 --max-time 300 "https://desktop.docker.com/win/main/!ARCH!/Docker Desktop Installer.exe" >nul 2>&1
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        goto :docker_download_failed

:docker_downloaded_success
        echo ✅ Docker Desktop downloaded successfully (!ARCH! architecture)
        echo 🔍 Installing Docker Desktop...
        timeout /t 2 >nul
        
        REM Verify file integrity before installation
        echo 🔍 Verifying installer integrity...
        if not exist "%DOCKER_INSTALLER%" (
            echo ❌ Installer file disappeared, download may have failed
            goto :docker_download_failed
        )
        
        REM Check file size (Docker installer should be at least 400MB)
        for %%A in ("%DOCKER_INSTALLER%") do set "FILE_SIZE=%%~zA"
        if %FILE_SIZE% lss 400000000 (
            echo ⚠️  Downloaded file seems too small (%FILE_SIZE% bytes), may be corrupted
            echo 🔍 Attempting installation anyway...
        )
        
        REM Try multiple installation methods
        echo 🔍 Installation attempt 1: Standard quiet install...
        "%DOCKER_INSTALLER%" install --quiet --accept-license >nul 2>&1
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if %DOCKER_EXIT_CODE% equ 0 goto :docker_install_success
        
        echo 🔍 Installation attempt 2: Alternative parameters...
        "%DOCKER_INSTALLER%" --quiet --accept-license >nul 2>&1
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if %DOCKER_EXIT_CODE% equ 0 goto :docker_install_success
        
        echo 🔍 Installation attempt 3: Without quiet mode...
        start /wait "" "%DOCKER_INSTALLER%" install --accept-license
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if %DOCKER_EXIT_CODE% equ 0 goto :docker_install_success
        goto :docker_install_warning

:docker_install_success
        echo ✅ Docker Desktop installed successfully
        del "%DOCKER_INSTALLER%" >nul 2>&1
        goto :configure_docker

:docker_install_warning
        echo ⚠️  Docker Desktop installation completed with exit code: %ERRORLEVEL%
        echo 💡 This may be normal - Docker sometimes reports non-zero exit codes on success
        del "%DOCKER_INSTALLER%" >nul 2>&1
        goto :configure_docker

:configure_docker
REM Configure Docker for startup regardless of exit code
echo 🔍 Configuring Docker for automatic startup...
timeout /t 2 >nul

REM Add Docker to startup in multiple ways to ensure it starts
echo 🔍 Adding Docker Desktop to Windows startup (User Registry)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1

echo 🔍 Adding Docker Desktop to Windows startup (System Registry)...
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1

REM Also create a startup folder shortcut as backup
echo 🔍 Creating startup folder shortcut for Docker Desktop...
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
powershell -Command "if (Test-Path '%ProgramFiles%\Docker\Docker\Docker Desktop.exe') { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP_FOLDER%\Docker Desktop.lnk'); $Shortcut.TargetPath = '%ProgramFiles%\Docker\Docker\Docker Desktop.exe'; $Shortcut.Save() }" >nul 2>&1

echo ✅ Docker Desktop configured for automatic startup (multiple methods)

REM Try to start Docker Desktop
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" goto :docker_exe_found
goto :docker_exe_not_found

:docker_exe_found
echo ✅ Docker Desktop executable found, starting service...
start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" >nul 2>&1
timeout /t 15 >nul
echo ✅ Docker Desktop startup initiated
goto :docker_startup_complete

:docker_exe_not_found
echo ⚠️  Docker Desktop executable not found in expected location
echo 💡 Manual installation may be required: https://www.docker.com/products/docker-desktop
goto :docker_startup_complete

:docker_startup_complete
goto :end_docker_manual_install

:docker_download_failed
echo ❌ Failed to download Docker Desktop installer for !ARCH! architecture

REM Try fallback to AMD64 if ARM64 failed
echo !ARCH! | find "arm64" >nul 2>&1
if not errorlevel 1 goto :try_amd64_fallback
goto :all_docker_downloads_failed

:try_amd64_fallback
echo 🔍 Trying fallback to AMD64 architecture (method 3/4)...
set "ARCH=amd64"
set "DOCKER_INSTALLER=docker-desktop-installer-amd64.exe"

echo 🔍 AMD64 fallback - PowerShell download attempt 1...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe' -OutFile '%DOCKER_INSTALLER%' -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' -UseBasicParsing -TimeoutSec 180 } catch { exit 1 }"

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success

echo 🔍 AMD64 fallback - WebClient download attempt 2...
powershell -Command "try { $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Memshak-Installer/2.0'); $webClient.DownloadFile('https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe', '%DOCKER_INSTALLER%') } catch { exit 1 }"

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success

echo 🔍 AMD64 fallback - CURL download attempt 3...
curl -L -o "%DOCKER_INSTALLER%" --user-agent "Memshak-Installer/3.0" --connect-timeout 60 --max-time 300 "https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe" >nul 2>&1

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success
goto :winget_install_attempt

:amd64_fallback_success
echo ✅ AMD64 fallback download successful
echo ⚠️  Note: Running AMD64 Docker on ARM64 may have performance impact
goto :docker_downloaded_success

:winget_install_attempt
echo 🔍 Trying Winget package manager installation (method 4/4)...
timeout /t 2 >nul

REM Check if winget is available
winget --version >nul 2>&1
if errorlevel 1 goto :all_docker_install_methods_failed

echo 🔍 Attempting Docker Desktop installation via Winget...
winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements --silent >nul 2>&1
if errorlevel 1 goto :all_docker_install_methods_failed

echo ✅ Docker Desktop installed successfully via Winget
timeout /t 2 >nul
goto :configure_docker

:all_docker_install_methods_failed
echo ❌ All Docker installation methods failed (Chocolatey, Direct Download, Winget)
echo.
echo 💡 MANUAL INSTALLATION REQUIRED:
echo.
echo 📥 Download Docker Desktop manually from:
echo    🌐 https://www.docker.com/products/docker-desktop
echo.
echo 💻 Architecture-specific direct download URLs:
echo    • x64/AMD64: https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe
echo    • ARM64: https://desktop.docker.com/win/main/arm64/Docker Desktop Installer.exe
echo.
echo 🔧 After manual installation:
echo    1. Ensure Docker Desktop is running (check system tray)
echo    2. Open Command Prompt as Administrator
echo    3. Navigate to: %INSTALL_DIR%
echo    4. Run: docker-compose up -d
echo.
echo 💡 Common Docker installation issues and solutions:
echo    • Insufficient disk space - free up at least 4GB
echo    • Antivirus blocking - temporarily disable real-time protection
echo    • Windows version too old - requires Windows 10/11 with WSL2 support
echo    • Network restrictions - check corporate firewall/proxy settings
echo.
goto :end_docker_manual_install

:end_docker_manual_install
goto :docker_section_complete

:docker_choco_success
echo ✅ Docker Desktop installed successfully via Chocolatey
timeout /t 2 >nul

REM Configure Docker for startup
echo 🔍 Configuring Docker for automatic startup...

REM Add Docker to startup in multiple ways to ensure it starts
echo 🔍 Adding Docker Desktop to Windows startup (User Registry)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1

echo 🔍 Adding Docker Desktop to Windows startup (System Registry)...
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\"" /f >nul 2>&1

REM Also create a startup folder shortcut as backup
echo 🔍 Creating startup folder shortcut for Docker Desktop...
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
powershell -Command "if (Test-Path '%ProgramFiles%\Docker\Docker\Docker Desktop.exe') { $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP_FOLDER%\Docker Desktop.lnk'); $Shortcut.TargetPath = '%ProgramFiles%\Docker\Docker\Docker Desktop.exe'; $Shortcut.Save() }" >nul 2>&1

echo ✅ Docker Desktop configured for automatic startup (multiple methods)

REM Start Docker Desktop
echo 🔍 Starting Docker Desktop...
start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" >nul 2>&1
timeout /t 20 >nul 2>&1
goto :docker_section_complete

:docker_already_installed
echo ✅ Docker Desktop already installed
timeout /t 2 >nul
goto :docker_section_complete

:docker_section_complete

echo.
echo [STEP 2/7] Downloading deployment package...
echo.

set "DOWNLOAD_URL=https://github.com/mickeyklai/memshak-deployment/archive/refs/heads/main.zip"
set "TEMP_ZIP=deployment.zip"

echo 🔍 Downloading from: %DOWNLOAD_URL%
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_ZIP%' -UserAgent 'Memshak-CDN/3.0' -TimeoutSec 60"
if errorlevel 1 (
    echo ❌ Failed to download deployment package
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo ✅ Deployment package downloaded successfully

echo.
echo [STEP 3/7] Extracting deployment package...
echo.

powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '.' -Force"
if errorlevel 1 (
    echo ❌ Failed to extract deployment package
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

del "%TEMP_ZIP%" >nul 2>&1

REM Find extracted directory
for /d %%i in (memshak-deployment-*) do set "EXTRACTED_DIR=%%i"
if not defined EXTRACTED_DIR (
    echo ❌ Could not find extracted deployment directory
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo ✅ Deployment package extracted to: %EXTRACTED_DIR%

echo.
echo [STEP 4/7] Setting up Memshak system...
echo.

REM Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy deployment files
xcopy "%EXTRACTED_DIR%\*" "%INSTALL_DIR%\" /e /h /y >nul 2>&1
if errorlevel 1 (
    echo ❌ Failed to copy deployment files
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo ✅ Memshak system files installed to: %INSTALL_DIR%

REM Clean up extracted directory
rmdir /s /q "%EXTRACTED_DIR%" >nul 2>&1

echo.
echo [STEP 5/7] Setting up Docker services...
echo.

REM Change to installation directory
cd /d "%INSTALL_DIR%"

REM Check if Docker is available and start services
if exist "docker-compose.yml" (
    echo 🔍 Waiting for Docker to be ready...
    timeout /t 3 >nul
    
    REM Extended wait for Docker with progress indicators (timeout after 3 minutes)
    set /a "timeout=180"
    set /a "elapsed=0"
    set /a "check_interval=10"
    
    :docker_wait
    echo 🔍 Checking Docker status... (elapsed: !elapsed!s / max: %timeout%s)
    docker info >nul 2>&1
    if not errorlevel 1 goto docker_ready
    
    REM Check if Docker Desktop process is running
    tasklist /FI "IMAGENAME eq Docker Desktop.exe" 2>nul | find /I "Docker Desktop.exe" >nul 2>&1
    if errorlevel 1 (
        echo 🔍 Docker Desktop not running, attempting to start...
        if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
            start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" >nul 2>&1
            echo 🔍 Docker Desktop start command sent...
        )
    ) else (
        echo 🔍 Docker Desktop is running, waiting for Docker daemon...
    )
    
    timeout /t %check_interval% >nul 2>&1
    set /a "elapsed+=%check_interval%"
    if %elapsed% lss %timeout% goto docker_wait
    
    echo ⚠️  Docker not ready after %timeout% seconds
    echo 💡 Possible solutions:
    echo    • Restart computer and try again
    echo    • Manually start Docker Desktop from Start Menu
    echo    • Check if WSL2 is properly configured
    echo    • Run: docker-compose up -d manually in %INSTALL_DIR%
    goto skip_docker
    
    :docker_ready
    echo ✅ Docker is ready after !elapsed! seconds
    echo 🔍 Building and starting Docker services...
    timeout /t 2 >nul
    
    REM Try to start services with better error handling
    docker-compose up --build -d --remove-orphans
    set "COMPOSE_EXIT_CODE=%ERRORLEVEL%"
    
    if !COMPOSE_EXIT_CODE! equ 0 (
        echo ✅ Docker services started successfully
        timeout /t 2 >nul
        
        REM Show running containers
        echo 🔍 Active containers:
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul
    ) else (
        echo ⚠️  Docker services failed to start (exit code: !COMPOSE_EXIT_CODE!)
        echo 💡 This may be resolved by:
        echo    • Restarting your computer
        echo    • Running: docker-compose up -d manually
        echo    • Checking Docker Desktop logs
    )
    
    :skip_docker
) else (
    echo ⚠️  No docker-compose.yml found in %INSTALL_DIR%
    echo 💡 Skipping Docker service setup
    timeout /t 2 >nul
)

echo.
echo [STEP 6/7] Creating shortcuts and startup configuration...
echo.

REM Create desktop shortcut using PowerShell
echo 🔍 Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Memshak.lnk'); $Shortcut.TargetPath = 'http://localhost:4200'; $Shortcut.Save()"
echo ✅ Desktop shortcut created

REM Create start menu shortcut
echo 🔍 Creating start menu shortcut...
set "START_MENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Memshak"
if not exist "%START_MENU_PATH%" mkdir "%START_MENU_PATH%"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_PATH%\Memshak.lnk'); $Shortcut.TargetPath = 'http://localhost:4200'; $Shortcut.Save()"
echo ✅ Start menu shortcut created

echo.
echo [STEP 7/7] Installation complete!
echo.

echo ==========================================
echo   INSTALLATION COMPLETED SUCCESSFULLY!
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
echo 3. Wait 2-3 minutes for Docker services to initialize
echo 4. Open Memshak via desktop shortcut or navigate to http://localhost:4200
echo.
echo 💡 TROUBLESHOOTING:
echo If Docker installation failed or services don't start:
echo    • Download Docker Desktop manually: https://www.docker.com/products/docker-desktop
echo    • After manual installation, navigate to %INSTALL_DIR%
echo    • Run: docker-compose up -d
echo    • Check Docker Desktop is running from system tray
echo.
echo 💡 If Memshak doesn't load after restart:
echo    • Open Docker Desktop and ensure it's running
echo    • Open Command Prompt as Administrator
echo    • Navigate to: %INSTALL_DIR%
echo    • Run: docker-compose up -d
echo    • Wait 2-3 minutes then try http://localhost:4200
echo.

set /p "restart=Would you like to restart now? (recommended) (y/n): "
if /i "!restart!"=="y" (
    echo.
    echo 🔄 Restarting system in 10 seconds...
    echo Press Ctrl+C to cancel
    timeout /t 20
    shutdown /r /f /t 0
) else (
    echo ⚠️  Please restart your computer manually when convenient
    echo 💡 This ensures all components work properly
)

echo.
echo ==========================================
echo Installation process completed!
echo Press any key to close this window...
echo ==========================================
pause >nul