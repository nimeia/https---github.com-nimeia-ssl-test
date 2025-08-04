# ================== �������� ==================
$caName = "MyCompany Root CA"
$O ="MyCompany"
$OU = "IT Department"
$C = "CN"
$caKey = "rootCA.key"
$caCert = "rootCA.crt"
$truststoreFile = "truststore.p12"
$truststorePassword = "changeit"

$services = @("order-service", "gateway-service", "user-service", "product-service")
$dnsNames = @("localhost", "mydomain.com", "*.mydomain.com")
$ipAddresses = @("127.0.0.1", "192.168.0.238", "172.17.192.1")

$keystorePassword = "changeit"
$validDays = 3650
$openssl = "openssl"

# ��������Ŀ¼
$workDir = "..\src\main\resources\certs"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Set-Location $workDir

# ================== ������������ CA ==================
function New-RootCA {
    if (!(Test-Path $caCert)) {
        Write-Host "���� Root CA..."
        & $openssl req -x509 -newkey rsa:4096 -nodes `
            -keyout $caKey `
            -out $caCert `
            -days $validDays `
            -subj "/CN=$caName/O=$O/OU=$OU/C=$C" `
    } else {
        Write-Host "Root CA �Ѵ��ڣ��������ɡ�"
    }
}

# ================== ���������� SAN �����ļ� ==================
function Create-SANConfig {
    param($serviceName)
    $sanFile = "$serviceName-san.cnf"
    $altNames = ""
    $index = 1

    foreach ($dns in $dnsNames) {
        $altNames += "DNS.$index = $dns`n"
        $index++
    }
    foreach ($ip in $ipAddresses) {
        $altNames += "IP.$index = $ip`n"
        $index++
    }

    @"
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
$altNames
"@ | Set-Content $sanFile

    return $sanFile
}

# ================== ������Ϊ��������֤�� ==================
function Generate-CertForService {
    param($serviceName)

    Write-Host "����֤��: $serviceName"

    $keyFile = "$serviceName.key"
    $csrFile = "$serviceName.csr"
    $crtFile = "$serviceName.crt"
    $p12File = "$serviceName.p12"
    $sanFile = Create-SANConfig -serviceName $serviceName

    & $openssl req -newkey rsa:2048 -nodes `
        -keyout $keyFile `
        -out $csrFile `
        -subj "/CN=$serviceName/O=$O/OU=$OU/C=$C" `
        -config $sanFile

    & $openssl x509 -req -in $csrFile `
        -CA $caCert -CAkey $caKey -CAcreateserial `
        -out $crtFile `
        -days $validDays `
        -extensions v3_req -extfile $sanFile

    & $openssl pkcs12 -export `
        -in $crtFile `
        -inkey $keyFile `
        -certfile $caCert `
        -out $p12File `
        -name "$serviceName" `
        -passout pass:$keystorePassword

    return (Resolve-Path $crtFile).Path
}

# ================== ���������� Truststore ==================
function Create-Truststore {
    param($certFiles)

    if (Test-Path $truststoreFile) {
        Remove-Item $truststoreFile -Force
    }

    # �� root CA ���� truststore
    & keytool -importcert `
        -alias root-ca `
        -file $caCert `
        -keystore $truststoreFile `
        -storepass $truststorePassword `
        -storetype PKCS12 `
        -noprompt

    # ����ÿ������֤�飨��ѡ��
    $index = 1
    foreach ($cert in $certFiles) {
        $alias = "service-$index"
        & keytool -importcert `
            -alias $alias `
            -file $cert `
            -keystore $truststoreFile `
            -storepass $truststorePassword `
            -storetype PKCS12 `
            -noprompt
        $index++
    }
}

# ================== ��ִ������ ==================
New-RootCA

$certs = @()
foreach ($svc in $services) {
    $cert = Generate-CertForService -serviceName $svc
    if (Test-Path $cert) {
        $certs += $cert
    } else {
        Write-Host "����: δ�ҵ����� [$svc] ��֤��: $cert"
    }
}

Create-Truststore -certFiles $certs

Write-Host "? ����֤���� truststore �����ɣ�λ��Ŀ¼: $workDir"
