$ErrorActionPreference = "Stop"

# ========= ? 全局配置 =========
$domain = ""           # 服务后缀域名
$outputDir = "../src/main/resources/certs"                  # 证书输出目录
$trustStorePass = "changeit"
$validityDays = 3650
$services = @("eureka-server", "user-service", "product-service", "order-service", "gateway-service")

# ========= ? 清理 & 创建输出目录 =========
if (Test-Path $outputDir) {
    Remove-Item -Recurse -Force "$outputDir/*"
} else {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# ========= ? Step 1: 创建私有 CA =========
$caKey = Join-Path $outputDir "ca.key"
$caCert = Join-Path $outputDir "ca.crt"

Write-Output "? Step 1: 生成私有 CA"

openssl genrsa -out $caKey 4096
openssl req -x509 -new -nodes -key $caKey -sha256 -days $validityDays -out $caCert -subj "/CN=MyRootCA/O=MyCompany/C=US"

# ========= ? Step 2: 生成服务 keystore =========
foreach ($service in $services) {
    $fullCN = "$service$domain"
    $alias = $service

    $key     = Join-Path $outputDir "$service.key"
    $csr     = Join-Path $outputDir "$service.csr"
    $crt     = Join-Path $outputDir "$service.crt"
    $p12     = Join-Path $outputDir "$service-keystore.p12"
    $keystorePass = "changeit"

    Write-Output "? 正在处理服务: $service"

    # 生成私钥和 CSR
    openssl genrsa -out $key 2048
    openssl req -new -key $key -out $csr -subj "/CN=$fullCN/O=MyCompany/C=US"

    # 使用 CA 签名
    openssl x509 -req -in $csr -CA $caCert -CAkey $caKey -CAcreateserial -out $crt -days $validityDays -sha256

    # 打包为 keystore
    openssl pkcs12 -export -in $crt -inkey $key -certfile $caCert -out $p12 -name $alias -passout pass:$keystorePass
}

# ========= ? Step 3: 构建统一 truststore =========
$trustStore = Join-Path $outputDir "truststore.p12"
Write-Output "? Step 3: 创建统一 truststore"

foreach ($service in $services) {
    $crt = Join-Path $outputDir "$service.crt"
    $alias = $service

    keytool -import -trustcacerts -alias $alias -file $crt `
        -keystore $trustStore -storepass $trustStorePass -storetype PKCS12 -noprompt
}

# ========= ? 完成 =========
Write-Output ""
Write-Output "? 所有证书已成功生成并输出到: '$outputDir'"
Write-Output " - 每个服务: <service>-keystore.p12"
Write-Output " - 统一 Truststore: truststore.p12"
Write-Output " - CA 证书: ca.crt"
