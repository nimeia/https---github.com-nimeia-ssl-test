# 合并所有 p12 文件和 CA 证书为一个 truststore.p12
TRUSTSTORE=truststore.p12
PASSWORD=changeit
rm -f $TRUSTSTORE

# 导入 CA 证书
openssl pkcs12 -export -in ca.crt -nokeys -out ca-ca.p12 -name demoapi-ca -password pass:$PASSWORD
keytool -importkeystore -srckeystore ca-ca.p12 -srcstoretype PKCS12 -srcstorepass $PASSWORD \
  -destkeystore $TRUSTSTORE -deststoretype PKCS12 -deststorepass $PASSWORD -alias demoapi-ca
rm ca-ca.p12

# 导入所有服务证书
for service in user-service order-service product-service eureka-server gateway-service; do
  openssl pkcs12 -export -in ${service}.crt -nokeys -out ${service}-cert.p12 -name ${service} -password pass:$PASSWORD
  keytool -importkeystore -srckeystore ${service}-cert.p12 -srcstoretype PKCS12 -srcstorepass $PASSWORD \
    -destkeystore $TRUSTSTORE -deststoretype PKCS12 -deststorepass $PASSWORD -alias ${service}
  rm ${service}-cert.p12
  echo "已合并 ${service}.crt 到 truststore.p12"
done

echo "truststore.p12 已生成，包含所有服务证书和 CA 证书"