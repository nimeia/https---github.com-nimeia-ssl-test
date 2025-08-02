# ================================
# ��������
# ================================
$Services = @("eureka-server", "gateway-service", "user-service", "product-service", "order-service")
$Domain = "demoapi.io"
$TruststorePassword = "changeit"
$KeystorePassword = "changeit"
$DaysValid = 3650
$OutputDir = "../src/main/resources/certs"

# ================================
# ��ʼ��Ŀ¼
# ================================
if (-Not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
Set-Location $OutputDir

# ================================
# ���� CA ��֤��
# ================================
Write-Host "? ���� CA..."
openssl genrsa -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days $DaysValid -out ca.crt -subj "/CN=$Domain CA/O=$Domain/C=CN"
Write-Host "? CA ֤��������"

# ================================
# Ϊÿ����������˽Կ��֤��
# ================================
foreach ($service in $Services) {
    $Fqdn = "$service"+"."+"$Domain"
    Write-Host "? ��������֤��: $Fqdn"

    openssl genrsa -out "$service.key" 2048
    openssl req -new -key "$service.key" -out "$service.csr" -subj "/CN=$Fqdn/O=$Domain/C=CN"
    openssl x509 -req -in "$service.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "$service.crt" -days $DaysValid -sha256
    Remove-Item "$service.csr"
}

# ================================
# Ϊÿ���������� keystore����˽Կ��
# ================================
foreach ($service in $Services) {
    Write-Host "? ���� keystore: $service-keystore.p12"
    openssl pkcs12 -export `
        -in "$service.crt" `
        -inkey "$service.key" `
        -certfile ca.crt `
        -out "$service-keystore.p12" `
        -name $service `
        -password pass:$KeystorePassword
}

# ================================
# Ϊÿ���������� truststore��������������֤�飩
# ================================
foreach ($service in $Services) {
    Write-Host "? Ϊ $service ���� truststore"
    $truststoreFile = "$service-truststore.p12"
    if (Test-Path $truststoreFile) {
        Remove-Item $truststoreFile
    }

    foreach ($other in $Services) {
        if ($other -ne $service) {
            keytool -importcert -noprompt `
                -alias $other `
                -file "$other.crt" `
                -keystore $truststoreFile `
                -storetype PKCS12 `
                -storepass $TruststorePassword
        }
    }
}

Write-Host "? ���з���֤�顢keystore��truststore �����ɡ�"
