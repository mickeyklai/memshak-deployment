@echo off
REM Memshak Installer Launcher
REM This script downloads and launches the main installer with Administrator privileges

echo ==========================================
echo     MEMSHAK INSTALLER LAUNCHER v2.2
echo ==========================================
echo.
echo This installer will automatically install:
echo ✅ Chocolatey Package Manager  
echo ✅ PowerShell 7
echo ✅ Docker Desktop (with auto-start)
echo ✅ WSL (Windows Subsystem for Linux)
echo ✅ Memshak Application System
echo.

REM Download installer files if they don't exist
if not exist "%~dp0memshak-installer-enhanced.ps1" (
    echo 📥 Downloading PowerShell installer...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mickeyklai/memshak/master/railway-deployments/memshak-deployment-package/docs/memshak-installer-enhanced.ps1' -OutFile '%~dp0memshak-installer-enhanced.ps1' -UseBasicParsing; Write-Host '✅ PowerShell installer downloaded' } catch { Write-Host '❌ Failed to download PowerShell installer' }"
)

if not exist "%~dp0memshak-installer-enhanced.bat" (
    echo 📥 Downloading Batch installer...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mickeyklai/memshak/master/railway-deployments/memshak-deployment-package/docs/memshak-installer-enhanced.bat' -OutFile '%~dp0memshak-installer-enhanced.bat' -UseBasicParsing; Write-Host '✅ Batch installer downloaded' } catch { Write-Host '❌ Failed to download Batch installer' }"
)

echo.
echo 🔧 Administrator privileges will be requested...
echo.

pause

REM Check if we're running as administrator
net session >nul 2>&1
if errorlevel 1 (
    REM Not running as admin, launch with admin privileges
    echo Requesting Administrator privileges...
    
    REM Try PowerShell version first (more reliable)
    if exist "%~dp0memshak-installer-enhanced.ps1" (
        powershell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0memshak-installer-enhanced.ps1\"' -Verb RunAs"
    ) else if exist "%~dp0memshak-installer-enhanced.bat" (
        REM Fallback to batch version
        powershell -Command "Start-Process cmd -ArgumentList '/c \"%~dp0memshak-installer-enhanced.bat\"' -Verb RunAs"
    ) else (
        echo ❌ ERROR: Unable to download or find installer files!
        echo Please check your internet connection and try again.
        echo.
        echo If the problem persists, download manually:
        echo   • memshak-installer-enhanced.ps1
        echo   • memshak-installer-enhanced.bat
        echo.
        echo From: https://github.com/mickeyklai/memshak/tree/master/railway-deployments/memshak-deployment-package/docs/
        pause
        exit /b 1
    )
    
    echo.
    echo ✅ Installer launched with Administrator privileges
    echo Check the new window for installation progress...
    echo.
    pause
    exit /b 0
) else (
    REM Already running as admin, launch installer directly
    if exist "%~dp0memshak-installer-enhanced.ps1" (
        powershell -ExecutionPolicy Bypass -File "%~dp0memshak-installer-enhanced.ps1"
    ) else if exist "%~dp0memshak-installer-enhanced.bat" (
        call "%~dp0memshak-installer-enhanced.bat"
    ) else (
        echo ❌ ERROR: Unable to download or find installer files!
        echo Please check your internet connection and try again.
        pause
        exit /b 1
    )
)