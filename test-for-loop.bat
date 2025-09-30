@echo off
setlocal enabledelayedexpansion
set PS_COMMAND=pwsh

echo Testing for loop with PowerShell output...

for /f "delims=" %%i in ('%PS_COMMAND% -ExecutionPolicy Bypass -File cert-detect-thumbprint.ps1') do (
    set "CERT_THUMBPRINT=%%i"
)

echo CERT_THUMBPRINT is: %CERT_THUMBPRINT%
echo Test completed
pause