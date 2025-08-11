@echo off
REM Memshak Docker Start Script - Deployment Version
REM Starts all Memshak Docker containers using remote images

echo ================================
echo    MEMSHAK DOCKER START
echo ================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not running
    echo Please install Docker Desktop and ensure it's running
    pause
    exit /b 1
)

echo Starting Memshak containers...
echo This may take a few minutes to pull images on first run
echo.

REM Create required directories
if not exist "data" mkdir data
if not exist "logs" mkdir logs
if not exist "ssl" mkdir ssl

REM Generate SSL certificates if they don't exist
if not exist "ssl\localhost.crt" (
    echo Generating SSL certificates for HTTPS...
    
    REM Check if running as admin
    net session >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Running without administrator privileges
        echo Creating basic SSL certificates (browsers may show warnings)
        
        if exist "generate-basic-ssl.ps1" (
            pwsh -ExecutionPolicy Bypass -File "generate-basic-ssl.ps1"
        ) else (
            echo ❌ generate-basic-ssl.ps1 not found
        )
    ) else (
        echo ✅ Running with administrator privileges
        echo Creating SSL certificates with trusted root installation...
        if exist "generate-ssl.ps1" (
            pwsh -ExecutionPolicy Bypass -File "generate-ssl.ps1"
        ) else (
            echo ⚠️  generate-ssl.ps1 not found, creating basic certificates
            if exist "generate-basic-ssl.ps1" (
                pwsh -ExecutionPolicy Bypass -File "generate-basic-ssl.ps1"
            )
        )
    )
)

REM Start containers using Docker Compose
docker-compose up -d

if errorlevel 1 (
    echo ERROR: Failed to start containers
    echo Please check Docker Desktop is running and try again
    pause
    exit /b 1
) else (
    echo.
    echo ================================
    echo   MEMSHAK SERVICES STARTED
    echo ================================
    echo.
    echo Services are starting up...
    echo Web Interface (HTTPS): https://localhost:8443
    echo Web Interface (HTTP):  http://localhost:8080
    echo Direct API Access:     http://localhost:3000
    echo.
    
    REM Start the PowerShell authentication server
    if exist "start-auth-server.bat" (
        echo Starting PowerShell authentication server...
        start /b cmd /c "start-auth-server.bat"
        timeout /t 2 >nul
        echo ✅ Authentication server started
        echo    Auth Server: http://localhost:8081
        echo    Certificate detection is automatic
    ) else (
        echo ⚠️  Authentication server script not found
        echo    Manual certificate authentication may be required
    )
    
    echo.
    echo 🎉 All Memshak services are now running!
    echo.
    echo Tip: It may take 1-2 minutes for all services to fully start
    echo Check status with: docker-compose ps
    echo View logs with: docker-compose logs -f
)

echo.
pause
