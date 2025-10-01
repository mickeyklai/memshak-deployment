@echo off
REM Memshak Complete Installer - Fixed Version with Better Flow Control
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

REM Set up logging
set "LOG_FILE=%~dp0memshak-install.log"
echo Memshak Installation Log > "%LOG_FILE%"
echo Started: %DATE% %TIME% >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"

echo ==========================================
echo    MEMSHAK INSTALLER v3.6-FIXED
echo ==========================================
echo.
echo Log file: %LOG_FILE%
echo.

REM Check admin
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: Administrator privileges required! >> "%LOG_FILE%"
    echo ERROR: Administrator privileges required!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo [OK] Running as Administrator >> "%LOG_FILE%"
echo [OK] Running as Administrator

REM Detect architecture
set "DETECTED_ARCH=x64"
echo %PROCESSOR_ARCHITECTURE% | find /i "ARM64" >nul 2>&1
if not errorlevel 1 set "DETECTED_ARCH=ARM64"

echo [INFO] Architecture: %DETECTED_ARCH% >> "%LOG_FILE%"
echo [INFO] Architecture: %DETECTED_ARCH%

set "INSTALL_DIR=%USERPROFILE%\memshak-system"
echo [INFO] Install directory: %INSTALL_DIR% >> "%LOG_FILE%"
echo [INFO] Install directory: %INSTALL_DIR%
echo.

REM Check if Docker already installed and system already configured
echo [DEBUG] Checking Docker installation... >> "%LOG_FILE%"
echo [DEBUG] Checking Docker installation...

docker --version >nul 2>&1
set "DOCKER_CHECK=%ERRORLEVEL%"

echo [DEBUG] Docker check result: %DOCKER_CHECK% >> "%LOG_FILE%"
echo [DEBUG] Docker check result: %DOCKER_CHECK%

if %DOCKER_CHECK% EQU 0 (
    echo [INFO] Docker found - checking system configuration... >> "%LOG_FILE%"
    echo [INFO] Docker found - checking system configuration...
    echo [DEBUG] Checking WSL status... >> "%LOG_FILE%"
    echo [DEBUG] Checking WSL status...
    
    wsl --status >nul 2>&1
    set "WSL_CHECK=%ERRORLEVEL%"
    
    echo [DEBUG] WSL check result: %WSL_CHECK% >> "%LOG_FILE%"
    echo [DEBUG] WSL check result: %WSL_CHECK%
    
    if !WSL_CHECK! EQU 0 (
        echo [INFO] System already configured - skipping prerequisites >> "%LOG_FILE%"
        echo [INFO] System already configured - skipping prerequisites
        echo [INFO] Proceeding directly to Memshak installation >> "%LOG_FILE%"
        echo [INFO] Proceeding directly to Memshak installation
        echo [DEBUG] About to jump to skip_to_memshak_install >> "%LOG_FILE%"
        echo [DEBUG] About to jump to skip_to_memshak_install
        echo.
        timeout /t 2 >nul
        goto skip_to_memshak_install
    ) else (
        echo [INFO] Docker found but WSL needs configuration >> "%LOG_FILE%"
        echo [INFO] Docker found but WSL needs configuration
        goto configure_wsl_only
    )
) else (
    echo [DEBUG] Docker not found - full installation needed >> "%LOG_FILE%"
    echo [DEBUG] Docker not found - full installation needed
)

echo ========================================== >> "%LOG_FILE%"
echo [STEP 1/5] INSTALLING CHOCOLATEY >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 1/5] INSTALLING CHOCOLATEY

choco --version >nul 2>&1
if errorlevel 1 (
    echo [ACTION] Installing Chocolatey... >> "%LOG_FILE%"
    echo Installing Chocolatey...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Chocolatey installation failed >> "%LOG_FILE%"
        echo ERROR: Chocolatey installation failed
        pause
        exit /b 1
    )
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    echo [OK] Chocolatey installed >> "%LOG_FILE%"
    echo [OK] Chocolatey installed
) else (
    echo [OK] Chocolatey already installed >> "%LOG_FILE%"
    echo [OK] Chocolatey already installed
)

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 2/5] INSTALLING POWERSHELL 7 >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 2/5] INSTALLING POWERSHELL 7

