package com.example.user.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.List;
import java.util.Map;

@FeignClient(name = "order-service")
public interface OrderFeignClient {
    @GetMapping("/order/user/{userId}" )
    List<Map<String, Object>> getOrdersByUserId(@PathVariable("userId") String userId);
}
