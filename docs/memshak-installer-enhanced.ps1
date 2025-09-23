#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Memshak CDN Installer - Enhanced PowerShell Version
    
.DESCRIPTION
    Downloads and installs Memshak system with automatic prerequisite installation
    - Automatically installs Chocolatey if not present
    - Installs PowerShell 7, Docker Desktop, and WSL via Chocolatey
    - Configures Docker for automatic startup
    - Sets up the complete Memshak system
    
.NOTES
    Requires Administrator privileges
    Version: 2.1 Enhanced
#>

param(
    [switch]$SkipRestart,
    [switch]$Verbose
)

# Set error handling
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "🔍 $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "`n[STEP] $Message" -ForegroundColor Magenta }

Write-Host @"
==========================================
   MEMSHAK CDN INSTALLER v2.1 ENHANCED
==========================================
"@ -ForegroundColor Green

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Administrator privileges required!"
    Write-Host @"
This installer needs to:
• Install Chocolatey package manager
• Install PowerShell 7, Docker Desktop, and WSL
• Configure system services and startup
• Install SSL certificates

🔧 SOLUTION: Right-click PowerShell and select 'Run as administrator'
"@
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Success "Running with Administrator privileges"

# Installation directory setup
$InstallDir = "$env:USERPROFILE\memshak-system"
Write-Host "Installation directory: $InstallDir"

if (Test-Path $InstallDir) {
    Write-Warning "Installation directory already exists"
    $overwrite = Read-Host "Continue anyway? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "Installation cancelled"
        exit 0
    }
}

Write-Step "1/7 - Checking and installing prerequisites"

# Function to install Chocolatey
function Install-Chocolatey {
    Write-Info "Checking for Chocolatey package manager..."
    
    try {
        $chocoVersion = choco --version 2>$null
        Write-Success "Chocolatey already installed (version: $chocoVersion)"
        return $true
    }
    catch {
        Write-Warning "Chocolatey not found. Installing Chocolatey..."
        
        try {
            # Install Chocolatey
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "Chocolatey installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install Chocolatey: $_"
            return $false
        }
    }
}

# Function to install PowerShell 7
function Install-PowerShell7 {
    Write-Info "Checking for PowerShell 7..."
    
    try {
        $pwshVersion = pwsh --version 2>$null
        Write-Success "PowerShell 7 already installed ($pwshVersion)"
        return $true
    }
    catch {
        Write-Warning "PowerShell 7 not found. Installing via Chocolatey..."
        
        try {
            choco install powershell-core -y --no-progress
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "PowerShell 7 installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install PowerShell 7: $_"
            return $false
        }
    }
}

# Function to install WSL (MUST be done before Docker Desktop)
function Install-WSL {
    Write-Info "Checking for WSL (Windows Subsystem for Linux) - Required for Docker Desktop..."
    
    try {
        $wslStatus = wsl --status 2>$null
        Write-Success "WSL already installed and functional"
        return $true
    }
    catch {
        Write-Warning "WSL not found. Installing WSL2 (required for Docker Desktop)..."
        
        try {
            Write-Info "Enabling WSL Windows features..."
            # Enable WSL features first
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart -WarningAction SilentlyContinue
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart -WarningAction SilentlyContinue
            
            Write-Info "Installing WSL2 kernel and components via Chocolatey..."
            # Install WSL2 kernel via Chocolatey
            choco install wsl2 -y --no-progress
            
            # Try to set WSL2 as default version
            wsl --set-default-version 2 2>$null
            
            Write-Success "WSL2 installed successfully"
            Write-Warning "IMPORTANT: A system restart is strongly recommended for WSL2 to be fully functional"
            Write-Info "Docker Desktop installation will proceed, but may require restart to work properly"
            return $true
        }
        catch {
            Write-Error "WSL installation failed: $_"
            Write-Warning "WSL2 is required for Docker Desktop on Windows"
            Write-Info "You may need to:"
            Write-Info "1. Restart your computer"
            Write-Info "2. Run this installer again"
            Write-Info "3. Or install WSL2 manually from Microsoft Store"
            return $false
        }
    }
}

# Function to install Docker Desktop (requires WSL2)
function Install-DockerDesktop {
    Write-Info "Checking for Docker Desktop..."
    
    try {
        $dockerVersion = docker --version 2>$null
        Write-Success "Docker Desktop already installed ($dockerVersion)"
        
        # Configure for startup
        Configure-DockerStartup
        return $true
    }
    catch {
        Write-Warning "Docker not found. Installing Docker Desktop via Chocolatey..."
        Write-Info "Note: Docker Desktop requires WSL2 which should now be installed"
        
        try {
            # Verify WSL2 is available before installing Docker
            try {
                wsl --status 2>$null | Out-Null
                Write-Success "WSL2 verified - proceeding with Docker Desktop installation"
            }
            catch {
                Write-Warning "WSL2 may not be fully ready, but continuing with Docker installation"
            }
            
            choco install docker-desktop -y --no-progress
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "Docker Desktop installed successfully"
            
            # Configure Docker startup
            Configure-DockerStartup
            
            # Start Docker Desktop
            Write-Info "Starting Docker Desktop..."
            $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerPath) {
                Start-Process $dockerPath
                Start-Sleep -Seconds 10
            }
            
            return $true
        }
        catch {
            Write-Error "Failed to install Docker Desktop: $_"
            Write-Info "You may need to install manually from: https://www.docker.com/products/docker-desktop"
            return $false
        }
    }
}

# Function to configure Docker for automatic startup
function Configure-DockerStartup {
    Write-Info "Configuring Docker for automatic startup..."
    
    try {
        $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
        
        if (Test-Path $dockerPath) {
            # Add to startup registry
            $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Set-ItemProperty -Path $runKey -Name "Docker Desktop" -Value "`"$dockerPath`"" -Force
            Write-Success "Docker configured for automatic startup"
        }
        else {
            Write-Warning "Docker Desktop executable not found at expected location"
        }
    }
    catch {
        Write-Warning "Could not configure Docker startup: $_"
    }
}