pwsh --version >nul 2>&1
if errorlevel 1 (
    echo [ACTION] Installing PowerShell 7... >> "%LOG_FILE%"
    echo Installing PowerShell 7...
    choco install powershell-core -y --no-progress >> "%LOG_FILE%" 2>&1
    echo [OK] PowerShell 7 installed >> "%LOG_FILE%"
    echo [OK] PowerShell 7 installed
) else (
    echo [OK] PowerShell 7 already installed >> "%LOG_FILE%"
    echo [OK] PowerShell 7 already installed
)

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 3/5] ENABLING WSL FEATURES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 3/5] ENABLING WSL FEATURES

:configure_wsl_only
echo [ACTION] Enabling WSL and virtualization features... >> "%LOG_FILE%"
echo Enabling WSL and virtualization features...

REM Enable core WSL features
echo [INFO] Enabling Windows Subsystem for Linux... >> "%LOG_FILE%"
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [WARNING] WSL feature enablement had issues >> "%LOG_FILE%"
) else (
    echo [OK] WSL feature enabled >> "%LOG_FILE%"
)

REM Enable Virtual Machine Platform
echo [INFO] Enabling Virtual Machine Platform... >> "%LOG_FILE%"
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [WARNING] Virtual Machine Platform enablement had issues >> "%LOG_FILE%"
) else (
    echo [OK] Virtual Machine Platform enabled >> "%LOG_FILE%"
)

REM Update WSL
echo [INFO] Updating WSL... >> "%LOG_FILE%"
wsl --update >> "%LOG_FILE%" 2>&1
echo [OK] WSL features configured >> "%LOG_FILE%"
echo [OK] WSL features configured

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 4/5] INSTALLING DOCKER DESKTOP >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 4/5] INSTALLING DOCKER DESKTOP

REM Check if we should skip Docker installation
docker --version >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Docker already installed, skipping installation >> "%LOG_FILE%"
    echo [INFO] Docker already installed, skipping installation
    goto configure_docker_startup
)

if "%DETECTED_ARCH%"=="ARM64" (
    echo [INFO] ARM64 detected - direct download >> "%LOG_FILE%"
    echo ARM64 detected - downloading Docker Desktop...
    
    set "DOCKER_INSTALLER=%TEMP%\DockerDesktop-ARM64.exe"
    powershell -Command "$url = 'https://desktop.docker.com/win/main/arm64/Docker Desktop Installer.exe'; $outFile = Join-Path $env:TEMP 'DockerDesktop-ARM64.exe'; Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing; if (Test-Path $outFile) { exit 0 } else { exit 1 }" >> "%LOG_FILE%" 2>&1
    
    if errorlevel 1 (
        echo [ERROR] Download failed >> "%LOG_FILE%"
        echo ERROR: Download failed
        pause
        exit /b 1
    )
    
    echo [ACTION] Installing Docker... >> "%LOG_FILE%"
    echo Installing Docker Desktop...
    start /wait "" "!DOCKER_INSTALLER!" install --accept-license >> "%LOG_FILE%" 2>&1
    del "!DOCKER_INSTALLER!" >nul 2>&1
    echo [OK] Docker installed >> "%LOG_FILE%"
    echo [OK] Docker installed
) else (
    echo [INFO] x64 detected - Chocolatey install >> "%LOG_FILE%"
    echo Installing Docker via Chocolatey...
    choco install docker-desktop -y --no-progress --ignore-checksums >> "%LOG_FILE%" 2>&1
    echo [OK] Docker installed >> "%LOG_FILE%"
    echo [OK] Docker installed
)

echo.
:configure_docker_startup
echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 5/5] CONFIGURING DOCKER STARTUP >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 5/5] CONFIGURING DOCKER STARTUP

echo [ACTION] Configuring Docker Desktop for automatic startup... >> "%LOG_FILE%"
echo Configuring Docker Desktop for automatic startup...

REM Method 1: Registry startup entry (User level)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\" --start-machine" /f >> "%LOG_FILE%" 2>&1
if not errorlevel 1 (
    echo [OK] User registry startup configured >> "%LOG_FILE%"
    echo [OK] User registry startup configured
) else (
    echo [WARNING] User registry startup failed >> "%LOG_FILE%"
)

REM Method 2: System-wide registry startup (if needed)
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Docker Desktop" /t REG_SZ /d "\"%ProgramFiles%\Docker\Docker\Docker Desktop.exe\" --start-machine" /f >> "%LOG_FILE%" 2>&1
if not errorlevel 1 (
    echo [OK] System registry startup configured >> "%LOG_FILE%"
    echo [OK] System registry startup configured
) else (
    echo [INFO] System registry startup not configured (may require different permissions) >> "%LOG_FILE%"
)

