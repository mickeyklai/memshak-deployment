# Memshak Enhanced Installer Suite

This enhanced installer suite automatically handles all prerequisites and system setup for the Memshak application.

## What Gets Installed

The installer automatically detects and installs missing components:

### 🔧 Prerequisites
- **Chocolatey Package Manager** - For automated software installation
- **PowerShell 7** - Latest PowerShell version required for scripts
- **Docker Desktop** - Container platform for running services
- **WSL (Windows Subsystem for Linux)** - Required by Docker Desktop

### 🚀 System Configuration
- **Docker Auto-Start** - Configures Docker Desktop to start with Windows
- **Desktop Shortcuts** - Quick access to Memshak application
- **Start Menu Shortcuts** - Integration with Windows Start Menu
- **Service Setup** - Automatic container orchestration with docker-compose

## Installation Options

### Option 1: Simple Installation (Recommended)
**File:** `INSTALL-MEMSHAK.bat`

```batch
# Just double-click this file
INSTALL-MEMSHAK.bat
```

- User-friendly launcher
- Automatically requests Administrator privileges
- Handles all complexity behind the scenes

### Option 2: PowerShell Installation (Advanced)
**File:** `memshak-installer-enhanced.ps1`

```powershell
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy Bypass -Scope Process
.\memshak-installer-enhanced.ps1
```

**Features:**
- More detailed output and error handling
- Better progress reporting
- PowerShell-native implementation
- Support for command-line parameters

**Parameters:**
- `-SkipRestart` - Don't prompt to restart after installation
- `-Verbose` - Show detailed installation logs

### Option 3: Batch Installation (Compatibility)
**File:** `memshak-installer-enhanced.bat`

```batch
# Right-click and "Run as Administrator"
memshak-installer-enhanced.bat
```

- Classic batch script implementation
- Maximum Windows compatibility
- Works on older Windows versions

## Installation Process

### Step 1: Prerequisites Check & Install (In Correct Order)
- ✅ Checks for Chocolatey, installs if missing
- ✅ Checks for PowerShell 7, installs via Chocolatey if missing
- ✅ **Checks for WSL2 FIRST**, enables Windows features and installs if missing
- ✅ Checks for Docker Desktop (after WSL2), installs via Chocolatey if missing
- ✅ Configures Docker Desktop for automatic startup

**Important:** WSL2 is installed before Docker Desktop as it's a hard requirement

### Step 2: Download Memshak
- 📥 Downloads latest Memshak deployment package from GitHub
- 📦 Extracts to temporary location

### Step 3: System Setup
- 📁 Creates installation directory (`%USERPROFILE%\memshak-system`)
- 📋 Copies all application files
- 🔗 Creates desktop and Start Menu shortcuts

### Step 4: Docker Services
- ⏳ Waits for Docker Desktop to be ready
- 🐳 Builds and starts Memshak containers using docker-compose
- ✅ Verifies services are running

### Step 5: Completion
- 🎉 Installation summary
- 🔄 Optional system restart (recommended)

## System Requirements

### Minimum Requirements
- **OS:** Windows 10 version 2004 or Windows 11
- **RAM:** 8GB (16GB recommended for Docker)
- **Disk:** 10GB free space
- **Architecture:** x64 (64-bit)

### Required Privileges
- **Administrator Rights** - Required for:
  - Installing system-level software (Chocolatey, PowerShell 7, Docker)
  - Enabling Windows features (WSL, Hyper-V)
  - Modifying system registry (startup configurations)
  - Installing SSL certificates to trusted store

## Chocolatey Package Details

The installer uses these Chocolatey packages:

```powershell
choco install powershell-core -y    # PowerShell 7
choco install wsl2 -y              # WSL2 (Windows Subsystem for Linux) - INSTALLED FIRST
choco install docker-desktop -y     # Docker Desktop - Requires WSL2
```

**Installation Order is Critical:**
1. PowerShell 7 (for script execution)
2. **WSL2 first** (Docker Desktop dependency)
3. Docker Desktop (depends on WSL2 being available)

## Post-Installation

### Automatic Startup
- **Docker Desktop** - Configured to start with Windows
- **Memshak Services** - Start automatically when Docker starts

### Manual Service Management
```bash
# Navigate to installation directory
cd %USERPROFILE%\memshak-system

# Start services
docker-compose up -d

# Stop services  
docker-compose down

# View logs
docker-compose logs -f
```

### Access Points
- **Web Application:** http://localhost:4200
- **Desktop Shortcut:** Double-click Memshak icon
- **Start Menu:** Start → All Programs → Memshak

## Troubleshooting

### Installation Issues

**Problem:** "Chocolatey installation failed"
```batch
# Solution: Manual Chocolatey installation
# Open PowerShell as Administrator:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Problem:** "Docker installation failed"
```batch
# Solution: Manual Docker Desktop installation
# Download from: https://www.docker.com/products/docker-desktop
# Install, then restart the Memshak installer
```

**Problem:** "WSL installation requires restart"
```batch
# Solution: Restart required
# 1. Restart computer
# 2. Re-run installer
# WSL features need a restart to activate
```

### Runtime Issues

**Problem:** Services don't start after restart
```bash
# Check Docker Desktop status
# Start Menu → Docker Desktop → Start

# Or manually start services:
cd %USERPROFILE%\memshak-system
docker-compose up -d
```

**Problem:** "Port already in use"
```bash
# Check what's using the port:
netstat -ano | findstr :4200

# Kill conflicting process or change port in docker-compose.yml
```

**Problem:** WSL issues with Docker
```bash
# Update WSL to latest version:
wsl --update

# Restart WSL:
wsl --shutdown
# Then restart Docker Desktop
```

## Uninstallation

### Remove Memshak Application
1. Stop Docker services:
   ```bash
   cd %USERPROFILE%\memshak-system
   docker-compose down
   ```

2. Remove installation directory:
   ```batch
   rmdir /s "%USERPROFILE%\memshak-system"
   ```

3. Remove shortcuts:
   - Delete desktop shortcut
   - Remove from Start Menu → Memshak folder

### Remove Prerequisites (Optional)
```powershell
# Remove via Chocolatey:
choco uninstall docker-desktop -y
choco uninstall powershell-core -y
choco uninstall wsl2 -y

# Remove Chocolatey itself (if desired):
# Follow instructions at: https://docs.chocolatey.org/en-us/choco/uninstallation
```

## Security Considerations

### Administrator Privileges
- Required only during installation
- Used for system-level software installation
- NOT stored or cached after installation

### Network Security
- All services run locally (localhost)
- No external network exposure by default
- SSL certificates for internal HTTPS communication

### Data Security
- Application data stored in user directory
- No system-wide data storage
- Easy to backup/restore user data

## Support

### Log Files
Installation logs are displayed in console and can be redirected:

```batch
# Save installation log:
INSTALL-MEMSHAK.bat > installation.log 2>&1
```

### Common Issues
1. **Antivirus Blocking:** Temporarily disable real-time protection
2. **Corporate Networks:** May need proxy configuration for downloads
3. **Virtualization:** Ensure Hyper-V is enabled for Docker Desktop

### Getting Help
- Check installation logs for specific error messages
- Ensure system meets minimum requirements
- Try manual installation of failed components
- Restart computer and retry installation

---

**Version:** 2.1 Enhanced  
**Last Updated:** December 2024  
**Compatibility:** Windows 10/11 with Administrator privileges