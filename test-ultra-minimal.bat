@echo off
setlocal enabledelayedexpansion

echo Using PowerShell 7
set PS_COMMAND=pwsh

if not defined CERT_THUMBPRINT (
    echo Starting detection...
)

echo Done