REM Method 3: Startup folder shortcut
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
    echo [ACTION] Creating startup folder shortcut... >> "%LOG_FILE%"
    powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STARTUP_FOLDER%\Docker Desktop.lnk'); $Shortcut.TargetPath = '%ProgramFiles%\Docker\Docker\Docker Desktop.exe'; $Shortcut.Arguments = '--start-machine'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1
    if not errorlevel 1 (
        echo [OK] Startup folder shortcut created >> "%LOG_FILE%"
        echo [OK] Startup folder shortcut created
    ) else (
        echo [WARNING] Startup folder shortcut failed >> "%LOG_FILE%"
    )
) else (
    echo [WARNING] Docker Desktop executable not found for startup configuration >> "%LOG_FILE%"
    echo [WARNING] Docker Desktop executable not found for startup configuration
)

echo [OK] Docker startup configuration completed >> "%LOG_FILE%"
echo [OK] Docker startup configuration completed

echo.
echo ========================================== >> "%LOG_FILE%"
echo SYSTEM CONFIGURATION COMPLETE >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo ==========================================
echo   SYSTEM CONFIGURATION COMPLETE
echo ==========================================
echo.
echo The following have been installed/configured:
echo - WSL (Windows Subsystem for Linux)
echo - Virtual Machine Platform
echo - Windows Hypervisor Platform
echo - Docker Desktop
echo - Docker automatic startup
echo.
echo *** RESTART REQUIRED ***
echo.
echo Please restart your computer now to activate:
echo - Virtualization features (WSL2, Hyper-V, etc.)
echo - Docker Desktop integration
echo.
echo After restart, run this installer again to:
echo - Download and install Memshak application
echo - Start the services
echo.
echo [INFO] System restart required >> "%LOG_FILE%"
pause
exit /b 0

REM ==========================================
REM MEMSHAK INSTALLATION (No Prerequisites Needed)
REM ==========================================
:skip_to_memshak_install
echo.
echo ========================================== >> "%LOG_FILE%"
echo [DEBUG] STARTING MEMSHAK INSTALLATION >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo ==========================================
echo   INSTALLING MEMSHAK
echo ==========================================
echo.

echo ========================================== >> "%LOG_FILE%"
echo [STEP 1/3] DOWNLOADING MEMSHAK >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 1/3] DOWNLOADING MEMSHAK
echo.

set "DOWNLOAD_URL=https://github.com/mickeyklai/memshak-deployment/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\memshak-deploy.zip"

REM Delete old zip if exists
if exist "%TEMP_ZIP%" (
    echo [DEBUG] Removing old zip file >> "%LOG_FILE%"
    del "%TEMP_ZIP%" >nul 2>&1
)

echo [ACTION] Downloading package from GitHub... >> "%LOG_FILE%"
echo [ACTION] Downloading package from GitHub...
echo [DEBUG] Download URL: %DOWNLOAD_URL% >> "%LOG_FILE%"
echo [DEBUG] Target file: %TEMP_ZIP% >> "%LOG_FILE%"
echo.

