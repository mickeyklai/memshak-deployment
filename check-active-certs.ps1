# --- Helpers ---
function Test-CertKeyOnline {
  param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)

  try {
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
    if ($rsa) {
      $null = $rsa.SignData([byte[]](0x01,0x02,0x03),
                            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
      return $true
    }
  } catch { return $false }

  try {
    $ecdsa = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Cert)
    if ($ecdsa) {
      $null = $ecdsa.SignData([byte[]](0x01,0x02,0x03),
                              [System.Security.Cryptography.HashAlgorithmName]::SHA256)
      return $true
    }
  } catch { return $false }

  return $false
}

function Get-ProviderName {
  param([System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
  try {
    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
    if ($rsa -and $rsa.Key -and $rsa.Key.Provider) { return $rsa.Key.Provider.Provider }
  } catch {}
  try {
    if ($Cert.PrivateKey -and $Cert.PrivateKey.CspKeyContainerInfo) {
      return $Cert.PrivateKey.CspKeyContainerInfo.ProviderName
    }
  } catch {}
  return $null
}

# --- Gather certificates that are usable right now (smart card inserted) ---
$online =
  Get-ChildItem Cert:\CurrentUser\My |
  Where-Object { $_.HasPrivateKey } |
  ForEach-Object {
    if (Test-CertKeyOnline -Cert $_) {
      $ku  = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension] }).KeyUsages
      $eku = ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.FriendlyName -join ', '
      [pscustomobject]@{
        Subject          = $_.Subject
        Issuer           = $_.Issuer
        NotBefore        = $_.NotBefore
        NotAfter         = $_.NotAfter
        Thumbprint       = $_.Thumbprint
        SerialNumber     = $_.SerialNumber
        FriendlyName     = $_.FriendlyName
        HasPrivateKey    = $_.HasPrivateKey
        Provider         = Get-ProviderName -Cert $_
        KeyUsage         = $ku
        EnhancedKeyUsage = $eku
        RawCertificate   = $_   # keep full cert object if you need deeper inspection
      }
    }
  }

# --- Apply filters ---
$patternCN  = '(?i)CN=.*PersonalID Supervised Operational'
$patternEKU = '(?i)(Client Authentication|Smart Card Log[- ]?on)'

$online |
  Where-Object {
    (($_.Subject + '|' + $_.Issuer) -match $patternCN) -and
    ($_.EnhancedKeyUsage -match $patternEKU)
  } |
  Sort-Object Subject |
  Format-List *
