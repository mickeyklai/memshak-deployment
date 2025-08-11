# Generate SSL certificates for localhost with trusted root installation
try {
    Write-Host "Creating self-signed certificate for localhost..."
    
    # Create self-signed certificate and install to LocalMachine\My
    $cert = New-SelfSignedCertificate -DnsName 'localhost','127.0.0.1' -CertStoreLocation 'cert:\LocalMachine\My' -NotAfter (Get-Date).AddYears(1) -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeyUsage KeyEncipherment,DigitalSignature -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1')
    
    Write-Host "Exporting certificate files..."
    
    # Export certificate to .crt file (DER format)
    $cert | Export-Certificate -FilePath 'ssl\localhost.crt' -Type CERT
    
    # Export to PFX for private key extraction
    $cert | Export-PfxCertificate -FilePath 'ssl\localhost.pfx' -Password (ConvertTo-SecureString -String 'localhost' -AsPlainText -Force)
    
    Write-Host "Installing certificate to Trusted Root Certification Authorities store..."
    
    # Import certificate to Trusted Root store so browsers will trust it
    $certPath = (Get-Item 'ssl\localhost.crt').FullName
    Import-Certificate -FilePath $certPath -CertStoreLocation 'cert:\LocalMachine\Root'
    
    Write-Host "Generating OpenSSL private key file..."
    
    # Try to generate .key file using OpenSSL if available
    if (Get-Command openssl -ErrorAction SilentlyContinue) {
        & openssl pkcs12 -in 'ssl\localhost.pfx' -out 'ssl\localhost.key' -nodes -password 'pass:localhost' 2>$null
    } else {
        # Fallback: Extract private key using .NET (more complex but works without OpenSSL)
        Write-Host "OpenSSL not available, using .NET to extract private key..."
        
        # Load PFX and extract private key
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
        
        # Clean up PFX object
        $pfx.Dispose()
    }
    
    # Convert .crt to PEM format for nginx
    $certBytes = [System.IO.File]::ReadAllBytes('ssl\localhost.crt')
    $certData = [System.Convert]::ToBase64String($certBytes)
    $certPem = "-----BEGIN CERTIFICATE-----`n"
    for($i = 0; $i -lt $certData.Length; $i += 64) {
        $certPem += $certData.Substring($i, [Math]::Min(64, $certData.Length - $i)) + "`n"
    }
    $certPem += "-----END CERTIFICATE-----"
    
    # Overwrite .crt with PEM format for nginx
    Set-Content -Path 'ssl\localhost.crt' -Value $certPem -Encoding ASCII
    
    Write-Host "✅ SSL certificate installation completed successfully!"
    Write-Host "Certificate: ssl\localhost.crt (PEM format for nginx)"
    Write-Host "Private Key: ssl\localhost.key (PEM format)"
    Write-Host "Trusted Root: Certificate installed to LocalMachine\Root store"
    Write-Host "🔒 Browsers should now trust https://localhost:8443 connections"
    
    # Clean up temporary files
    if (Test-Path 'ssl\localhost.pfx') {
        Remove-Item 'ssl\localhost.pfx' -Force
    }
    
} catch {
    Write-Host "⚠️ SSL certificate generation failed: $($_.Exception.Message)"
    Write-Host "The system will still work but browsers may show security warnings"
    
    # Don't create fallback certificates - let the user know they need admin rights
    Write-Host ""
    Write-Host "SOLUTION: Run the installer as Administrator for proper SSL certificate installation"
    Write-Host "Right-click on the installer and select 'Run as administrator'"
    Write-Host ""
    exit 1
}
