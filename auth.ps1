param(
    [Parameter(Mandatory = $true)]
    [string]$thumbprint,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ClientIds = @(),  # Array of client IDs to sync - used for loading existing data
    
    [Parameter(Mandatory = $false)]
    [string]$StationId  # Station ID from backend config
)

Add-Type -AssemblyName System.Web

function Get-UserCertificate {
    param(
        [Parameter(Mandatory = $true)][string]$Thumbprint
    )
    
    try {
        # Ensure certificate provider is loaded
        Import-Module PKI -ErrorAction SilentlyContinue
        
        # Try to access certificate store using different methods and locations
        $cert = $null
        
        # Method 1: Try CurrentUser store first
        try {
            $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$Thumbprint" -ErrorAction Stop
            Write-Host "Found certificate in CurrentUser\My store"
        }
        catch {
            Write-Host "Certificate not found in CurrentUser\My store, trying LocalMachine store..."
            
            # Method 2: Try LocalMachine store
            try {
                $cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$Thumbprint" -ErrorAction Stop
                Write-Host "Found certificate in LocalMachine\My store"
            }
            catch {
                Write-Host "Certificate not found in LocalMachine\My store, trying .NET X509Store methods..."
                
                # Method 3: Try using .NET X509Store for CurrentUser
                try {
                    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "CurrentUser")
                    $store.Open("ReadOnly")
                    $certificates = $store.Certificates
                    $cert = $certificates | Where-Object { $_.Thumbprint -eq $Thumbprint }
                    $store.Close()
                    
                    if ($cert) {
                        Write-Host "Found certificate using .NET CurrentUser X509Store method"
                    }
                    else {
                        # Method 4: Try using .NET X509Store for LocalMachine
                        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")
                        $store.Open("ReadOnly")
                        $certificates = $store.Certificates
                        $cert = $certificates | Where-Object { $_.Thumbprint -eq $Thumbprint }
                        $store.Close()
                        
                        if ($cert) {
                            Write-Host "Found certificate using .NET LocalMachine X509Store method"
                        }
                        else {
                            Write-Host "Certificate not found in any certificate store"
                        }
                    }
                }
                catch {
                    Write-Host "Certificate access methods failed: $($_.Exception.Message)"
                }
            }
        }
        
        return $cert
        
    }
    catch {
        Write-Error "Certificate access failed: $($_.Exception.Message)"
        return $null
    }
}

function New-BtlWebSession {
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
    return $session
}

function Get-BtlInitialResponse {
    param(
        [Parameter(Mandatory = $true)]$Cert,
        [Parameter(Mandatory = $true)]$Session
    )
    return Invoke-WebRequest -Uri "https://mygimla.btl.gov.il" -Certificate $Cert -WebSession $Session -TimeoutSec 120
}

function Get-GuidFromUri {
    param([string]$Uri)
    return [System.Web.HttpUtility]::ParseQueryString($Uri).Get("guid")
}

function Get-ExistingClientCounts {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ClientIds
    )
    
    $existingCounts = @{}
    
    foreach ($clientId in $ClientIds) {
        $clientDir = "./data/$clientId"
        $clientCounts = @{
            michtavimCount = 0
            protocolsCount = 0
        }
        
        # Count existing michtavim
        $michtavimPath = Join-Path $clientDir "Get-Michtavim.json"
        if (Test-Path $michtavimPath) {
            try {
                $michtavimContent = Get-Content $michtavimPath -Raw -Encoding UTF8
                $michtavimJson = $michtavimContent | ConvertFrom-Json
                if ($michtavimJson.Letters) {
                    $clientCounts.michtavimCount = $michtavimJson.Letters.Count
                    Write-Host "     Found $($michtavimJson.Letters.Count) existing michtavim for client $clientId" -ForegroundColor Gray
                }
            }
            catch {
                Write-Warning "Failed to count existing michtavim for client $clientId`: $($_.Exception.Message)"
            }
        }
        
        # Count existing protocols
        $protocolsPath = Join-Path $clientDir "Get-Protocols.json"
        if (Test-Path $protocolsPath) {
            try {
                $protocolsContent = Get-Content $protocolsPath -Raw -Encoding UTF8
                $protocolsJson = $protocolsContent | ConvertFrom-Json
                if ($protocolsJson.Protocols) {
                    $clientCounts.protocolsCount = $protocolsJson.Protocols.Count
                    Write-Host "     Found $($protocolsJson.Protocols.Count) existing protocols for client $clientId" -ForegroundColor Gray
                }
            }
            catch {
                Write-Warning "Failed to count existing protocols for client $clientId`: $($_.Exception.Message)"
            }
        }
        
        $existingCounts[$clientId] = $clientCounts
    }
    
    return $existingCounts
}

