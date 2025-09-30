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

$online = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object {
    if (Test-CertKeyOnline -Cert $_) {
        $eku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.FriendlyName -join ', '
        
        [pscustomobject]@{
            Subject = $_.Subject
            Issuer = $_.Issuer
            NotAfter = $_.NotAfter
            Thumbprint = $_.Thumbprint
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

# Select the certificate with the longest validity (most recent expiry)
$selectedCert = $validCerts | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1

if ($selectedCert) {
    $selectedCert.Thumbprint
} else {
    'NO_ONLINE_CERTIFICATES_FOUND'
}