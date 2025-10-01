@echo off
REM Memshak Complete Installer - Simplified Version
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

REM Set up logging
set "LOG_FILE=%~dp0memshak-install.log"
echo Memshak Installation Log > "%LOG_FILE%"
echo Started: %DATE% %TIME% >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"

echo ==========================================
echo    MEMSHAK INSTALLER v3.4
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
docker --version >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Docker found - checking system configuration... >> "%LOG_FILE%"
    echo [INFO] Docker found - checking system configuration...
    
    REM Check if WSL is properly configured
    wsl --status >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] System already configured - skipping prerequisites >> "%LOG_FILE%"
        echo [INFO] System already configured - skipping prerequisites
        goto install_memshak_files
    ) else (
        echo [INFO] Docker found but WSL needs configuration >> "%LOG_FILE%"
        echo [INFO] Docker found but WSL needs configuration
        goto configure_wsl_only
    )
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

:install_memshak_files
echo ========================================== >> "%LOG_FILE%"
echo [STEP 1/3] DOWNLOADING MEMSHAK >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 1/3] DOWNLOADING MEMSHAK

set "DOWNLOAD_URL=https://github.com/mickeyklai/memshak-deployment/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\memshak-deploy.zip"

echo [ACTION] Downloading package... >> "%LOG_FILE%"
echo Downloading package...
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_ZIP%' -UseBasicParsing" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Download failed >> "%LOG_FILE%"
    echo ERROR: Download failed
    pause
    exit /b 1
)
echo [OK] Download complete >> "%LOG_FILE%"
echo [OK] Download complete

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 2/3] EXTRACTING FILES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 2/3] EXTRACTING FILES

echo [ACTION] Extracting archive... >> "%LOG_FILE%"
echo Extracting archive...
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP%' -Force" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Extraction failed >> "%LOG_FILE%"
    echo ERROR: Extraction failed
    pause
    exit /b 1
)
echo [OK] Extracted >> "%LOG_FILE%"
echo [OK] Extracted

echo [ACTION] Finding extracted directory... >> "%LOG_FILE%"
set "EXTRACTED_DIR="
for /d %%i in ("%TEMP%\memshak-deployment-*") do (
    echo [FOUND] %%i >> "%LOG_FILE%"
    set "EXTRACTED_DIR=%%i"
)

if not defined EXTRACTED_DIR (
    echo [ERROR] Extracted directory not found >> "%LOG_FILE%"
    echo ERROR: Extracted directory not found
    pause
    exit /b 1
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [ACTION] Copying files... >> "%LOG_FILE%"
echo Copying files to: %INSTALL_DIR%
xcopy "%EXTRACTED_DIR%\*" "%INSTALL_DIR%\" /e /h /y /i >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Copy failed - exit code: %ERRORLEVEL% >> "%LOG_FILE%"
    echo ERROR: File copy failed
    pause
    exit /b 1
)
echo [OK] Files copied >> "%LOG_FILE%"
echo [OK] Files copied

echo [ACTION] Verifying files... >> "%LOG_FILE%"
if exist "%INSTALL_DIR%\docker-compose.yml" (
    echo [OK] docker-compose.yml found >> "%LOG_FILE%"
    echo [OK] docker-compose.yml found
) else (
    echo [WARNING] docker-compose.yml NOT found >> "%LOG_FILE%"
    echo [WARNING] docker-compose.yml NOT found
)

echo [ACTION] Cleaning up... >> "%LOG_FILE%"
del "%TEMP_ZIP%" >nul 2>&1
timeout /t 2 >nul
start /wait /min cmd /c "rmdir /s /q "%EXTRACTED_DIR%" 2>nul"
echo [OK] Cleanup complete >> "%LOG_FILE%"

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 3/3] STARTING SERVICES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 3/3] STARTING SERVICES

echo [ACTION] Changing to install directory >> "%LOG_FILE%"
cd /d "%INSTALL_DIR%"

if not exist "start-local.bat" (
    echo [ERROR] start-local.bat not found! >> "%LOG_FILE%"
    echo ERROR: start-local.bat not found in %INSTALL_DIR%
    pause
    exit /b 1
)

echo [INFO] Found start-local.bat >> "%LOG_FILE%"
echo Found start-local.bat
echo.
echo Starting Memshak services...
echo.

echo [ACTION] Calling start-local.bat >> "%LOG_FILE%"
call start-local.bat

echo.
echo [INFO] start-local.bat completed >> "%LOG_FILE%"
echo.
echo [ACTION] Creating shortcuts >> "%LOG_FILE%"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Memshak.lnk'); $Shortcut.TargetPath = 'https://localhost:8443'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1

echo.
echo [INFO] Installation completed >> "%LOG_FILE%"
echo ==========================================
echo   INSTALLATION COMPLETED
echo ==========================================
echo.
echo Location: %INSTALL_DIR%
echo URL: https://localhost:8443
echo Log: %LOG_FILE%
echo.
echo Memshak should be accessible at https://localhost:8443
echo Wait 1-2 minutes for services to initialize.
echo.
pause
exit /b 0 [STEP 2/3] EXTRACTING FILES

echo [ACTION] Extracting archive... >> "%LOG_FILE%"
echo Extracting archive...
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP%' -Force" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Extraction failed >> "%LOG_FILE%"
    echo ERROR: Extraction failed
    pause
    exit /b 1
)
echo [OK] Extracted >> "%LOG_FILE%"
echo [OK] Extracted

