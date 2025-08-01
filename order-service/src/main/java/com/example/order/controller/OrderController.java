package com.example.order.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
import java.util.HashMap;

@RestController
public class OrderController {
    @GetMapping("/order/{id}")
    public Map<String, Object> getOrder(@PathVariable("id") String id) {
        Map<String, Object> order = new HashMap<>();
        order.put("id", id);
        order.put("product", "测试商品");
        order.put("amount", 2);
        order.put("price", 199.98);
        order.put("status", "已支付");
        return order;
    }
}
