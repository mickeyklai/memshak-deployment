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

# Main detection logic
try {
    Write-Error 'Scanning certificate store (fast-path first)...' -ErrorAction Continue

    $patternCN  = '(?i)CN=.*PersonalID Supervised Operational'
    $patternEKU = '(?i)(Client Authentication|Smart Card Log[-\s]?on|אימות לקוח|כניסה של כרטיס חכם)'

    # FAST PATH: collect candidates without doing signing yet
    $candidates = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey } | ForEach-Object {
        $ekuExt = $_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }
        $ekuNames = $ekuExt.EnhancedKeyUsages.FriendlyName -join ', '
        if ( (($_.Subject + '|' + $_.Issuer) -match $patternCN) -and ($ekuNames -match $patternEKU) ) {
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
        Write-Error 'ERROR: No matching PersonalID candidate certificates with private key present' -ErrorAction Continue
        Write-Output 'NO_CERTIFICATES_FOUND'
        return
    }

    # If exactly one candidate, accept immediately (skip online sign test)
    if ($candidates.Count -eq 1) {
        $only = $candidates[0]
        Write-Error "FAST-PATH: Single candidate detected. Selecting thumbprint: $($only.Thumbprint)" -ErrorAction Continue
        Write-Output $only.Thumbprint
        return
    }

    Write-Error ("Found {0} candidate certificates. Performing private key online accessibility test..." -f $candidates.Count) -ErrorAction Continue

    # SLOW PATH: confirm online accessibility via sign attempt
    $online = foreach ($c in $candidates) {
        if (Test-CertKeyOnline -Cert $c.RawCertificate) {
            $prov = Get-ProviderName -Cert $c.RawCertificate
            [pscustomobject]@{
                Subject = $c.Subject
                Issuer = $c.Issuer
                NotAfter = $c.NotAfter
                Thumbprint = $c.Thumbprint
                Provider = $prov
                EnhancedKeyUsage = $c.EnhancedKeyUsage
                RawCertificate = $c.RawCertificate
            }
        }
    }

    if (-not $online -or $online.Count -eq 0) {
        Write-Error 'ERROR: No certificates passed private key online test' -ErrorAction Continue
        Write-Output 'NO_CERTIFICATES_FOUND'
        return
    }

    Write-Error 'Online-accessible PersonalID certificate(s):' -ErrorAction Continue
    $online | ForEach-Object {
        Write-Error "  Subject: $($_.Subject)" -ErrorAction Continue
        Write-Error "  Provider: $($_.Provider)" -ErrorAction Continue
        Write-Error "  Expires: $($_.NotAfter)" -ErrorAction Continue
        Write-Error "  Thumbprint: $($_.Thumbprint)" -ErrorAction Continue
        Write-Error '' -ErrorAction Continue
    }

    $selected = $online | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1
    if ($selected) {
        Write-Error "SUCCESS: Selected certificate with thumbprint: $($selected.Thumbprint)" -ErrorAction Continue
        Write-Output $selected.Thumbprint
        return
    }

    Write-Error 'ERROR: No non-expired certificate available after filtering' -ErrorAction Continue
    Write-Output 'NO_CERTIFICATES_FOUND'

} catch {
    Write-Error "ERROR: Certificate detection failed: $($_.Exception.Message)" -ErrorAction Continue
    Write-Output 'DETECTION_ERROR'
}