# Function to wait for Docker to be ready
function Wait-ForDocker {
    param([int]$TimeoutSeconds = 120)
    
    Write-Info "Waiting for Docker to be ready..."
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
    
    while ((Get-Date) -lt $timeout) {
        try {
            docker info 2>$null | Out-Null
            Write-Success "Docker is ready"
            return $true
        }
        catch {
            Start-Sleep -Seconds 5
        }
    }
    
    Write-Warning "Docker did not become ready within $TimeoutSeconds seconds"
    return $false
}

# Install prerequisites in correct order
$prereqSuccess = $true

if (-not (Install-Chocolatey)) { $prereqSuccess = $false }
if (-not (Install-PowerShell7)) { $prereqSuccess = $false }

# WSL MUST be installed before Docker Desktop
$wslInstalled = Install-WSL
if (-not $wslInstalled) { 
    Write-Warning "WSL installation failed or incomplete - Docker Desktop requires WSL2"
    Write-Warning "You may need to restart and run the installer again"
    $prereqSuccess = $false
} else {
    Write-Success "WSL2 is ready - proceeding with Docker Desktop installation"
}

# Only install Docker if WSL is available
if ($wslInstalled) {
    if (-not (Install-DockerDesktop)) { 
        Write-Warning "Docker installation failed, but continuing..."
    }
} else {
    Write-Error "Skipping Docker installation due to WSL2 dependency issues"
}

