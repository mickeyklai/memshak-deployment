@echo off
setlocal enabledelayedexpansion

set PS_COMMAND=pwsh

echo Testing simple PowerShell call...
%PS_COMMAND% -Command "Write-Host 'Hello from PowerShell'"
echo Simple call completed

echo Testing PowerShell script call...
%PS_COMMAND% -ExecutionPolicy Bypass -File cert-detect-display.ps1
echo Script call completed

pause