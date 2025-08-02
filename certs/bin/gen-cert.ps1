# -------------------------------
# ��������
# -------------------------------
$CAName = "my-root-ca"
$Password = "changeit"
$CAKey = "$CAName.key"
$CACert = "$CAName.crt"
$CADays = 3650
$Services = @("eureka-server", "gateway", "user-service", "product-service", "order-service")
$CertsDir = "../src/main/resources/certs"
New-Item -ItemType Directory -Force -Path $CertsDir | Out-Null

# -------------------------------
# 1. ������ǩ�� CA��ֻ����һ�Σ�
# -------------------------------
if (-not (Test-Path "$CertsDir/$CAKey")) {
    Write-Host "? ������ǩ�� CA: $CAName"
    openssl req -x509 -newkey rsa:2048 -days $CADays -nodes `
        -keyout "$CertsDir/$CAKey" -out "$CertsDir/$CACert" `
        -subj "/CN=MyCustomCA/O=DemoCA"
}

# -------------------------------
# 2. Ϊÿ����������֤�顢keystore��truststore
# -------------------------------
foreach ($service in $Services) {
    Write-Host "? ���ڴ������: $service"
    $key = $service+".key"
    $csr = $service+".csr"
    $crt = $service+".crt"
    $p12 = $service+"-keystore.p12"
    $trust = $service+"-truststore.p12"
    $alias = $service
    $fqdn = $service+".demoapi.io"

    # Step 1: ����˽Կ
    openssl genrsa -out "$CertsDir/$key" 2048

    # Step 2: ���� CSR
    openssl req -new -key "$CertsDir/$key" -out "$CertsDir/$csr" -subj "/CN=$fqdn/O=DemoService"

    # Step 3: ʹ�� CA ǩ��֤��
    openssl x509 -req -in "$CertsDir/$csr" -CA "$CertsDir/$CACert" -CAkey "$CertsDir/$CAKey" `
        -CAcreateserial -out "$CertsDir/$crt" -days 825 -sha256

    # Step 4: ���� keystore (��������֤�� + ˽Կ)
    openssl pkcs12 -export `
        -in "$CertsDir/$crt" `
        -inkey "$CertsDir/$key" `
        -certfile "$CertsDir/$CACert" `
        -out "$CertsDir/$p12" `
        -name "$alias" `
        -passout pass:$Password

    # Step 5: ���� truststore�������� CA ֤�飩
    keytool -importcert `
        -alias "$CAName" `
        -keystore "$CertsDir/$trust" `
        -storepass $Password `
        -storetype PKCS12 `
        -file "$CertsDir/$CACert" `
        -noprompt
}

Write-Host "`n? ���з���� keystore/truststore ������ϣ������� $CertsDir �ļ�����"
