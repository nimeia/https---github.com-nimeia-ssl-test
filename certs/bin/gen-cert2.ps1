# ================== �������� ==================
$caName = "MyCompany Root CA"
$caKey = "rootCA.key"
$caCert = "rootCA.crt"
$truststoreFile = "truststore.p12"
$truststorePassword = "changeit"

$services = @("order-service", "gateway-service", "user-service", "product-service")
$dnsNames = @("localhost", "mydomain.com", "*.mydomain.com")
$ipAddresses = @("127.0.0.1", "172.16.3.163")

$keystorePassword = "changeit"
$validDays = 3650
$openssl = "openssl"
$keytool = "keytool"

# ��������Ŀ¼
$workDir = "../src/main/resources/certs"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Set-Location $workDir

# ================== ������������ CA ==================
function New-RootCA {
    if (!(Test-Path $caCert)) {
        Write-Host "? ���� Root CA..."
        & $openssl req -x509 -newkey rsa:4096 -nodes `
            -keyout $caKey `
            -out $caCert `
            -days $validDays `
            -subj "/CN=$caName"
    } else {
        Write-Host "? Root CA �Ѵ��ڣ��������ɡ�"
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

# ================== ������Ϊ��������֤������ keystore ==================
function Generate-CertForService {
    param($serviceName)

    Write-Host "? ����֤��: $serviceName"

    $keyFile = "$serviceName.key"
    $csrFile = "$serviceName.csr"
    $crtFile = "$serviceName.crt"
    $chainFile = "$serviceName.chain.crt"
    $p12File = "$serviceName.p12"
    $sanFile = Create-SANConfig -serviceName $serviceName

    # ���� CSR + ˽Կ��ע�� -reqexts v3_req��
    & $openssl req -newkey rsa:2048 -nodes `
        -keyout $keyFile `
        -out $csrFile `
        -subj "/CN=$serviceName" `
        -config $sanFile `
        -reqexts v3_req

    # ʹ�� CA ǩ��֤��
    & $openssl x509 -req -in $csrFile `
        -CA $caCert -CAkey $caKey -CAcreateserial `
        -out $crtFile `
        -days $validDays `
        -extensions v3_req -extfile $sanFile

    # ���� chain.crt�������� CA��
    Set-Content $chainFile -Value (
        (Get-Content $crtFile -Raw) + "`n" + (Get-Content $caCert -Raw)
    )

    # ��������֤������ .p12 keystore
    & $openssl pkcs12 -export `
        -in $crtFile `
        -inkey $keyFile `
        -certfile $caCert `
        -out $p12File `
        -name "$serviceName" `
        -passout pass:$keystorePassword

    return (Resolve-Path $chainFile).Path
}

# ================== ����������ͳһ truststore ==================
function Create-Truststore {
    param($chainFiles)

    if (Test-Path $truststoreFile) {
        Remove-Item $truststoreFile -Force
    }

    # ���� Root CA
    & $keytool -importcert `
        -alias root-ca `
        -file $caCert `
        -keystore $truststoreFile `
        -storepass $truststorePassword `
        -storetype PKCS12 `
        -noprompt

    # ����ÿ������֤����
    # $index = 1
    # foreach ($chain in $chainFiles) {
    #     $alias = "svc-$index"
    #     & $keytool -importcert `
    #         -alias $alias `
    #         -file $chain `
    #         -keystore $truststoreFile `
    #         -storepass $truststorePassword `
    #         -storetype PKCS12 `
    #         -noprompt
    #     $index++
    # }

    Write-Host "? Truststore �������: $truststoreFile"
}

# ================== ������ ==================
New-RootCA

$chainFiles = @()
foreach ($svc in $services) {
    $chain = Generate-CertForService -serviceName $svc
    if (Test-Path $chain) {
        $chainFiles += $chain
    } else {
        Write-Host "?? δ����֤����: $svc"
    }
}

Create-Truststore -chainFiles $chainFiles

Write-Host "`n? ȫ��֤��������ϣ�"
Write-Host "? ���Ŀ¼: $(Resolve-Path .)"
