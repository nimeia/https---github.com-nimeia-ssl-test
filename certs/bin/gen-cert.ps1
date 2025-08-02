# -------------------------------
# 参数设置
# -------------------------------
$CAName = "my-root-ca"
$Password = "changeit"
$CAKey = "$CAName.key"
$CACert = "$CAName.crt"
$CADays = 3650
$Services = @("eureka-server", "gateway", "user-service", "product-service", "order-service")
$CertsDir = "certs"
New-Item -ItemType Directory -Force -Path $CertsDir | Out-Null

# -------------------------------
# 1. 创建自签名 CA（只创建一次）
# -------------------------------
if (-not (Test-Path "$CertsDir/$CAKey")) {
    Write-Host "? 生成自签名 CA: $CAName"
    openssl req -x509 -newkey rsa:2048 -days $CADays -nodes `
        -keyout "$CertsDir/$CAKey" -out "$CertsDir/$CACert" `
        -subj "/CN=MyCustomCA/O=DemoCA"
}

# -------------------------------
# 2. 为每个服务生成证书、keystore、truststore
# -------------------------------
foreach ($service in $Services) {
    Write-Host "? 正在处理服务: $service"
    $key = $service+".key"
    $csr = $service+".csr"
    $crt = $service+".crt"
    $p12 = $service+"-keystore.p12"
    $trust = $service+"-truststore.p12"
    $alias = $service
    $fqdn = $service+".demoapi.io"

    # Step 1: 创建私钥
    openssl genrsa -out "$CertsDir/$key" 2048

    # Step 2: 创建 CSR
    openssl req -new -key "$CertsDir/$key" -out "$CertsDir/$csr" -subj "/CN=$fqdn/O=DemoService"

    # Step 3: 使用 CA 签发证书
    openssl x509 -req -in "$CertsDir/$csr" -CA "$CertsDir/$CACert" -CAkey "$Cert
