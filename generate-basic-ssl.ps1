# Generate basic SSL certificates for non-admin users
try {
    Write-Host "Creating basic SSL certificates..."
    
    # Create self-signed certificate in CurrentUser store (doesn't require admin)
    $cert = New-SelfSignedCertificate -DnsName 'localhost','127.0.0.1' -CertStoreLocation 'cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(1) -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256
    
    Write-Host "Exporting certificate files..."
    
    # Export certificate and key
    $cert | Export-Certificate -FilePath 'ssl\localhost.crt' -Type CERT
    $cert | Export-PfxCertificate -FilePath 'ssl\localhost.pfx' -Password (ConvertTo-SecureString -String 'localhost' -AsPlainText -Force)
    
    # Extract private key
    $pfx = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new('ssl\localhost.pfx', 'localhost', [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($pfx)
    
    # Export private key in PKCS#8 format
    $keyBytes = $privateKey.ExportPkcs8PrivateKey()
    $keyData = [System.Convert]::ToBase64String($keyBytes)
    $keyPem = "-----BEGIN PRIVATE KEY-----`n"
    for($i = 0; $i -lt $keyData.Length; $i += 64) {
        $keyPem += $keyData.Substring($i, [Math]::Min(64, $keyData.Length - $i)) + "`n"
    }
    $keyPem += "-----END PRIVATE KEY-----"
    Set-Content -Path 'ssl\localhost.key' -Value $keyPem -Encoding ASCII
    
    # Convert .crt to PEM format for nginx
    $certBytes = [System.IO.File]::ReadAllBytes('ssl\localhost.crt')
    $certData = [System.Convert]::ToBase64String($certBytes)
    $certPem = "-----BEGIN CERTIFICATE-----`n"
    for($i = 0; $i -lt $certData.Length; $i += 64) {
        $certPem += $certData.Substring($i, [Math]::Min(64, $certData.Length - $i)) + "`n"
    }
    $certPem += "-----END CERTIFICATE-----"
    Set-Content -Path 'ssl\localhost.crt' -Value $certPem -Encoding ASCII
    
    # Clean up
    Remove-Item 'ssl\localhost.pfx' -Force
    $pfx.Dispose()
    
    Write-Host "✅ Basic SSL certificates created"
    Write-Host "⚠️  Note: Browsers may show security warnings"
    Write-Host "💡 To fix: Run installer as administrator for trusted root installation"
    
} catch {
    Write-Host "❌ SSL certificate generation failed: $($_.Exception.Message)"
    exit 1
}
