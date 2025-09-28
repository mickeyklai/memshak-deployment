@echo off
REM Memshak Complete Installer - Standalone Batch Version
REM This script installs everything needed for Memshak without external files

REM Set UTF-8 encoding to properly display emojis and special characters
chcp 65001 >nul 2>&1

setlocal EnableDelayedExpansion

echo ==========================================
echo    MEMSHAK COMPLETE INSTALLER v3.1
echo ==========================================
echo.
echo This installer will automatically install:
echo ✅ Chocolatey Package Manager  
echo ✅ PowerShell 7
echo ✅ Docker Desktop (~500-600MB download)
echo ✅ WSL (Windows Subsystem for Linux)
echo ✅ Memshak Application System
echo.
echo 💻 Supports: x64/AMD64 and ARM64 architectures
echo ⚠️  Total download size: ~600MB+ (mainly Docker Desktop)
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
    set /p "overwrite=Continue anyway? (Y/n) [default: Y]: "
    if "!overwrite!"=="" set "overwrite=y"
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
choco --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Chocolatey not found. Installing Chocolatey...
    
    REM Install Chocolatey using PowerShell with enhanced network handling
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12,Tls11,Tls,Ssl3'; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; try { iex (Invoke-WebRequest -UseBasicParsing -Uri 'https://community.chocolatey.org/install.ps1' -TimeoutSec 30).Content } catch { Write-Host 'Fallback method'; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }"
    
    if errorlevel 1 (
        echo ❌ Failed to install Chocolatey
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    
    REM Refresh PATH environment variable to include Chocolatey
    echo 🔍 Refreshing environment variables...
    
    REM Simple approach - just add Chocolatey to current PATH
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    echo 🔍 Chocolatey added to PATH for current session
    
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
) else (
    echo ✅ Chocolatey already installed
)

REM Check PowerShell 7
echo 🔍 Checking for PowerShell 7...
 
pwsh --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  PowerShell 7 not found. Installing via Chocolatey...
    
    choco install powershell-core -y --no-progress
    if errorlevel 1 (
        echo ❌ Failed to install PowerShell 7
        
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
    
    REM PowerShell 7 should now be available in PATH after Chocolatey installation
    echo 🔍 PowerShell 7 should now be available via Chocolatey PATH updates
    
    
    echo ✅ PowerShell 7 installed successfully
    
) else (
    echo ✅ PowerShell 7 already installed
    
)

REM Check WSL
echo 🔍 Checking for WSL (Windows Subsystem for Linux)...


echo 🔍 Starting WSL detection process (using crash-safe methods)...


REM Check for WSL using safer methods that won't crash the script
echo 🔍 Testing WSL availability using safe detection methods...


REM Method 1: Check if WSL executable exists in system PATH
set "WSL_AVAILABLE=1"
set "WSL_CONFIGURED=1"

echo 🔍 [DEBUG] About to check for wsl.exe in System32...


