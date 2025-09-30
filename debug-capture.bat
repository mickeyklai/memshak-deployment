@echo off
setlocal enabledelayedexpansion
set PS_COMMAND=pwsh

echo Testing PowerShell output capture...

for /f "tokens=*" %%i in ('!PS_COMMAND! -ExecutionPolicy Bypass -File detect-certificate-auto.ps1 2^>nul') do (
    echo Captured line: [%%i]
    set "RESULT=%%i"
)

echo Final result: [!RESULT!]
echo Length check: !RESULT! is empty? 
if "!RESULT!"=="" echo YES - empty
if not "!RESULT!"=="" echo NO - not empty

pause