function Invoke-BtlLogin {
    param(
        [Parameter(Mandatory = $true)][string]$Guid,
        [Parameter(Mandatory = $true)]$Session
    )
    $headers = @{
        "Accept"             = "application/json"
        "Accept-Encoding"    = "gzip, deflate, br, zstd"
        "Accept-Language"    = "en-GB,en;q=0.9"
        "Origin"             = "https://mygimla.btl.gov.il"
        "Referer"            = "https://mygimla.btl.gov.il/BTL.ILG.MeyazgimGimlaot.WebSite/login?guid=$Guid"
        "Sec-Fetch-Dest"     = "empty"
        "Sec-Fetch-Mode"     = "cors"
        "Sec-Fetch-Site"     = "same-origin"
        "sec-ch-ua"          = '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"'
        "sec-ch-ua-mobile"   = "?0"
        "sec-ch-ua-platform" = '"Windows"'
    }
    $loginBody = '"' + $Guid + '"'
    return Invoke-WebRequest -Uri "https://mygimla.btl.gov.il/BTL.ILG.MeyazgimGimlaot.WebSite/api/authentication/login" `
        -Method POST `
        -WebSession $Session `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $loginBody
}


# Handle comma-separated string input from Node.js
Write-Host "Debug: auth.ps1 received ClientIds parameter: $($ClientIds | ConvertTo-Json)" -ForegroundColor Magenta
Write-Host "Debug: auth.ps1 ClientIds.Count = $($ClientIds.Count)" -ForegroundColor Magenta
Write-Host "Debug: auth.ps1 ClientIds type: $($ClientIds.GetType())" -ForegroundColor Magenta

if ($ClientIds.Count -eq 1 -and $ClientIds[0].Contains(',')) {
    Write-Host "Debug: auth.ps1 splitting comma-separated string" -ForegroundColor Magenta
    $ClientIds = $ClientIds[0] -split ','
    Write-Host "Debug: auth.ps1 after splitting: $($ClientIds | ConvertTo-Json)" -ForegroundColor Magenta
}

# Main authentication flow
Write-Host "=== CERTIFICATE AUTHENTICATION SCRIPT ===" -ForegroundColor Green
Write-Host "Starting authentication process..." -ForegroundColor Yellow

# Get certificate thumbprint from parameter or environment variable
if (-not $thumbprint) {
    $thumbprint = $env:CERT_THUMBPRINT
    if (-not $thumbprint) {
        Write-Error "Certificate thumbprint not provided as parameter or CERT_THUMBPRINT environment variable"
        exit 1
    }
}

# Load existing data for efficiency if client IDs are provided
$existingClientData = @{}
Write-Host "Debug: About to check ClientIds.Count = $($ClientIds.Count)" -ForegroundColor Magenta
if ($ClientIds.Count -gt 0) {
    Write-Host "Loading existing data for $($ClientIds.Count) clients..." -ForegroundColor Cyan
    Write-Host "Debug: Client IDs to load existing data for: $($ClientIds -join ', ')" -ForegroundColor Magenta
    $existingClientCounts = Get-ExistingClientCounts -ClientIds $ClientIds
    Write-Host "   ✓ Loaded existing counts for $($existingClientCounts.Keys.Count) clients" -ForegroundColor Green
    
    # Debug: Show what was loaded
    foreach ($clientId in $existingClientCounts.Keys) {
        $clientCounts = $existingClientCounts[$clientId]
        Write-Host "Debug: Loaded existing counts for client $clientId`: $($clientCounts.michtavimCount) michtavim, $($clientCounts.protocolsCount) protocols" -ForegroundColor Magenta
    }
} else {
    Write-Host "Debug: No client IDs provided (ClientIds.Count = 0), skipping existing data loading" -ForegroundColor Magenta
}