echo [ACTION] Finding extracted directory... >> "%LOG_FILE%"
set "EXTRACTED_DIR="
for /d %%i in ("%TEMP%\memshak-deployment-*") do (
    echo [FOUND] %%i >> "%LOG_FILE%"
    set "EXTRACTED_DIR=%%i"
)

if not defined EXTRACTED_DIR (
    echo [ERROR] Extracted directory not found >> "%LOG_FILE%"
    echo ERROR: Extracted directory not found
    pause
    exit /b 1
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [ACTION] Copying files... >> "%LOG_FILE%"
echo Copying files to: %INSTALL_DIR%
xcopy "%EXTRACTED_DIR%\*" "%INSTALL_DIR%\" /e /h /y /i >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [ERROR] Copy failed - exit code: %ERRORLEVEL% >> "%LOG_FILE%"
    echo ERROR: File copy failed
    pause
    exit /b 1
)
echo [OK] Files copied >> "%LOG_FILE%"
echo [OK] Files copied

echo [ACTION] Verifying files... >> "%LOG_FILE%"
if exist "%INSTALL_DIR%\docker-compose.yml" (
    echo [OK] docker-compose.yml found >> "%LOG_FILE%"
    echo [OK] docker-compose.yml found
) else (
    echo [WARNING] docker-compose.yml NOT found >> "%LOG_FILE%"
    echo [WARNING] docker-compose.yml NOT found
    echo [INFO] Files in install directory: >> "%LOG_FILE%"
    dir "%INSTALL_DIR%" /b >> "%LOG_FILE%"
)

echo [ACTION] Cleaning up... >> "%LOG_FILE%"
del "%TEMP_ZIP%" >nul 2>&1
timeout /t 2 >nul
start /wait /min cmd /c "rmdir /s /q "%EXTRACTED_DIR%" 2>nul"
echo [OK] Cleanup complete >> "%LOG_FILE%"

echo.
echo ========================================== >> "%LOG_FILE%"
echo [STEP 3/3] STARTING DOCKER SERVICES >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"
echo.
echo [STEP 3/3] STARTING DOCKER SERVICES
echo.

cd /d "%INSTALL_DIR%" >> "%LOG_FILE%" 2>&1

if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found! >> "%LOG_FILE%"
    echo ERROR: docker-compose.yml not found in %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo [INFO] Found docker-compose.yml >> "%LOG_FILE%"
echo Found docker-compose.yml
echo.
echo Checking if Docker is ready...
echo.

docker info >nul 2>&1
if not errorlevel 1 (
    echo [OK] Docker is ready >> "%LOG_FILE%"
    echo Docker is ready!
    goto start_services
)

echo [INFO] Docker not ready, attempting to start Docker Desktop... >> "%LOG_FILE%"
echo Docker not ready, checking if Docker Desktop needs to be started...

tasklist /FI "IMAGENAME eq Docker Desktop.exe" 2>nul | find /I "Docker Desktop.exe" >nul 2>&1
if errorlevel 1 (
    if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
        echo [ACTION] Starting Docker Desktop... >> "%LOG_FILE%"
        echo Starting Docker Desktop...
        start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" >nul 2>&1
        echo Waiting for Docker Desktop to initialize (this may take 1-2 minutes)...
    ) else (
        echo [ERROR] Docker Desktop not found >> "%LOG_FILE%"
        echo ERROR: Docker Desktop executable not found
        echo Please install Docker Desktop manually
        pause
        exit /b 1
    )
) else (
    echo Docker Desktop is running, waiting for it to be ready...
)

echo.
echo Waiting for Docker daemon...
set "max_wait=180"
set "wait_count=0"

:wait_loop
timeout /t 10 >nul 2>&1
set /a wait_count+=10
echo Waiting... %wait_count%/%max_wait% seconds

docker info >nul 2>&1
if not errorlevel 1 goto start_services

if %wait_count% lss %max_wait% goto wait_loop

echo.
echo [WARNING] Docker not ready after %max_wait% seconds >> "%LOG_FILE%"
echo WARNING: Docker did not become ready after %max_wait% seconds
echo.
echo Please:
echo 1. Ensure Docker Desktop is running
echo 2. Wait for it to fully start
echo 3. Then run: cd %INSTALL_DIR% ^&^& docker-compose up -d
echo.
pause
exit /b 0

:start_services
echo.
echo [OK] Docker ready >> "%LOG_FILE%"
echo Docker is ready!
echo.
echo Starting services in background...
echo.

docker-compose up -d --remove-orphans

if errorlevel 1 (
    echo [WARNING] Services start had issues >> "%LOG_FILE%"
    echo WARNING: Docker Compose had issues
    echo Check logs with: docker-compose logs
) else (
    echo [OK] Services started >> "%LOG_FILE%"
    echo [OK] All services started successfully!
    echo.
    echo Running containers:
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
)

echo.
echo [ACTION] Creating shortcuts... >> "%LOG_FILE%"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Memshak.lnk'); $Shortcut.TargetPath = 'https://localhost:8443'; $Shortcut.Save()" >> "%LOG_FILE%" 2>&1

echo.
echo ==========================================
echo   INSTALLATION COMPLETED
echo ==========================================
echo.
echo Location: %INSTALL_DIR%
echo URL: https://localhost:8443
echo Log: %LOG_FILE%
echo.
echo Press Ctrl+C to stop services, or close this window when done.
echo.
pause
exit /b 0