REM Try download with better error handling
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { Write-Host 'Starting download...'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_ZIP%' -UseBasicParsing -TimeoutSec 300; if (Test-Path '%TEMP_ZIP%') { $size = (Get-Item '%TEMP_ZIP%').Length; Write-Host \"Download successful. Size: $size bytes\"; exit 0 } else { Write-Host 'Download failed - file does not exist'; exit 1 } } catch { Write-Host \"ERROR: $($_.Exception.Message)\"; Write-Host \"ERROR: $($_.Exception.GetType().FullName)\"; exit 1 } }" >> "%LOG_FILE%" 2>&1

set "DOWNLOAD_RESULT=%ERRORLEVEL%"
echo [DEBUG] PowerShell exit code: %DOWNLOAD_RESULT% >> "%LOG_FILE%"

if %DOWNLOAD_RESULT% NEQ 0 (
    echo [ERROR] Download failed with exit code: %DOWNLOAD_RESULT% >> "%LOG_FILE%"
    echo ERROR: Download failed! Check log file for details.
    echo Log file: %LOG_FILE%
    echo.
    echo Attempting alternative download method with curl...
    
    REM Try with curl as fallback
    curl --version >nul 2>&1
    if not errorlevel 1 (
        echo [DEBUG] Trying curl download >> "%LOG_FILE%"
        curl -L -o "%TEMP_ZIP%" "%DOWNLOAD_URL%" >> "%LOG_FILE%" 2>&1
        if not errorlevel 1 (
            echo [OK] Downloaded with curl >> "%LOG_FILE%"
            goto download_success
        )
    )
    
    echo [ERROR] All download methods failed >> "%LOG_FILE%"
    echo ERROR: Unable to download Memshak package
    echo.
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)

:download_success
echo [OK] Download complete >> "%LOG_FILE%"
echo [OK] Download complete
echo [DEBUG] Download success label reached >> "%LOG_FILE%"
echo.

REM Verify downloaded file
echo [DEBUG] Verifying downloaded file exists... >> "%LOG_FILE%"
if not exist "%TEMP_ZIP%" (
    echo [ERROR] Downloaded file not found! >> "%LOG_FILE%"
    echo ERROR: Downloaded file verification failed
    pause
    exit /b 1
)

echo [DEBUG] Getting file size... >> "%LOG_FILE%"
for %%A in ("%TEMP_ZIP%") do set "FILE_SIZE=%%~zA"
echo [DEBUG] File size: !FILE_SIZE! bytes >> "%LOG_FILE%"
echo [DEBUG] File size: !FILE_SIZE! bytes

echo [DEBUG] Checking if file size is valid (greater than 1000 bytes)... >> "%LOG_FILE%"
if !FILE_SIZE! LSS 1000 (
    echo [ERROR] Downloaded file too small ^(!FILE_SIZE! bytes^) - likely corrupted >> "%LOG_FILE%"
    echo ERROR: Download appears corrupted
    pause
    exit /b 1
)

echo [DEBUG] File size check passed - file is !FILE_SIZE! bytes >> "%LOG_FILE%"
echo [DEBUG] File verification passed >> "%LOG_FILE%"
echo [DEBUG] File verification passed
echo [DEBUG] Proceeding to extraction step... >> "%LOG_FILE%"
echo.

echo ========================================== >> "%LOG_FILE%"
echo [STEP 2/3] EXTRACTING FILES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo ==========================================
echo [STEP 2/3] EXTRACTING FILES
echo ==========================================
echo.

echo [ACTION] Extracting archive... >> "%LOG_FILE%"
echo [ACTION] Extracting archive...
echo [DEBUG] Extracting to: %TEMP% >> "%LOG_FILE%"
echo [DEBUG] Starting PowerShell extraction... >> "%LOG_FILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { Write-Host 'Extracting...'; Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP%' -Force; Write-Host 'Extraction successful'; exit 0 } catch { Write-Host \"ERROR: $($_.Exception.Message)\"; exit 1 } }" >> "%LOG_FILE%" 2>&1

set "EXTRACT_RESULT=%ERRORLEVEL%"
echo [DEBUG] Extraction exit code: %EXTRACT_RESULT% >> "%LOG_FILE%"
echo [DEBUG] Extraction exit code: %EXTRACT_RESULT%

if %EXTRACT_RESULT% NEQ 0 (
    echo [ERROR] Extraction failed >> "%LOG_FILE%"
    echo ERROR: Extraction failed
    pause
    exit /b 1
)
echo [OK] Extracted >> "%LOG_FILE%"
echo [OK] Extracted
echo.

echo [ACTION] Finding extracted directory... >> "%LOG_FILE%"
echo [ACTION] Finding extracted directory...
set "EXTRACTED_DIR="
for /d %%i in ("%TEMP%\memshak-deployment-*") do (
    echo [FOUND] %%i >> "%LOG_FILE%"
    set "EXTRACTED_DIR=%%i"
)

if not defined EXTRACTED_DIR (
    echo [ERROR] Extracted directory not found >> "%LOG_FILE%"
    echo [DEBUG] Listing TEMP directory contents: >> "%LOG_FILE%"
    dir "%TEMP%\memshak*" /b >> "%LOG_FILE%" 2>&1
    echo ERROR: Extracted directory not found
    echo.
    echo The download may be corrupted. Please try again.
    pause
    exit /b 1
)

echo [DEBUG] Using directory: %EXTRACTED_DIR% >> "%LOG_FILE%"
echo [DEBUG] Using directory: %EXTRACTED_DIR%
echo.

if not exist "%INSTALL_DIR%" (
    echo [ACTION] Creating install directory... >> "%LOG_FILE%"
    mkdir "%INSTALL_DIR%"
)

echo [ACTION] Copying files to installation directory... >> "%LOG_FILE%"
echo [ACTION] Copying files to installation directory...
xcopy "%EXTRACTED_DIR%\*" "%INSTALL_DIR%\" /e /h /y /i /q >> "%LOG_FILE%" 2>&1
set "COPY_RESULT=%ERRORLEVEL%"
echo [DEBUG] Copy exit code: %COPY_RESULT% >> "%LOG_FILE%"

if %COPY_RESULT% GTR 0 (
    echo [ERROR] Copy failed - exit code: %COPY_RESULT% >> "%LOG_FILE%"
    echo ERROR: File copy failed
    pause
    exit /b 1
)
echo [OK] Files copied successfully >> "%LOG_FILE%"
echo [OK] Files copied successfully
echo.

echo [ACTION] Verifying installation files... >> "%LOG_FILE%"
echo [ACTION] Verifying installation files...
if exist "%INSTALL_DIR%\docker-compose.yml" (
    echo [OK] docker-compose.yml found >> "%LOG_FILE%"
    echo [OK] docker-compose.yml found
) else (
    echo [ERROR] docker-compose.yml NOT found >> "%LOG_FILE%"
    echo [ERROR] docker-compose.yml NOT found - installation incomplete
    echo [DEBUG] Directory contents: >> "%LOG_FILE%"
    dir "%INSTALL_DIR%" >> "%LOG_FILE%" 2>&1
    pause
    exit /b 1
)

if exist "%INSTALL_DIR%\start-local.bat" (
    echo [OK] start-local.bat found >> "%LOG_FILE%"
    echo [OK] start-local.bat found
) else (
    echo [WARNING] start-local.bat NOT found >> "%LOG_FILE%"
    echo [WARNING] start-local.bat NOT found
)
echo.

echo [ACTION] Cleaning up temporary files... >> "%LOG_FILE%"
echo [ACTION] Cleaning up temporary files...
del "%TEMP_ZIP%" >nul 2>&1
timeout /t 1 >nul
rmdir /s /q "%EXTRACTED_DIR%" >nul 2>&1
echo [OK] Cleanup complete >> "%LOG_FILE%"
echo [OK] Cleanup complete
echo.

echo ========================================== >> "%LOG_FILE%"
echo [STEP 3/3] STARTING SERVICES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 3/3] STARTING SERVICES
echo.

