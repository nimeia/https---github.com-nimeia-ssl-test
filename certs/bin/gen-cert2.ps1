# ================== 配置区域 ==================
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

# 创建工作目录
$workDir = "../src/main/resources/certs"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Set-Location $workDir

# ================== 函数：创建根 CA ==================
function New-RootCA {
    if (!(Test-Path $caCert)) {
        Write-Host "? 生成 Root CA..."
        & $openssl req -x509 -newkey rsa:4096 -nodes `
            -keyout $caKey `
            -out $caCert `
            -days $validDays `
            -subj "/CN=$caName"
    } else {
        Write-Host "? Root CA 已存在，跳过生成。"
    }
}

# ================== 函数：生成 SAN 配置文件 ==================
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

# ================== 函数：为服务生成证书链和 keystore ==================
function Generate-CertForService {
    param($serviceName)

    Write-Host "? 生成证书: $serviceName"

    $keyFile = "$serviceName.key"
    $csrFile = "$serviceName.csr"
    $crtFile = "$serviceName.crt"
    $chainFile = "$serviceName.chain.crt"
    $p12File = "$serviceName.p12"
    $sanFile = Create-SANConfig -serviceName $serviceName

    # 生成 CSR + 私钥（注意 -reqexts v3_req）
    & $openssl req -newkey rsa:2048 -nodes `
        -keyout $keyFile `
        -out $csrFile `
        -subj "/CN=$serviceName" `
        -config $sanFile `
        -reqexts v3_req

    # 使用 CA 签发证书
    & $openssl x509 -req -in $csrFile `
        -CA $caCert -CAkey $caKey -CAcreateserial `
        -out $crtFile `
        -days $validDays `
        -extensions v3_req -extfile $sanFile

    # 生成 chain.crt（包含根 CA）
    Set-Content $chainFile -Value (
        (Get-Content $crtFile -Raw) + "`n" + (Get-Content $caCert -Raw)
    )

    # 创建包含证书链的 .p12 keystore
    & $openssl pkcs12 -export `
        -in $crtFile `
        -inkey $keyFile `
        -certfile $caCert `
        -out $p12File `
        -name "$serviceName" `
        -passout pass:$keystorePassword

    return (Resolve-Path $chainFile).Path
}

# ================== 函数：构建统一 truststore ==================
function Create-Truststore {
    param($chainFiles)

    if (Test-Path $truststoreFile) {
        Remove-Item $truststoreFile -Force
    }

    # 导入 Root CA
    & $keytool -importcert `
        -alias root-ca `
        -file $caCert `
        -keystore $truststoreFile `
        -storepass $truststorePassword `
        -storetype PKCS12 `
        -noprompt

    # 导入每个服务证书链
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

    Write-Host "? Truststore 构建完成: $truststoreFile"
}

# ================== 主流程 ==================
New-RootCA

$chainFiles = @()
foreach ($svc in $services) {
    $chain = Generate-CertForService -serviceName $svc
    if (Test-Path $chain) {
        $chainFiles += $chain
    } else {
        Write-Host "?? 未生成证书链: $svc"
    }
}

Create-Truststore -chainFiles $chainFiles

Write-Host "`n? 全部证书生成完毕！"
Write-Host "? 输出目录: $(Resolve-Path .)"