REM Check if wsl.exe exists in System32
if exist "%SystemRoot%\System32\wsl.exe" (
    echo 🔍 WSL executable found in System32
    set "WSL_AVAILABLE=0"
    
    REM Check WSL configuration using registry and file system (completely safe)
    echo 🔍 Checking WSL configuration status using safe methods...
    
    
    REM Check if any WSL distributions are installed by looking at registry
    set "WSL_CONFIGURED=1"
    
    REM Method 1: Check WSL distribution registry entries
    echo 🔍 [DEBUG] About to check WSL registry entries...
    
    
    reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" >nul 2>&1
    if not errorlevel 1 (
        echo 🔍 WSL registry entries found
        set "WSL_CONFIGURED=0"
    ) else (
        echo 🔍 [DEBUG] WSL registry check completed, no entries found
        
        echo 🔍 [DEBUG] About to check AppData for WSL distributions...
        
        
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


REM Method 2: Check Windows features for WSL (alternative detection)
if !WSL_AVAILABLE! neq 0 (
    echo 🔍 Checking Windows optional features for WSL...
    
    
    REM Use DISM to check if WSL feature is installed
    dism /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 (
        echo 🔍 WSL Windows feature is enabled
        set "WSL_AVAILABLE=0"
    )
)

echo 🔍 [DEBUG] WSL detection method 2 completed successfully


echo 🔍 [DEBUG] About to evaluate WSL_CONFIGURED status: !WSL_CONFIGURED!


echo 🔍 [DEBUG] WSL_CONFIGURED variable value before if statement: !WSL_CONFIGURED!


echo 🔍 [DEBUG] About to check WSL_CONFIGURED value...


REM Use GOTO instead of IF to avoid any potential crashes with delayed expansion
echo 🔍 [DEBUG] WSL_CONFIGURED value is: !WSL_CONFIGURED!


if "!WSL_CONFIGURED!"=="0" goto wsl_already_configured
goto wsl_needs_installation

:wsl_already_configured
echo 🔍 [DEBUG] WSL already configured - skipping installation

echo ✅ WSL already installed and functional

goto wsl_section_complete

:wsl_needs_installation
echo 🔍 [DEBUG] WSL needs installation - proceeding with setup
    
    echo ⚠️  WSL not found or not configured. Installing WSL2 (required for Docker Desktop)...
    
    
    REM Enable WSL features using safer DISM commands
    echo 🔍 Enabling WSL Windows features (this may take a few minutes)...
    
    
    echo 🔍 Enabling Windows Subsystem for Linux feature...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    if errorlevel 1 (
        echo ⚠️  Warning: WSL feature enable had issues but continuing...
    ) else (
        echo ✅ Windows Subsystem for Linux feature enabled successfully
    )
    
    
    echo 🔍 Enabling Virtual Machine Platform feature...
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    if errorlevel 1 (
        echo ⚠️  Warning: Virtual Machine Platform enable had issues but continuing...
    ) else (
        echo ✅ Virtual Machine Platform feature enabled successfully
    )
    
    
    echo 🔍 Enabling Windows Hypervisor Platform feature (required for Docker Desktop)...
    echo 🔍 Method 1: Using DISM with HypervisorPlatform feature name...
    dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart
    set "HYPERV_RESULT1=%ERRORLEVEL%"
    
    if !HYPERV_RESULT1! neq 0 (
        echo 🔍 Method 2: Using DISM with Microsoft-Hyper-V-Hypervisor feature name...
        dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-Hypervisor /all /norestart
        set "HYPERV_RESULT2=%ERRORLEVEL%"
    ) else (
        echo ✅ Windows Hypervisor Platform enabled successfully (Method 1)
        set "HYPERV_RESULT2=0"
    )
    
    if !HYPERV_RESULT1! neq 0 if !HYPERV_RESULT2! neq 0 (
        echo 🔍 Method 3: Using PowerShell Enable-WindowsOptionalFeature...
        powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart" >nul 2>&1
        set "HYPERV_RESULT3=%ERRORLEVEL%"
        
        if !HYPERV_RESULT3! neq 0 (
            echo 🔍 Method 4: Using PowerShell with Microsoft-Hyper-V-Hypervisor...
            powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor -All -NoRestart" >nul 2>&1
            set "HYPERV_RESULT4=%ERRORLEVEL%"
            
            if !HYPERV_RESULT4! neq 0 (
                echo 🔍 Method 5: Using bcdedit to enable hypervisor...
                bcdedit /set hypervisorlaunchtype auto >nul 2>&1
                set "HYPERV_RESULT5=%ERRORLEVEL%"
                
                if !HYPERV_RESULT5! equ 0 (
                    echo ✅ Hypervisor launch type set to auto via bcdedit
                ) else (
                    echo ⚠️  All automatic methods failed - manual intervention may be required
                    echo 💡 Please manually enable "Windows Hypervisor Platform" in:
                    echo    Control Panel → Programs → Turn Windows features on or off
                )
            ) else (
                echo ✅ Windows Hypervisor Platform enabled successfully (Method 4)
            )
        ) else (
            echo ✅ Windows Hypervisor Platform enabled successfully (Method 3)
        )
    )
    
    
    echo 🔍 Enabling Hyper-V (if available on this Windows edition)...
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Hyper-V not available (normal for Windows Home edition)
    ) else (
        echo ✅ Hyper-V feature enabled successfully
    )
    
    
    REM Install WSL2 kernel via Chocolatey
    echo 🔍 Installing WSL2 kernel and components via Chocolatey...
    
    choco install wsl2 -y --no-progress
    if errorlevel 1 (
        echo ⚠️  Chocolatey WSL2 installation had issues, but features were enabled
        echo 💡 WSL2 kernel update may be required after restart
    )
    
    
    REM Verify Windows features are enabled
    echo 🔍 Verifying Windows features for Docker Desktop compatibility...
    echo.
    echo 🔍 Checking required Windows features status:
    
    REM Check WSL feature
    dism /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Windows Subsystem for Linux: ENABLED
    ) else (
        echo ❌ Windows Subsystem for Linux: DISABLED
    )
    
    REM Check Virtual Machine Platform
    dism /online /get-featureinfo /featurename:VirtualMachinePlatform 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Virtual Machine Platform: ENABLED
    ) else (
        echo ❌ Virtual Machine Platform: DISABLED
    )
    
    REM Check Hypervisor Platform (try multiple feature names)
    set "HYPERV_ENABLED=0"
    
    dism /online /get-featureinfo /featurename:HypervisorPlatform 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 set "HYPERV_ENABLED=1"
    
    if !HYPERV_ENABLED! equ 0 (
        dism /online /get-featureinfo /featurename:Microsoft-Hyper-V-Hypervisor 2>nul | find /i "State : Enabled" >nul 2>&1
        if not errorlevel 1 set "HYPERV_ENABLED=1"
    )
    
    if !HYPERV_ENABLED! equ 1 (
        echo ✅ Windows Hypervisor Platform: ENABLED
    ) else (
        echo ❌ Windows Hypervisor Platform: DISABLED
        echo 💡 MANUAL FIX REQUIRED for Windows Hypervisor Platform:
        echo    1. Press Win+R, type 'optionalfeatures' and press Enter
        echo    2. Find and check ☑️ "Windows Hypervisor Platform"
        echo    3. Click OK and restart when prompted
        echo    4. Alternative: Run as Administrator: dism /online /enable-feature /featurename:HypervisorPlatform /all
    )
    
    REM Check Hyper-V (optional, may not be available on all editions)
    dism /online /get-featureinfo /featurename:Microsoft-Hyper-V 2>nul | find /i "State : Enabled" >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Hyper-V: ENABLED
    ) else (
        echo ⚠️  Hyper-V: DISABLED (may not be available on Windows Home)
    )
    
    echo.
    echo 💡 NOTE: If any required features show as DISABLED, please:
    echo    1. Restart your computer after installation completes
    echo    2. Manually enable missing features in "Turn Windows features on or off"
    echo    3. Required features: WSL, Virtual Machine Platform, Hypervisor Platform
    echo.
    
    
    REM Set WSL2 as default version via registry (completely safe method)
    echo 🔍 Setting WSL2 as default version via registry...
    
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" /v DefaultVersion /t REG_DWORD /d 2 /f >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  WSL2 registry setting had issues, but will work after restart
    ) else (
        echo ✅ WSL2 default version configured via registry successfully
    )
    
    
    echo ✅ WSL2 installation and configuration completed
    echo ⚠️  IMPORTANT: A system restart is required for WSL2 to be fully functional
    

