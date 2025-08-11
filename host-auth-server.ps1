# PowerShell HTTP Authentication Server
# Lightweight HTTP server for certificate authentication without Node.js dependencies

param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8888,
    
    [Parameter(Mandatory = $false)]
    [string]$AuthScriptPath = "./auth.ps1"
)

# Import required modules
Add-Type -AssemblyName System.Web

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Send-HttpResponse {
    param(
        [System.Net.HttpListenerContext]$Context,
        [int]$StatusCode = 200,
        [string]$ContentType = "application/json",
        [string]$Body = ""
    )
    
    try {
        $response = $Context.Response
        $response.StatusCode = $StatusCode
        $response.ContentType = "$ContentType; charset=utf-8"
        
        if ($Body) {
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($Body)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
    catch {
        Write-Log "Failed to send HTTP response: $($_.Exception.Message)" "ERROR"
    }
}

function Send-ErrorResponse {
    param(
        [System.Net.HttpListenerContext]$Context,
        [int]$StatusCode = 500,
        [string]$ErrorMessage = "Internal Server Error"
    )
    
    $errorResponse = @{
        error = $ErrorMessage
        timestamp = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    } | ConvertTo-Json
    
    Send-HttpResponse -Context $Context -StatusCode $StatusCode -Body $errorResponse
}

function Invoke-AuthScript {
    param(
        [string]$ClientIds = "",
        [string]$StationId = "DOCKER"
    )
    
    try {
        # Validate certificate thumbprint
        $certThumbprint = $env:CERT_THUMBPRINT
        if (-not $certThumbprint) {
            throw "CERT_THUMBPRINT environment variable not set"
        }
        
        # Validate auth script exists
        $scriptPath = Resolve-Path $AuthScriptPath -ErrorAction Stop
        
        Write-Log "Executing auth script: $scriptPath" "INFO"
        Write-Log "Certificate thumbprint: $certThumbprint" "INFO"
        Write-Log "Client IDs: $ClientIds" "INFO"
        Write-Log "Station ID: $StationId" "INFO"
        
        # Build PowerShell command
        $psArgs = @(
            "-ExecutionPolicy", "Bypass"
            "-File", $scriptPath
            "-thumbprint", $certThumbprint
            "-StationId", $StationId
        )
        
        if ($ClientIds -and $ClientIds.Trim() -ne "") {
            $psArgs += @("-ClientIds", $ClientIds)
        }
        
        # Execute auth script and capture output
        Write-Log "Starting PowerShell process..." "INFO"
        
        # Create temporary files for output capture
        $tempDir = [System.IO.Path]::GetTempPath()
        $stdOutFile = Join-Path $tempDir "auth-stdout-$(Get-Random).txt"
        $stdErrFile = Join-Path $tempDir "auth-stderr-$(Get-Random).txt"
        
        $process = Start-Process -FilePath "pwsh" -ArgumentList $psArgs -Wait -NoNewWindow -PassThru -RedirectStandardOutput $stdOutFile -RedirectStandardError $stdErrFile
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = if (Test-Path $stdErrFile) { 
                Get-Content $stdErrFile -Raw 
            } else { 
                "Auth script failed with exit code $($process.ExitCode)" 
            }
            # Clean up temp files
            if (Test-Path $stdOutFile) { Remove-Item $stdOutFile -Force }
            if (Test-Path $stdErrFile) { Remove-Item $stdErrFile -Force }
            throw "Auth script execution failed: $errorOutput"
        }
        
        # Read the output
        $output = ""
        if (Test-Path $stdOutFile) {
            $output = Get-Content $stdOutFile -Raw
        }
        
        # Clean up temp files
        try {
            if (Test-Path $stdOutFile) { Remove-Item $stdOutFile -Force }
            if (Test-Path $stdErrFile) { Remove-Item $stdErrFile -Force }
        }
        catch {
            Write-Log "Warning: Failed to clean up temp files: $($_.Exception.Message)" "WARN"
        }
        
        # Extract session data between markers
        $sessionDataMatch = $output | Select-String -Pattern "SESSION_DATA_START\s*(.*?)\s*SESSION_DATA_END" -AllMatches
        
        if ($sessionDataMatch.Matches.Count -eq 0) {
            throw "No session data found in auth script output"
        }
        
        $sessionJson = $sessionDataMatch.Matches[0].Groups[1].Value
        
        # Validate JSON
        try {
            $sessionData = $sessionJson | ConvertFrom-Json
            Write-Log "Auth script executed successfully, session data captured" "SUCCESS"
            return $sessionJson
        }
        catch {
            throw "Invalid session JSON returned from auth script: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Log "Auth script execution failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Start-AuthServer {
    # Validate environment
    if (-not $env:CERT_THUMBPRINT) {
        Write-Log "CERT_THUMBPRINT environment variable not set" "ERROR"
        Write-Log "Please set the certificate thumbprint:" "INFO"
        $thumbprint = Read-Host "Enter certificate thumbprint"
        if ($thumbprint) {
            $env:CERT_THUMBPRINT = $thumbprint
            [Environment]::SetEnvironmentVariable("CERT_THUMBPRINT", $thumbprint, "User")
            Write-Log "Certificate thumbprint set: $thumbprint" "SUCCESS"
        }
        else {
            Write-Log "Certificate thumbprint is required" "ERROR"
            return
        }
    }
    
    # Validate auth script exists
    if (-not (Test-Path $AuthScriptPath)) {
        Write-Log "Auth script not found at: $AuthScriptPath" "ERROR"
        return
    }
    
    # Create HTTP listener
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://127.0.0.1:$Port/"
    $listener.Prefixes.Add($prefix)
    
    try {
        $listener.Start()
        Write-Log "PowerShell HTTP Authentication Server started" "SUCCESS"
        Write-Log "Listening on: $prefix" "INFO"
        Write-Log "Certificate: $env:CERT_THUMBPRINT" "INFO"
        Write-Log "Auth Script: $AuthScriptPath" "INFO"
        Write-Log "" "INFO"
        Write-Log "Available endpoints:" "INFO"
        Write-Log "  GET  /health     - Health check" "INFO"
        Write-Log "  POST /auth       - Certificate authentication" "INFO"
        Write-Log "" "INFO"
        Write-Log "Press Ctrl+C to stop the server" "WARN"
        Write-Log "" "INFO"
        
        while ($listener.IsListening) {
            try {
                # Wait for a request
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $method = $request.HttpMethod
                $path = $request.Url.LocalPath
                $clientIP = $request.RemoteEndPoint.Address
                
                Write-Log "$method $path from $clientIP" "INFO"
                
                # Route requests
                switch -Regex ("$method $path") {
                    "GET /health" {
                        $healthResponse = @{
                            status = "ok"
                            service = "powershell-auth-server"
                            timestamp = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                            certificate = if ($env:CERT_THUMBPRINT) { $env:CERT_THUMBPRINT } else { "not-set" }
                        } | ConvertTo-Json
                        
                        Send-HttpResponse -Context $context -Body $healthResponse
                        Write-Log "Health check completed" "SUCCESS"
                    }
                    
                    "POST /auth" {
                        try {
                            # Read request body
                            $reader = New-Object System.IO.StreamReader($request.InputStream)
                            $requestBody = $reader.ReadToEnd()
                            $reader.Close()
                            
                            # Parse request parameters
                            $clientIds = ""
                            $stationId = "DOCKER"
                            
                            if ($requestBody) {
                                try {
                                    $requestData = $requestBody | ConvertFrom-Json
                                    if ($requestData.clientIds) {
                                        $clientIds = if ($requestData.clientIds -is [array]) {
                                            $requestData.clientIds -join ","
                                        } else {
                                            $requestData.clientIds
                                        }
                                    }
                                    if ($requestData.stationId) {
                                        $stationId = $requestData.stationId
                                    }
                                }
                                catch {
                                    Write-Log "Failed to parse request JSON, using defaults" "WARN"
                                }
                            }
                            
                            # Execute authentication
                            Write-Log "Starting certificate authentication..." "INFO"
                            $sessionJson = Invoke-AuthScript -ClientIds $clientIds -StationId $stationId
                            
                            # Send successful response
                            Send-HttpResponse -Context $context -Body $sessionJson
                            Write-Log "Authentication completed successfully" "SUCCESS"
                        }
                        catch {
                            Write-Log "Authentication failed: $($_.Exception.Message)" "ERROR"
                            Send-ErrorResponse -Context $context -StatusCode 500 -ErrorMessage $_.Exception.Message
                        }
                    }
                    
                    default {
                        Write-Log "Unknown endpoint: $method $path" "WARN"
                        Send-ErrorResponse -Context $context -StatusCode 404 -ErrorMessage "Endpoint not found"
                    }
                }
            }
            catch {
                Write-Log "Request processing error: $($_.Exception.Message)" "ERROR"
                try {
                    Send-ErrorResponse -Context $context -StatusCode 500 -ErrorMessage $_.Exception.Message
                }
                catch {
                    Write-Log "Failed to send error response: $($_.Exception.Message)" "ERROR"
                }
            }
        }
    }
    catch {
        Write-Log "Server error: $($_.Exception.Message)" "ERROR"
    }
    finally {
        if ($listener.IsListening) {
            $listener.Stop()
            Write-Log "HTTP server stopped" "INFO"
        }
    }
}

# Handle Ctrl+C gracefully
$null = Register-EngineEvent -SourceIdentifier "PowerShell.Exiting" -Action {
    Write-Log "Shutting down authentication server..." "WARN"
}

# Start the server
Write-Log "=== PowerShell HTTP Authentication Server ===" "SUCCESS"
Start-AuthServer
