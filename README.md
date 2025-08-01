# Spring Cloud 多微服务项目

本项目采用 Maven 管理，包含以下微服务：
- 用户服务（user-service）
- 订单服务（order-service）
- 商品服务（product-service）
- 服务注册中心（eureka-server，基于 Spring Cloud Eureka）
- 网关服务（gateway-service，基于 Spring Cloud Gateway）

## 快速开始
1. 使用 Maven 构建各微服务模块。
2. 启动 Eureka Server。
3. 启动各微服务。
4. 启动网关服务，通过网关访问各微服务。

## 目录结构
```
user-service/
order-service/
product-service/
eureka-server/
gateway-service/
.github/
README.md
```

## 依赖
- Java 8+
- Maven 3.6+
- Spring Boot 2.5+
- Spring Cloud 2020+

详细配置和代码请参考各服务目录。