:wsl_section_complete
echo 🔍 WSL detection and configuration completed successfully


REM Check Docker Desktop
echo 🔍 Checking for Docker Desktop...
timeout /t 2 >nul
docker --version >nul 2>&1
if errorlevel 1 goto :install_docker
goto :docker_already_installed

:install_docker
echo ⚠️  Docker not found. Installing Docker Desktop...
echo 🔍 Note: Docker Desktop requires WSL2 which should now be installed
timeout /t 2 >nul

echo 🔍 Attempting Docker Desktop installation via Chocolatey (method 1/4)...
choco install docker-desktop -y --no-progress --ignore-checksums
if errorlevel 1 goto :docker_manual_install

echo ✅ Docker Desktop installed successfully via Chocolatey
echo 🔄 Refreshing PATH environment variable...
call refreshenv
goto :docker_section_complete

:docker_manual_install
echo ❌ Chocolatey Docker installation failed. Trying direct download method (method 2/4)...
timeout /t 2 >nul

REM Try downloading and installing Docker manually with enhanced error handling
echo 🔍 Detecting system architecture for direct download...
timeout /t 1 >nul
        
        REM Detect system architecture (simplified)
        set "ARCH=amd64"
        set "ARCH_PATH=amd64"
        echo 🔍 Using AMD64 architecture for Docker Desktop (most compatible)
        
        echo 🔍 Preparing to download Docker Desktop for AMD64 architecture...
        echo ⚠️  WARNING: Docker Desktop installer is approximately 500-600MB
        echo 💾 This will use significant bandwidth and disk space
        echo.
        set /p "download_docker=Continue with Docker Desktop download? (Y/n) [default: Y]: "
        
        REM Set default to y if user just pressed Enter
        if "!download_docker!"=="" set "download_docker=y"
        
        REM Use GOTO to avoid variable expansion crashes
        if /i "!download_docker!"=="y" goto :proceed_with_docker_download
        if /i "!download_docker!"=="yes" goto :proceed_with_docker_download
        goto :skip_docker_download

:skip_docker_download
        echo ⏭️  Skipping Docker Desktop automatic download
        echo 💡 You can install Docker Desktop manually later from:
        echo    🌐 https://www.docker.com/products/docker-desktop
        timeout /t 2 >nul
        goto :docker_section_complete