try {
    # Step 1: Get certificate
    Write-Host "1. Getting certificate with thumbprint: $thumbprint" -ForegroundColor Cyan
    $cert = Get-UserCertificate -Thumbprint $thumbprint
    
    if (-not $cert) {
        Write-Error "Certificate with thumbprint $thumbprint not found"
        exit 1
    }
    
    Write-Host "   ✓ Certificate found: $($cert.Subject)" -ForegroundColor Green
    Write-Host "   ✓ Has private key: $($cert.HasPrivateKey)" -ForegroundColor Green
    
    # Step 2: Create session
    Write-Host "2. Creating web session..." -ForegroundColor Cyan
    $session = New-BtlWebSession
    Write-Host "   ✓ Session created" -ForegroundColor Green
    
    # Step 3: Initial response with certificate
    Write-Host "3. Getting initial response with certificate..." -ForegroundColor Cyan
    try {
        Write-Host "Before requesting initial response"
        $response = Get-BtlInitialResponse -Cert $cert -Session $session
    }
    catch {
        Write-Host "Failed to get initial response: $($_.Exception.Message)"
        Write-Host "initial response error inner ex: $($_.Exception.InnerException.Message)"
    }

    Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 601)
    $response = Get-BtlInitialResponse -Cert $cert -Session $session
    $uri = $response.BaseResponse.RequestMessage.RequestUri
    $guid = Get-GuidFromUri -Uri $uri.Query
    # $testGuid = New-Guid
    # Write-Host "   ✓ Initial response received, GUID: $testGuid.Guid" -ForegroundColor Green
    # try {
    #     $loginResponse = Invoke-BtlLogin -Guid $testGuid.Guid -Session $session
    # }
    # catch {
    #     Write-Host "Login request failed: $($_.Exception.Message)"
    # }
        
    # Step 4: Capture session state for handoff (no login/office selection)
    Write-Host "4. Capturing session state..." -ForegroundColor Cyan
    
    # Debug: Show what existing data is being added to session
    Write-Host "Debug: Adding existingClientData to session metadata:" -ForegroundColor Magenta
    Write-Host "Debug: existingClientData.Keys.Count = $($existingClientData.Keys.Count)" -ForegroundColor Magenta
    foreach ($clientId in $existingClientData.Keys) {
        $mCount = if ($existingClientData.$clientId.michtavim) { $existingClientData.$clientId.michtavim.Count } else { 0 }
        $pCount = if ($existingClientData.$clientId.protocols) { $existingClientData.$clientId.protocols.Count } else { 0 }
        Write-Host "Debug: Session metadata will include client $clientId`: $mCount michtavim, $pCount protocols" -ForegroundColor Magenta
    }
    
    $sessionState = @{
        cookies  = @()
        headers  = @{}
        certificates = @()
        guid     = $guid
        userAgent = $session.UserAgent
        metadata = @{
            clientIds = $ClientIds
            stationId = $StationId
            existingCounts = $existingClientCounts
            expiresAt = [int64]([DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeMilliseconds())
            userId = $null  # Will be set by the backend when processing
        }
    }
    
    # Extract all session headers
    Write-Host "   Capturing session headers..." -ForegroundColor Yellow
    
    # Try to extract headers from the session object
    try {
        Write-Host "   Inspecting session object for headers..." -ForegroundColor Gray
        
        # Check if session has Headers property
        if ($session.PSObject.Properties['Headers']) {
            Write-Host "   Found Headers property on session" -ForegroundColor Gray
            foreach ($header in $session.Headers.GetEnumerator()) {
                $sessionState.headers[$header.Key] = $header.Value
                Write-Host "     Added header: $($header.Key)" -ForegroundColor Gray
            }
        }
        
        # Check for DefaultRequestHeaders
        if ($session.PSObject.Properties['DefaultRequestHeaders']) {
            Write-Host "   Found DefaultRequestHeaders property on session" -ForegroundColor Gray
            foreach ($header in $session.DefaultRequestHeaders.GetEnumerator()) {
                $sessionState.headers[$header.Key] = $header.Value -join ', '
                Write-Host "     Added default header: $($header.Key)" -ForegroundColor Gray
            }
        }
        
        # Check all properties to find authorization or other headers
        Write-Host "   Session object properties:" -ForegroundColor Gray
        $session.PSObject.Properties | ForEach-Object {
            Write-Host "     Property: $($_.Name) = $($_.Value)" -ForegroundColor Gray
            
            # Look for authorization-related properties
            if ($_.Name -like "*Auth*" -or $_.Name -like "*Token*" -or $_.Name -like "*Header*") {
                Write-Host "     *** Potential header property: $($_.Name) = $($_.Value)" -ForegroundColor Yellow
                
                # Try to add it to headers if it's a string
                if ($_.Value -is [string] -and -not [string]::IsNullOrWhiteSpace($_.Value)) {
                    $sessionState.headers[$_.Name] = $_.Value
                }
            }
        }
        
    }
    catch {
        Write-Warning "Failed to extract session headers: $($_.Exception.Message)"
    }
    
    Write-Host "   ✓ Captured $($sessionState.headers.Count) headers from session" -ForegroundColor Green
    
    # Extract certificates from session
    # Write-Host "   Capturing session certificates..." -ForegroundColor Yellow
    # try {
    #     if ($session.PSObject.Properties['Certificates']) {
    #         Write-Host "   Found Certificates property on session" -ForegroundColor Gray
    #         foreach ($cert in $session.Certificates) {
    #             if ($cert) {
    #                 $certObj = @{
    #                     Subject = $cert.Subject
    #                     Issuer = $cert.Issuer
    #                     Thumbprint = $cert.Thumbprint
    #                     NotBefore = $cert.NotBefore.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #                     NotAfter = $cert.NotAfter.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #                     HasPrivateKey = $cert.HasPrivateKey
    #                 }
    #                 $sessionState.certificates += $certObj
    #                 Write-Host "     Added certificate: $($cert.Subject)" -ForegroundColor Gray
    #             }
    #         }
    #     }
    #     else {
    #         Write-Host "   No Certificates property found on session" -ForegroundColor Gray
    #         # Add the certificate we used for authentication
    #         if ($cert) {
    #             $certObj = @{
    #                 Subject = $cert.Subject
    #                 Issuer = $cert.Issuer
    #                 Thumbprint = $cert.Thumbprint
    #                 NotBefore = $cert.NotBefore.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #                 NotAfter = $cert.NotAfter.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    #                 HasPrivateKey = $cert.HasPrivateKey
    #             }
    #             $sessionState.certificates += $certObj
    #             Write-Host "     Added authentication certificate: $($cert.Subject)" -ForegroundColor Gray
    #         }
    #     }
    #     Write-Host "   ✓ Captured $($sessionState.certificates.Count) certificates" -ForegroundColor Green
    # }
    # catch {
    #     Write-Warning "Failed to extract session certificates: $($_.Exception.Message)"
    # }
    
    # Extract cookies using the specified method for mygimla domain
    Write-Host "   Capturing cookies for mygimla.btl.gov.il..." -ForegroundColor Yellow
    try {
        $mygimlaUrl = [Uri]"https://mygimla.btl.gov.il"
        $mygimlacookies = $session.Cookies.GetCookies($mygimlaUrl)
        
        foreach ($cookie in $mygimlacookies) {
            if (-not [string]::IsNullOrWhiteSpace($cookie.Name)) {
                $cookieObj = @{
                    name   = $cookie.Name
                    value  = $cookie.Value
                    domain = $cookie.Domain
                    path   = $cookie.Path
                }
                if ($cookie.Expires -and $cookie.Expires -ne [DateTime]::MinValue) {
                    $cookieObj.expires = $cookie.Expires.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
                if ($cookie.PSObject.Properties['HttpOnly']) { 
                    $cookieObj.httpOnly = $cookie.HttpOnly 
                }
                if ($cookie.PSObject.Properties['Secure']) { 
                    $cookieObj.secure = $cookie.Secure 
                }
                $sessionState.cookies += $cookieObj
            }
        }
        Write-Host "   ✓ Captured $($sessionState.cookies.Count) cookies from mygimla domain" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to get mygimla cookies, falling back to all cookies: $($_.Exception.Message)"
        
        # Fallback: Extract all cookies from session
        foreach ($cookie in $session.Cookies) {
            if (-not [string]::IsNullOrWhiteSpace($cookie.Name)) {
                $cookieObj = @{
                    name   = $cookie.Name
                    value  = $cookie.Value
                    domain = $cookie.Domain
                    path   = $cookie.Path
                }
                if ($cookie.PSObject.Properties['Expires'] -and $cookie.Expires -and $cookie.Expires -ne [DateTime]::MinValue) {
                    $cookieObj.expires = $cookie.Expires.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
                if ($cookie.PSObject.Properties['HttpOnly']) { 
                    $cookieObj.httpOnly = $cookie.HttpOnly 
                }
                if ($cookie.PSObject.Properties['Secure']) { 
                    $cookieObj.secure = $cookie.Secure 
                }
                $sessionState.cookies += $cookieObj
            }
        }
        Write-Host "   ✓ Captured $($sessionState.cookies.Count) cookies (fallback method)" -ForegroundColor Green
    }
    
    Write-Host "   ✓ Session state captured ($($sessionState.cookies.Count) cookies)" -ForegroundColor Green
    
    # Session data will be sent to remote service via stdout (no local file needed)
    
    # Also output session data with markers for parsing (for compatibility)
    # Output session data with clear markers for HTTP server parsing
    Write-Host "`n=== SESSION DATA OUTPUT ===" -ForegroundColor Yellow
    Write-Host "SESSION_DATA_START"
    Write-Output ($sessionState | ConvertTo-Json -Depth 10 -Compress)
    Write-Host "SESSION_DATA_END"
    
    Write-Host "`n✅ Authentication completed successfully!" -ForegroundColor Green
    Write-Host "Session data is ready for handoff to remote service." -ForegroundColor Green
    
}
catch {
    Write-Error "Authentication failed: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}