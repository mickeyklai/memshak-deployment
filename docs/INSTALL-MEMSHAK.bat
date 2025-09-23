@echo off
REM Memshak Installer Launcher
REM This script launches the main installer with Administrator privileges

echo ==========================================
echo     MEMSHAK INSTALLER LAUNCHER v2.1
echo ==========================================
echo.
echo This installer will automatically install:
echo ✅ Chocolatey Package Manager  
echo ✅ PowerShell 7
echo ✅ Docker Desktop (with auto-start)
echo ✅ WSL (Windows Subsystem for Linux)
echo ✅ Memshak Application System
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
        echo ❌ ERROR: Installer files not found!
        echo Please ensure the following files are in the same directory:
        echo   • memshak-installer-enhanced.ps1 (preferred)
        echo   • memshak-installer-enhanced.bat (fallback)
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
        echo ❌ ERROR: Installer files not found!
        pause
        exit /b 1
    )
)