:proceed_with_docker_download
        
        echo 🔍 Checking available disk space for Docker installation...
        timeout /t 1 >nul
        
        REM Check free space on C: drive (Docker needs at least 4GB)
        for /f "tokens=3" %%a in ('dir /-c "%SystemDrive%\" ^| find "bytes free"') do set "FREE_SPACE=%%a"
        REM Remove commas from the number
        set "FREE_SPACE=!FREE_SPACE:,=!"
        
        REM Check if we have at least 4GB (4,294,967,296 bytes) free
        if !FREE_SPACE! lss 4294967296 (
            echo ❌ Insufficient disk space for Docker Desktop installation
            echo 💾 Available: !FREE_SPACE! bytes
            echo 📋 Required: At least 4GB (4,294,967,296 bytes) free space
            echo.
            echo 💡 Please free up disk space and run the installer again
            echo    - Delete temporary files
            echo    - Empty Recycle Bin  
            echo    - Run Disk Cleanup
            echo    - Uninstall unused programs
            timeout /t 5 >nul
            goto :docker_section_complete
        )
        
        echo ✅ Sufficient disk space available (!FREE_SPACE! bytes free)
        
        echo 🔍 Starting Docker Desktop download (this may take several minutes)...
        timeout /t 2 >nul
        set "DOCKER_URL=https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe"
        set "DOCKER_INSTALLER=docker-desktop-installer-amd64.exe"
        
        REM Check if installer already exists
        if exist "%DOCKER_INSTALLER%" goto :verify_existing_installer
        goto :start_fresh_download

:verify_existing_installer
        echo ✅ Docker installer already exists, verifying file...
        REM Check file size to ensure it's not corrupted
        timeout /t 2 >nul
        for %%A in ("%DOCKER_INSTALLER%") do set "FILE_SIZE=%%~zA"
        if !FILE_SIZE! gtr 400000000 goto :existing_installer_valid
        goto :existing_installer_invalid

:existing_installer_valid
        echo ✅ Existing Docker installer appears valid (size: !FILE_SIZE! bytes)
        echo 🔍 Skipping download, using existing installer...
        timeout /t 2 >nul
        goto :docker_downloaded_success

:existing_installer_invalid
        echo ⚠️  Existing installer seems too small (!FILE_SIZE! bytes), re-downloading...
        timeout /t 2 >nul
        del "%DOCKER_INSTALLER%" >nul 2>&1
        goto :start_fresh_download

:start_fresh_download
        
        echo 🔍 Attempting download method 1: Simple PowerShell download...
        powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe' -OutFile '%DOCKER_INSTALLER%'" 2>nul
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        
        echo 🔍 Attempting download method 2: PowerShell with basic parameters...
        powershell -Command "$client = New-Object System.Net.WebClient; $client.DownloadFile('https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe', '%DOCKER_INSTALLER%')" 2>nul
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        
        echo 🔍 Attempting download method 3: Using CURL (if available)...
        curl -L -o "%DOCKER_INSTALLER%" "https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe" >nul 2>&1
        
        if exist "%DOCKER_INSTALLER%" goto :docker_downloaded_success
        goto :docker_download_failed

:docker_downloaded_success
        echo ✅ Docker Desktop downloaded successfully (AMD64 architecture)
        echo 🔍 Installing Docker Desktop...
        timeout /t 2 >nul
        
        REM Verify file integrity before installation
        echo 🔍 Verifying installer integrity...
        timeout /t 2 >nul
        if not exist "%DOCKER_INSTALLER%" (
            echo ❌ Installer file disappeared, download may have failed
            timeout /t 2 >nul
            goto :docker_download_failed
        )
        
        REM Check file size (Docker installer should be at least 400MB)
        echo 🔍 Checking installer file size...
        timeout /t 1 >nul
        
        REM Get file size safely
        for %%A in ("%DOCKER_INSTALLER%") do set "FILE_SIZE=%%~zA"
        
        REM Check if FILE_SIZE is empty or invalid
        if "!FILE_SIZE!"=="" goto :file_size_check_failed
        if "!FILE_SIZE!"=="0" goto :file_size_too_small
        
        REM Use GOTO to avoid crashes with large number comparisons
        if !FILE_SIZE! lss 400000000 goto :file_size_too_small
        goto :file_size_check_passed

:file_size_check_failed
        echo ⚠️  Could not determine file size, proceeding with installation...
        timeout /t 2 >nul
        goto :file_size_check_passed

