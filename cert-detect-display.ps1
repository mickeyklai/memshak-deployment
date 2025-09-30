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

# Test certificates for accessible private keys
Write-Host 'Testing certificates for accessible private keys...'

$online = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object {
    if (Test-CertKeyOnline -Cert $_) {
        $ku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension] }).KeyUsages
        $eku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.FriendlyName -join ', '
        
        [pscustomobject]@{
            Subject = $_.Subject
            Issuer = $_.Issuer
            NotAfter = $_.NotAfter
            Thumbprint = $_.Thumbprint
            Provider = Get-ProviderName -Cert $_
            EnhancedKeyUsage = $eku
            RawCertificate = $_
        }
    }
}

$patternCN = '(?i)CN=.*PersonalID Supervised Operational'
$patternEKU = '(?i)(Client Authentication|Smart Card Log[-\s]?on)'

$validCerts = $online | Where-Object {
    (($_.Subject + '|' + $_.Issuer) -match $patternCN) -and 
    ($_.EnhancedKeyUsage -match $patternEKU)
}

if ($validCerts) {
    Write-Host 'Found PersonalID certificate(s) with accessible private keys:'
    $validCerts | ForEach-Object {
        Write-Host "  Subject: $($_.Subject)"
        Write-Host "  Provider: $($_.Provider)"
        Write-Host "  Expires: $($_.NotAfter)"
        Write-Host "  Thumbprint: $($_.Thumbprint)"
        Write-Host ''
    }
} else {
    Write-Host 'No PersonalID certificates found with accessible private keys'
}