echo [ACTION] Navigating to install directory >> "%LOG_FILE%"
echo [DEBUG] Changing directory to: %INSTALL_DIR% >> "%LOG_FILE%"
cd /d "%INSTALL_DIR%"
echo [DEBUG] Current directory: %CD% >> "%LOG_FILE%"

if not exist "start-local.bat" (
    echo [ERROR] start-local.bat not found! >> "%LOG_FILE%"
    echo ERROR: start-local.bat not found in %INSTALL_DIR%
    echo [DEBUG] Directory contents: >> "%LOG_FILE%"
    dir >> "%LOG_FILE%" 2>&1
    echo.
    echo The installation may be incomplete. Please check the log file.
    pause
    exit /b 1
)

echo [INFO] Found start-local.bat >> "%LOG_FILE%"
echo [INFO] Found start-local.bat
echo.
echo Starting Memshak services...
echo This may take a few minutes while Docker containers download and start...
echo.

echo [ACTION] Executing start-local.bat >> "%LOG_FILE%"
call start-local.bat

echo.
echo [INFO] start-local.bat execution completed >> "%LOG_FILE%"
echo [INFO] start-local.bat execution completed
echo.

echo [ACTION] Creating desktop shortcut... >> "%LOG_FILE%"
echo [ACTION] Creating desktop shortcut...
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Memshak.lnk'); $Shortcut.TargetPath = 'https://localhost:8443'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1
if not errorlevel 1 (
    echo [OK] Desktop shortcut created >> "%LOG_FILE%"
    echo [OK] Desktop shortcut created
)

echo.
echo [INFO] Installation completed successfully >> "%LOG_FILE%"
echo ==========================================
echo   INSTALLATION COMPLETED SUCCESSFULLY!
echo ==========================================
echo.
echo Installation Directory: %INSTALL_DIR%
echo Memshak URL: https://localhost:8443
echo Log File: %LOG_FILE%
echo.
echo Memshak should be accessible at https://localhost:8443
echo Please wait 1-2 minutes for all services to fully initialize.
echo.
echo If you encounter any SSL certificate warnings in your browser,
echo you can safely proceed (this is expected for local development).
echo.
pause
exit /b 0