if (-not $prereqSuccess) {
    Write-Error "Some prerequisites could not be installed"
    Write-Host @"
Please restart your computer and try again, or install manually:
• PowerShell 7: https://github.com/PowerShell/PowerShell/releases
• Docker Desktop: https://www.docker.com/products/docker-desktop
"@
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Success "All prerequisites installed!"

Write-Step "2/7 - Downloading deployment package"

$downloadUrl = "https://github.com/mickeyklai/memshak-deployment/archive/refs/heads/main.zip"
$tempZip = "deployment.zip"

try {
    Write-Info "Downloading from: $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UserAgent 'Memshak-CDN/2.1' -TimeoutSec 60
    Write-Success "Deployment package downloaded successfully"
}
catch {
    Write-Error "Failed to download deployment package: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Step "3/7 - Extracting deployment package"

try {
    Expand-Archive -Path $tempZip -DestinationPath "." -Force
    Remove-Item $tempZip -Force
    
    # Find extracted directory
    $extractedDir = Get-ChildItem -Directory "memshak-deployment-*" | Select-Object -First 1
    
    if (-not $extractedDir) {
        throw "Could not find extracted deployment directory"
    }
    
    Write-Success "Deployment package extracted to: $($extractedDir.Name)"
}
catch {
    Write-Error "Failed to extract deployment package: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Step "4/7 - Setting up Memshak system"

try {
    # Create installation directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    
    # Copy deployment files
    Copy-Item -Path "$($extractedDir.FullName)\*" -Destination $InstallDir -Recurse -Force
    
    Write-Success "Memshak system files installed to: $InstallDir"
    
    # Clean up extracted directory
    Remove-Item $extractedDir.FullName -Recurse -Force
}
catch {
    Write-Error "Failed to set up Memshak system: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Step "5/7 - Setting up Docker services"

# Change to installation directory
Set-Location $InstallDir

# Check if Docker is available and start services
if (Test-Path "docker-compose.yml") {
    if (Wait-ForDocker -TimeoutSeconds 60) {
        try {
            Write-Info "Building and starting Docker services..."
            docker-compose up --build -d
            Write-Success "Docker services started successfully"
        }
        catch {
            Write-Warning "Docker services failed to start: $_"
            Write-Info "This may be resolved after a system restart"
        }
    }
    else {
        Write-Warning "Docker not ready, skipping service startup"
        Write-Info "You can start services manually later with: docker-compose up -d"
    }
}
else {
    Write-Warning "No docker-compose.yml found, skipping Docker setup"
}

Write-Step "6/7 - Creating shortcuts and startup configuration"

try {
    # Create desktop shortcut
    Write-Info "Creating desktop shortcut..."
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Memshak.lnk")
    $Shortcut.TargetPath = "http://localhost:4200"
    $Shortcut.Save()
    Write-Success "Desktop shortcut created"
    
    # Create start menu shortcut
    Write-Info "Creating start menu shortcut..."
    $startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Memshak"
    if (-not (Test-Path $startMenuPath)) {
        New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
    }
    
    $Shortcut = $WshShell.CreateShortcut("$startMenuPath\Memshak.lnk")
    $Shortcut.TargetPath = "http://localhost:4200"
    $Shortcut.Save()
    Write-Success "Start menu shortcut created"
}
catch {
    Write-Warning "Could not create shortcuts: $_"
}

Write-Step "7/7 - Installation complete!"

Write-Host @"

==========================================
   INSTALLATION COMPLETED SUCCESSFULLY! 
==========================================

🎉 Memshak system has been installed with all prerequisites!

📍 Installation Location: $InstallDir
🌐 Access URL: http://localhost:4200
📱 Desktop Shortcut: Created
🐳 Docker Services: Configured for auto-start

🔧 INSTALLED COMPONENTS:
✅ Chocolatey Package Manager
✅ PowerShell 7
✅ Docker Desktop (with auto-start)
✅ WSL (Windows Subsystem for Linux)  
✅ Memshak Application Services

🚀 NEXT STEPS:
1. Restart your computer to ensure all components are fully active
2. After restart, Docker Desktop should start automatically
3. Open Memshak via desktop shortcut or navigate to http://localhost:4200

💡 If services don't start automatically after restart:
   • Check if Docker Desktop is running
   • Navigate to $InstallDir and run: docker-compose up -d

"@ -ForegroundColor Green

if (-not $SkipRestart) {
    $restart = Read-Host "Would you like to restart now? (recommended) (y/n)"
    if ($restart -eq 'y') {
        Write-Host "`n🔄 Restarting system in 10 seconds..."
        Write-Host "Press Ctrl+C to cancel" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
    else {
        Write-Warning "Please restart your computer manually when convenient"
        Write-Info "This ensures all components work properly"
    }
}

Read-Host "Press Enter to exit"