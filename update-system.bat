@echo off
REM Memshak Docker Update Script - Deployment Version  
REM Updates all Memshak Docker images to latest versions

echo ==========================================
echo    MEMSHAK DOCKER UPDATE - DEPLOYMENT
echo ==========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not running
    echo Please install Docker Desktop and ensure it's running
    pause
    exit /b 1
)

echo This will update Memshak to the latest version by:
echo   1. Stopping current containers
echo   2. Pulling latest Docker images
echo   3. Restarting services with updated images
echo.
echo Press any key to continue, or Ctrl+C to cancel...
pause >nul

echo [1/3] Stopping current services...
docker-compose down

echo [2/3] Pulling latest images...
docker-compose pull

if errorlevel 1 (
    echo WARNING: Failed to pull some images
    echo This might be due to network issues or image availability
    echo The system will try to start with existing images
)

echo [3/3] Starting updated services...
docker-compose up -d

if errorlevel 1 (
    echo ERROR: Failed to start updated services
    echo Please check Docker logs and try again
    pause
    exit /b 1
) else (
    echo.
    echo ==========================================
    echo    MEMSHAK UPDATE COMPLETED
    echo ==========================================
    echo.
    echo Updated services are starting up...
    echo Web Interface (HTTPS): https://localhost:8443
    echo Web Interface (HTTP):  http://localhost:8080
    echo Direct API Access:     http://localhost:3000
    echo.
    echo Check updated versions with: docker-compose ps
)

echo.
pause
