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

# Global tracking for in-process auth execution (enables credential caching!)
$Global:AuthScriptContent = $null
$Global:FirstAuthTime = $null
$Global:AuthCallCount = 0
$Global:LastAuthTime = $null

function Invoke-AuthScript {
    param(
        [string]$ClientIds = "",
        [string]$StationId = "DOCKER",
        [object]$ExistingCounts = $null,
        [object]$ExistingData = $null
    )
    
    try {
        # Validate certificate thumbprint
        $certThumbprint = $env:CERT_THUMBPRINT
        if (-not $certThumbprint) {
            throw "CERT_THUMBPRINT environment variable not set"
        }
        
        # Validate auth script exists
        $scriptPath = Resolve-Path $AuthScriptPath -ErrorAction Stop
        
        # Increment call counter
        $Global:AuthCallCount++
        $isFirstAuth = ($Global:AuthCallCount -eq 1)
        $now = Get-Date
        if ($Global:LastAuthTime) {
            $delta = $now - $Global:LastAuthTime
            Write-Log ("Time since previous auth call: {0:N2}s" -f $delta.TotalSeconds) "INFO"
        }
        $Global:LastAuthTime = $now
        
        if ($isFirstAuth) {
            Write-Log "═══════════════════════════════════════════════════════" "SUCCESS"
            Write-Log "FIRST AUTH REQUEST - Password prompt is EXPECTED" "SUCCESS"
            Write-Log "Executing auth.ps1 IN-PROCESS for credential caching" "SUCCESS"
            Write-Log "═══════════════════════════════════════════════════════" "SUCCESS"
            $Global:FirstAuthTime = Get-Date
        } else {
            $elapsedSinceFirst = (Get-Date) - $Global:FirstAuthTime
            $elapsedSeconds = [math]::Round($elapsedSinceFirst.TotalSeconds, 1)
            Write-Log "═══════════════════════════════════════════════════════" "INFO"
            Write-Log "RE-AUTH REQUEST #$Global:AuthCallCount (${elapsedSeconds}s since first)" "INFO"
            Write-Log "Password prompt should NOT appear (credential caching!)" "INFO"
            Write-Log "═══════════════════════════════════════════════════════" "INFO"
        }
        
        Write-Log "Certificate thumbprint: $certThumbprint" "INFO"
        Write-Log "Client IDs: $ClientIds" "INFO"
        Write-Log "Station ID: $StationId" "INFO"
        
        # CRITICAL: Execute auth.ps1 IN THIS PROCESS using Invoke-Expression
        # This preserves Windows credential caching across multiple auth requests!
        
        # Load auth script content if not already loaded
        if ($null -eq $Global:AuthScriptContent) {
            Write-Log "Loading auth.ps1 content for in-process execution..." "INFO"
            $rawContent = Get-Content $scriptPath -Raw
            
            # Remove the param() block at the top - it's not valid inside a script block
            # We'll set the variables manually instead
            # The param block must be at the very start of the script
            if ($rawContent.TrimStart() -match '^param\s*\(') {
                # Find the closing parenthesis by counting parentheses
                $depth = 0
                $inParam = $false
                $endIndex = -1
                
                for ($i = 0; $i -lt $rawContent.Length; $i++) {
                    $char = $rawContent[$i]
                    
                    if ($char -eq '(' -and -not $inParam) {
                        # Check if this is the 'param(' opening
                        $before = $rawContent.Substring([Math]::Max(0, $i - 5), [Math]::Min(5, $i))
                        if ($before -match 'param$') {
                            $inParam = $true
                            $depth = 1
                        }
                    } elseif ($inParam) {
                        if ($char -eq '(') {
                            $depth++
                        } elseif ($char -eq ')') {
                            $depth--
                            if ($depth -eq 0) {
                                $endIndex = $i + 1
                                break
                            }
                        }
                    }
                }
                
                if ($endIndex -gt 0) {
                    $Global:AuthScriptContent = $rawContent.Substring($endIndex).TrimStart()
                    Write-Log "Removed param() block (${endIndex} chars) from auth script" "INFO"
                } else {
                    # Fallback: just skip first line if it starts with param
                    $lines = $rawContent -split "`n"
                    $firstNonParamLine = 0
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i].TrimStart() -notmatch '^param|^\s*\[|^\)') {
                            $firstNonParamLine = $i
                            break
                        }
                    }
                    $Global:AuthScriptContent = ($lines[$firstNonParamLine..($lines.Count - 1)] -join "`n")
                    Write-Log "Removed param() block using line-based fallback" "WARN"
                }
            } else {
                $Global:AuthScriptContent = $rawContent
            }
            
            Write-Log "Auth script content loaded (${($Global:AuthScriptContent.Length)} chars)" "SUCCESS"
        }
        
        # Parse client IDs array
        $clientIdArray = if ($ClientIds -and $ClientIds.Trim() -ne "") {
            $ClientIds.Split(',').Trim()
        } else {
            @()
        }
        
        # Parse existing counts
        $existingCountsStr = ""
        $existingDataStr = ""
        if ($ExistingCounts) {
            $existingCountsStr = $ExistingCounts | ConvertTo-Json -Compress
        }
        if ($ExistingData) {
            $existingDataStr = $ExistingData | ConvertTo-Json -Compress -Depth 10
        }
        
        Write-Log "Executing auth.ps1 script block IN CURRENT PROCESS..." "INFO"
        
        # Create a script block with the auth script content and execute it in current scope
        # This is THE KEY - by executing in the same process, Windows credential caching works!
        $scriptBlock = [ScriptBlock]::Create(@"
# Set parameters as variables for the script
`$thumbprint = '$certThumbprint'
`$ClientIds = @($($clientIdArray | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
`$StationId = '$StationId'
`$ExistingCounts = '$existingCountsStr'
`$ExistingData = '$existingDataStr'

# Execute the auth script content
$Global:AuthScriptContent
"@)
        
        # Capture output to extract session data
        $output = & {
            $ErrorActionPreference = 'Stop'
            # Redirect Write-Host to capture output
            $inSessionData = $false
            $sessionDataLines = @()
            
            # Execute the script block and capture all output
            try {
                & $scriptBlock *>&1 | ForEach-Object {
                    $line = $_.ToString()
                    if ($line -match "SESSION_DATA_START") {
                        $inSessionData = $true
                    } elseif ($line -match "SESSION_DATA_END") {
                        $inSessionData = $false
                    } elseif ($inSessionData) {
                        $sessionDataLines += $line
                    }
                    Write-Host $line
                }
            } catch {
                Write-Error "Script execution failed: $_"
                throw
            }
            
            # Return the captured session data
            return ($sessionDataLines -join "")
        }
        
        $sessionJson = $output
        
        if ([string]::IsNullOrWhiteSpace($sessionJson)) {
            throw "No session data captured from auth script"
        }
        
        # Validate JSON
        try {
            $sessionData = $sessionJson | ConvertFrom-Json
            if ($isFirstAuth) {
                Write-Log "✅ FIRST AUTH COMPLETED - Credentials now cached in process!" "SUCCESS"
            } else {
                Write-Log "✅ RE-AUTH COMPLETED using cached credentials!" "SUCCESS"
            }
            $guidPreview = if ($sessionData.guid) { ($sessionData.guid.Substring(0, [Math]::Min(8, $sessionData.guid.Length))) + '...' } else { 'missing' }
            $clientCount = if ($sessionData.metadata -and $sessionData.metadata.clientIds) { $sessionData.metadata.clientIds.Count } else { 0 }
            Write-Log "Session ready: GUID=$guidPreview | Clients=$clientCount | Timestamp=$([DateTimeOffset]::UtcNow.ToString('HH:mm:ss.fff'))" "INFO"
            return $sessionJson
        }
        catch {
            throw "Invalid session JSON: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Log "Auth script execution failed: $($_.Exception.Message)" "ERROR"
        Write-Log "Stack: $($_.ScriptStackTrace)" "ERROR"
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
                            $existingCounts = $null
                            $existingData = $null
                            
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
                                    if ($requestData.existingCounts) {
                                        $existingCounts = $requestData.existingCounts
                                    }
                                    if ($requestData.existingData) {
                                        $existingData = $requestData.existingData
                                    }
                                }
                                catch {
                                    Write-Log "Failed to parse request JSON, using defaults" "WARN"
                                }
                            }
                            
                            # Execute authentication
                            Write-Log "Starting certificate authentication..." "INFO"
                            $sessionJson = Invoke-AuthScript -ClientIds $clientIds -StationId $stationId -ExistingCounts $existingCounts -ExistingData $existingData
                            
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