@echo off
REM Memshak Docker Stop Script - Deployment Version
REM Stops all running Memshak Docker containers

echo ================================
echo    MEMSHAK DOCKER STOP
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

echo Stopping Memshak containers...
echo.

REM Stop containers using Docker Compose
docker-compose down

if errorlevel 1 (
    echo WARNING: Some containers may not have stopped cleanly
) else (
    echo Containers stopped successfully!
)

echo.
echo ================================
echo   MEMSHAK CONTAINERS STOPPED
echo ================================
echo.
echo All Memshak services have been stopped
echo To start again, run: start-local.bat
