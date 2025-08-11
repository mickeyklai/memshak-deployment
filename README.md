# Memshak System - Deployment Package

This repository contains everything needed to deploy and run the Memshak system on Windows using Docker Desktop. No source code access required.

## Quick Start

### Prerequisites
- Windows 10/11
- Docker Desktop installed and running
- PowerShell 7 (for certificate authentication)
- Bituach Leumi certificate USB key (for authentication)

### Installation

1. **Download this repository**
   ```bash
   git clone [your-deployment-repo-url]
   cd memshak-deployment
   ```

2. **Detect your certificate** (optional but recommended)
   ```bash
   detect-certificate.bat
   ```

3. **Start the system**
   ```bash
   start-local.bat
   ```

4. **Access the web interface**
   - HTTPS: https://localhost:8443
   - HTTP: http://localhost:8080
   - Direct API: http://localhost:3000

## Configuration

Edit `.env` file to customize:
- Railway service URLs
- Authentication tokens
- User passwords
- Debug settings

## System Management

### Starting Services
```bash
start-local.bat          # Start all services
start-auth-server.bat    # Start certificate authentication server
```

### Stopping Services
```bash
stop-local.bat           # Stop all services
```

### Updating System
```bash
update-system.bat        # Pull latest images and restart
```

### Certificate Management
```bash
detect-certificate.bat   # Auto-detect and configure certificate
```

## Architecture

The system consists of:

1. **Frontend Service** - Angular web application
2. **Backend Service** - Express.js API server
3. **NGINX Proxy** - Reverse proxy with SSL termination
4. **Auth Server** - PowerShell certificate authentication

All services run in Docker containers using images hosted remotely.

## Docker Images

- `mickeyklai/memshak-frontend:latest` - Angular frontend
- `mickeyklai/memshak-backend:latest` - Express.js backend  
- `nginx:alpine` - NGINX reverse proxy

## Ports

- `8443` - HTTPS web interface
- `8080` - HTTP (redirects to HTTPS)
- `3000` - Direct API access
- `8888` - Authentication server (localhost only)

## Troubleshooting

### Services won't start
1. Check Docker Desktop is running
2. Ensure ports are not in use by other applications
3. Check logs: `docker-compose logs -f`

### Certificate issues
1. Ensure Bituach Leumi USB certificate is connected
2. Run `detect-certificate.bat` to auto-configure
3. Verify certificate is installed in Windows Certificate Store

### Authentication problems
1. Start auth server: `start-auth-server.bat`
2. Check certificate thumbprint is set correctly
3. Ensure PowerShell 7 is installed

## Support

- Check Docker container status: `docker-compose ps`
- View logs: `docker-compose logs -f [service-name]`
- Restart specific service: `docker-compose restart [service-name]`

## Security Notes

- SSL certificates are generated automatically for HTTPS
- Certificate-based authentication requires proper Bituach Leumi certificate
- All communication between services is secured within Docker network
- External access only through configured ports
