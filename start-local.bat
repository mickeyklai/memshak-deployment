docker-compose up -d
@echo off
setlocal EnableDelayedExpansion

echo === MEMSHAK DOCKER START ===
echo.

REM 1. Docker presence
docker --version >nul 2>&1 || (
    echo ERROR: Docker not available. Start Docker Desktop and retry.
    exit /b 1
)

REM 2. Minimal directories
for %%D in (data logs ssl) do if not exist "%%D" mkdir "%%D"

REM 3. (Optional) Generate basic localhost cert if missing (silent if tools absent)
if not exist "ssl\localhost.crt" if exist generate-basic-ssl.ps1 (
    echo Generating basic localhost SSL certificate...
    pwsh -ExecutionPolicy Bypass -File generate-basic-ssl.ps1 >nul 2>&1
)

echo Starting containers...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: docker-compose up failed.
    exit /b 1
)

echo Containers launched. (Check: docker-compose ps)

REM 5. Launch auth server
if not exist start-auth-server.bat goto :no_auth
echo Launching authentication server (background)...
start "AuthServer" /min cmd /c start-auth-server.bat

REM 6. Poll health (up to 20s)
set "_UP="
for /L %%I in (1,1,20) do (
    powershell -NoLogo -NoProfile -Command "try { $r=Invoke-WebRequest -UseBasicParsing -Uri http://127.0.0.1:8888/health -TimeoutSec 1; if($r.StatusCode -eq 200){ exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        echo Auth server is UP on attempt %%I (http://127.0.0.1:8888/health)
        set "_UP=1"
        goto :after_poll
    )
    ping 127.0.0.1 -n 2 >nul >nul
)
:after_poll
if not defined _UP (
    echo WARNING: Auth server not responding yet. It may still be initializing or waiting for user/device interaction.
    echo If you launched interactively, check the opened AuthServer window.
)
goto :end

:no_auth
echo WARNING: start-auth-server.bat not found; auth features unavailable.

:end
echo.
echo Done. Press any key to exit.
pause >nul
exit /b 0
