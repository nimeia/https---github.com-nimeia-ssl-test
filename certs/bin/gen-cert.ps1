param(
    [string]$Domain = "svc.local",
    [string]$Org = "MyOrg",
    [string]$Country = "CN",
    [string]$OutputPath = "..\src\main\resources\certs",
    [string[]]$Services = @("eureka", "gateway", "user", "product", "order"),
    [string[]]$SanList = @("127.0.0.1", "localhost", "*.demoapi.io","192.168.10.116")
)

$caKey = "$OutputPath\ca.key"
$caCert = "$OutputPath\ca.crt"

# �������Ŀ¼
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# ���� CA ˽Կ����ǩ��֤��
if (!(Test-Path $caKey)) {
    Write-Host "? ���� Root CA..."
    openssl genrsa -out $caKey 2048
    openssl req -x509 -new -nodes -key $caKey -sha256 -days 3650 -out $caCert -subj "/CN=MyCA/O=$Org/C=$Country"
}

foreach ($service in $Services) {
    $fqdn = "$service.$Domain"
    $certPath = "$OutputPath\$service"
    New-Item -ItemType Directory -Path $certPath -Force | Out-Null

    $keyFile = "$certPath\key.pem"
    $csrFile = "$certPath\csr.pem"
    $crtFile = "$certPath\cert.pem"
    $p12File = "$certPath\keystore.p12"
    $truststoreFile = "$certPath\truststore.p12"
    $extFile = "$certPath\ext.cnf"

    # д�� ext.cnf
    $allSans = @("DNS:$fqdn") + ($SanList | ForEach-Object {
        if ($_ -match '^\d{1,3}(\.\d{1,3}){3}$') { "IP:$_" } else { "DNS:$_" }
    })
    $sanString = [string]::Join(",", $allSans)

@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = $sanString
"@ | Out-File -Encoding ascii $extFile

    Write-Host "`n? Ϊ���� $service ����֤��..."

    openssl genrsa -out $keyFile 2048
    openssl req -new -key $keyFile -out $csrFile -subj "/CN=$fqdn/O=$Org/C=$Country"
    openssl x509 -req -in $csrFile -CA $caCert -CAkey $caKey -CAcreateserial -out $crtFile -days 825 -sha256 -extfile $extFile

    # ��� keystore
    Write-Host "? ��� keystore (PKCS12)..."
    openssl pkcs12 -export -in $crtFile -inkey $keyFile -out $p12File -name "$service-cert" -CAfile $caCert -caname root -passout pass:changeit

    # ���� truststore������ CA �����з��� cert
    $truststorePem = "$certPath\truststore.pem"
    $truststoreCombined = @($caCert)

    foreach ($s in $Services) {
        $sCert = "$OutputPath\$s\cert.pem"
        if (Test-Path $sCert) {
            $truststoreCombined += $sCert
        }
    }

    # ��� truststorePem
    Set-Content -Path $truststorePem -Value "" -Encoding ascii

    # ���׷������ PEM �ļ�����
    foreach ($pemPath in $truststoreCombined) {
        Get-Content -Path $pemPath -Encoding ascii | Add-Content -Path $truststorePem -Encoding ascii
    }

    #openssl pkcs12 -export -out $truststoreFile -in $caCert -inkey $keyFile -certfile $truststorePem -name "$service-trust" -passout pass:changeit
    openssl pkcs12 -export -out $truststoreFile -in $crtFile -inkey $keyFile  -certfile $truststorePem -name "$service-trust" -passout pass:changeit

    #openssl pkcs12 -export  -out "$certPath\truststore.p12" -in "$certPath\truststore.pem" -name "$service-trust" -passout pass:changeit
}

Write-Host "`n? ���з���֤��������ϣ�·����$OutputPath"