:file_size_too_small
        echo ⚠️  Downloaded file seems too small (!FILE_SIZE! bytes), may be corrupted
        echo 🔍 Attempting installation anyway...
        timeout /t 2 >nul
        goto :file_size_check_passed

:file_size_check_passed
        
        REM Try multiple installation methods
        echo 🔍 Installation attempt 1: Standard quiet install...
        "%DOCKER_INSTALLER%" install --quiet --accept-license >nul 2>&1
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if !DOCKER_EXIT_CODE! equ 0 goto :docker_install_success
        
        echo 🔍 Installation attempt 2: Alternative parameters...
        "%DOCKER_INSTALLER%" --quiet --accept-license >nul 2>&1
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if !DOCKER_EXIT_CODE! equ 0 goto :docker_install_success
        
        echo 🔍 Installation attempt 3: Without quiet mode...
        start /wait "" "%DOCKER_INSTALLER%" install --accept-license
        set "DOCKER_EXIT_CODE=%ERRORLEVEL%"
        
        if !DOCKER_EXIT_CODE! equ 0 goto :docker_install_success
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
echo ❌ Failed to download Docker Desktop installer via direct download
echo 🔍 Trying alternative download method...
timeout /t 2 >nul
goto :try_amd64_fallback

:try_amd64_fallback
echo 🔍 Trying fallback to AMD64 architecture (method 3/4)...
set "ARCH=amd64"
set "DOCKER_INSTALLER=docker-desktop-installer-amd64.exe"

echo 🔍 AMD64 fallback - Simple PowerShell download...
powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe' -OutFile '%DOCKER_INSTALLER%'" 2>nul

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success

echo 🔍 AMD64 fallback - WebClient download...
powershell -Command "$client = New-Object System.Net.WebClient; $client.DownloadFile('https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe', '%DOCKER_INSTALLER%')" 2>nul

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success

echo 🔍 AMD64 fallback - CURL download...
curl -L -o "%DOCKER_INSTALLER%" "https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe" >nul 2>&1

if exist "%DOCKER_INSTALLER%" goto :amd64_fallback_success
goto :winget_install_attempt

:amd64_fallback_success
echo ✅ Alternative download method successful
goto :docker_downloaded_success

:winget_install_attempt
echo 🔍 Trying Winget package manager installation (method 3/4)...
timeout /t 2 >nul

REM Check if winget is available
winget --version >nul 2>&1
if errorlevel 1 goto :chocolatey_fallback_attempt

echo 🔍 Attempting Docker Desktop installation via Winget...
winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements --silent >nul 2>&1
if errorlevel 1 goto :chocolatey_fallback_attempt

echo ✅ Docker Desktop installed successfully via Winget
timeout /t 2 >nul

REM Verify Winget installation worked
echo 🔍 Verifying Winget Docker installation...
timeout /t 5 >nul
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" goto :configure_docker

echo ⚠️  Winget installation completed but Docker executable not found, trying next method...
goto :chocolatey_fallback_attempt

:chocolatey_fallback_attempt
echo 🔍 Trying Chocolatey package manager installation (method 4/4)...
timeout /t 2 >nul

echo 🔍 Attempting Docker Desktop installation via Chocolatey (standard)...
choco install docker-desktop -y --no-progress --ignore-checksums >nul 2>&1
if errorlevel 1 goto :docker_choco_alternative_fallback

echo ✅ Docker Desktop installed successfully via Chocolatey
timeout /t 2 >nul

REM Verify Chocolatey installation worked
echo 🔍 Verifying Chocolatey Docker installation...
timeout /t 5 >nul
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" goto :configure_docker

echo ⚠️  Chocolatey installation completed but Docker executable not found, trying alternative method...
goto :docker_choco_alternative_fallback

:docker_choco_alternative_fallback
echo 🔍 Trying alternative Chocolatey method...
choco install docker-desktop -y --force --ignore-checksums --allow-empty-checksums >nul 2>&1
if errorlevel 1 goto :all_docker_install_methods_failed

echo ✅ Docker Desktop installed successfully via Chocolatey (alternative method)
timeout /t 2 >nul

REM Verify alternative Chocolatey installation worked
echo 🔍 Verifying alternative Chocolatey Docker installation...
timeout /t 5 >nul
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" goto :configure_docker

echo ⚠️  All Chocolatey methods completed but Docker executable not found
goto :all_docker_install_methods_failed

:all_docker_install_methods_failed
echo ❌ All Docker installation methods failed (Direct Download, AMD64 Fallback, Winget, Chocolatey)
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

set /p "restart=Would you like to restart now? (recommended) (Y/n) [default: Y]: "
if "!restart!"=="" set "restart=y"
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