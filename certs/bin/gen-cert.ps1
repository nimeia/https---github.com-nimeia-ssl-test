# ================================
# 参数配置
# ================================
$Services = @("eureka-server", "gateway-service", "user-service", "product-service", "order-service")
$Domain = "demoapi.io"
$TruststorePassword = "changeit"
$KeystorePassword = "changeit"
$DaysValid = 3650
$OutputDir = "../src/main/resources/certs"

# ================================
# 初始化目录
# ================================
if (-Not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
Set-Location $OutputDir

# ================================
# 生成 CA 根证书
# ================================
Write-Host "? 生成 CA..."
openssl genrsa -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days $DaysValid -out ca.crt -subj "/CN=$Domain CA/O=$Domain/C=CN"
Write-Host "? CA 证书已生成"

# ================================
# 为每个服务生成私钥、证书
# ================================
foreach ($service in $Services) {
    $Fqdn = "$service"+"."+"$Domain"
    Write-Host "? 正在生成证书: $Fqdn"

    openssl genrsa -out "$service.key" 2048
    openssl req -new -key "$service.key" -out "$service.csr" -subj "/CN=$Fqdn/O=$Domain/C=CN"
    openssl x509 -req -in "$service.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "$service.crt" -days $DaysValid -sha256
    Remove-Item "$service.csr"
}

# ================================
# 为每个服务生成 keystore（含私钥）
# ================================
foreach ($service in $Services) {
    Write-Host "? 生成 keystore: $service-keystore.p12"
    openssl pkcs12 -export `
        -in "$service.crt" `
        -inkey "$service.key" `
        -certfile ca.crt `
        -out "$service-keystore.p12" `
        -name $service `
        -password pass:$KeystorePassword
}

# ================================
# 为每个服务生成 truststore（包含其它服务证书）
# ================================
foreach ($service in $Services) {
    Write-Host "? 为 $service 生成 truststore"
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

Write-Host "? 所有服务证书、keystore、truststore 已生成。"
