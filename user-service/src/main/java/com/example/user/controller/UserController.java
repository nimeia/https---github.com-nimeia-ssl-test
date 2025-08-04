package com.example.user.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;
import com.example.user.feign.OrderFeignClient;
import java.util.Map;
import java.util.HashMap;

@RestController
public class UserController {
    @Autowired
    private OrderFeignClient orderFeignClient;
    @GetMapping("/user/{id}")
    public Map<String, Object> getUser(@PathVariable("id") String id) {
        Map<String, Object> user = new HashMap<>();
        user.put("id", id);
        user.put("name", "测试用户");
        user.put("email", "user" + id + "@example.com");
        user.put("age", 25);
        return user;
    }

    @GetMapping("/user/order/{id}")
    public Map<String, Object> getUserOrder(@PathVariable("id") String id) {
        Map<String, Object> user = new HashMap<>();
        user.put("id", id);
        user.put("name", "测试用户");
        user.put("email", "user" + id + "@example.com");
        user.put("age", 25);

        // 使用 FeignClient 调用订单服务
        java.util.List<Map<String, Object>> orders = orderFeignClient.getOrdersByUserId(id);

        Map<String, Object> result = new HashMap<>();
        result.put("user", user);
        result.put("orders", orders);
        return result;
    }
}
