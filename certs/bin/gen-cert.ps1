$ErrorActionPreference = "Stop"

# ========= ? ȫ������ =========
$domain = ""           # �����׺����
$outputDir = "../src/main/resources/certs"                  # ֤�����Ŀ¼
$trustStorePass = "changeit"
$validityDays = 3650
$services = @("eureka-server", "user-service", "product-service", "order-service", "gateway-service")

# ========= ? ���� & �������Ŀ¼ =========
if (Test-Path $outputDir) {
    Remove-Item -Recurse -Force "$outputDir/*"
} else {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# ========= ? Step 1: ����˽�� CA =========
$caKey = Join-Path $outputDir "ca.key"
$caCert = Join-Path $outputDir "ca.crt"

Write-Output "? Step 1: ����˽�� CA"

openssl genrsa -out $caKey 4096
openssl req -x509 -new -nodes -key $caKey -sha256 -days $validityDays -out $caCert -subj "/CN=MyRootCA/O=MyCompany/C=US"

# ========= ? Step 2: ���ɷ��� keystore =========
foreach ($service in $services) {
    $fullCN = "$service$domain"
    $alias = $service

    $key     = Join-Path $outputDir "$service.key"
    $csr     = Join-Path $outputDir "$service.csr"
    $crt     = Join-Path $outputDir "$service.crt"
    $p12     = Join-Path $outputDir "$service-keystore.p12"
    $keystorePass = "changeit"

    Write-Output "? ���ڴ������: $service"

    # ����˽Կ�� CSR
    openssl genrsa -out $key 2048
    openssl req -new -key $key -out $csr -subj "/CN=$fullCN/O=MyCompany/C=US"

    # ʹ�� CA ǩ��
    openssl x509 -req -in $csr -CA $caCert -CAkey $caKey -CAcreateserial -out $crt -days $validityDays -sha256

    # ���Ϊ keystore
    openssl pkcs12 -export -in $crt -inkey $key -certfile $caCert -out $p12 -name $alias -passout pass:$keystorePass
}

# ========= ? Step 3: ����ͳһ truststore =========
$trustStore = Join-Path $outputDir "truststore.p12"
Write-Output "? Step 3: ����ͳһ truststore"

foreach ($service in $services) {
    $crt = Join-Path $outputDir "$service.crt"
    $alias = $service

    keytool -import -trustcacerts -alias $alias -file $crt `
        -keystore $trustStore -storepass $trustStorePass -storetype PKCS12 -noprompt
}

# ========= ? ��� =========
Write-Output ""
Write-Output "? ����֤���ѳɹ����ɲ������: '$outputDir'"
Write-Output " - ÿ������: <service>-keystore.p12"
Write-Output " - ͳһ Truststore: truststore.p12"
Write-Output " - CA ֤��: ca.crt"
