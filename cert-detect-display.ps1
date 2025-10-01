param()

function Test-CertKeyOnline {
    param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
    
    try {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
        if ($rsa) {
            $null = $rsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
            return $true
        }
    } catch { }
    
    try {
        $ecdsa = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Cert)
        if ($ecdsa) {
            $null = $ecdsa.SignData([byte[]](0x01,0x02,0x03), [System.Security.Cryptography.HashAlgorithmName]::SHA256)
            return $true
        }
    } catch { }
    
    return $false
}

function Get-ProviderName {
    param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
    
    try {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
        if ($rsa -and $rsa.Key -and $rsa.Key.Provider) {
            return $rsa.Key.Provider.Provider
        }
    } catch {}
    
    try {
        if ($Cert.PrivateKey -and $Cert.PrivateKey.CspKeyContainerInfo) {
            return $Cert.PrivateKey.CspKeyContainerInfo.ProviderName
        }
    } catch {}
    
    return 'N/A'
}

# Fast / slow path detection for display
Write-Host 'Scanning for PersonalID certificates (fast-path first)...'

$patternCN  = '(?i)CN=.*PersonalID Supervised Operational'
$patternEKU = '(?i)(Client Authentication|Smart Card Log[-\s]?on|אימות לקוח|כניסה של כרטיס חכם)'

$candidates = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object {
    $ekuExt   = $_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }
    $ekuNames = $ekuExt.EnhancedKeyUsages.FriendlyName -join ', '
    if ((($_.Subject + '|' + $_.Issuer) -match $patternCN) -and ($ekuNames -match $patternEKU)) {
        [pscustomobject]@{
            Subject = $_.Subject
            Issuer = $_.Issuer
            NotAfter = $_.NotAfter
            Thumbprint = $_.Thumbprint
            EnhancedKeyUsage = $ekuNames
            RawCertificate = $_
        }
    }
}

if (-not $candidates -or $candidates.Count -eq 0) {
    Write-Host 'No matching PersonalID candidate certificates found.'
    return
}

if ($candidates.Count -eq 1) {
    $only = $candidates[0]
    Write-Host 'FAST-PATH: Single candidate detected (skipping private key sign test):'
    Write-Host "  Subject: $($only.Subject)"
    Write-Host "  Expires: $($only.NotAfter)"
    Write-Host "  Thumbprint: $($only.Thumbprint)"
    Write-Host "  EKU: $($only.EnhancedKeyUsage)"
    return
}

Write-Host ("Found {0} candidates. Performing private key accessibility test..." -f $candidates.Count)

$online = foreach ($c in $candidates) {
    if (Test-CertKeyOnline -Cert $c.RawCertificate) {
        [pscustomobject]@{
            Subject        = $c.Subject
            Issuer         = $c.Issuer
            NotAfter       = $c.NotAfter
            Thumbprint     = $c.Thumbprint
            Provider       = Get-ProviderName -Cert $c.RawCertificate
            EnhancedKeyUsage = $c.EnhancedKeyUsage
        }
    }
}

if (-not $online -or $online.Count -eq 0) {
    Write-Host 'No candidates passed private key online test.'
    return
}

Write-Host 'Online-accessible PersonalID certificates:'
$online | ForEach-Object {
    Write-Host "  Subject: $($_.Subject)"
    Write-Host "  Provider: $($_.Provider)"
    Write-Host "  Expires: $($_.NotAfter)"
    Write-Host "  Thumbprint: $($_.Thumbprint)"
    Write-Host ''
}