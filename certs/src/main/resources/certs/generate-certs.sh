#!/bin/bash
# 生成 CA 及所有微服务证书
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=demoapi.io CA/O=demoapi.io/C=CN"
export MSYS_NO_PATHCONV=1
for service in user-service order-service product-service eureka-server gateway-service; do
  openssl genrsa -out ${service}.key 2048
  openssl req -new -key ${service}.key -out ${service}.csr -subj "/CN=${service}.demoapi.io/O=demoapi.io/C=CN"
  openssl x509 -req -in ${service}.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${service}.crt -days 3650 -sha256
  rm ${service}.csr
  echo "${service} 证书已生成"
done



# 生成所有服务的 p12 文件，并将 CA 证书也导入
for service in user-service order-service product-service eureka-server gateway-service; do
  openssl pkcs12 -export \
    -in ${service}.crt \
    -inkey ${service}.key \
    -out ${service}.p12 \
    -name ${service} \
    -CAfile ca.crt \
    -caname root \
    -chain \
    -password pass:changeit
  echo "${service}.p12 已生成，包含 CA 证书"
done
