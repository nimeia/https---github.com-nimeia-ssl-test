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

    // 模拟：根据用户ID返回订单列表
    @GetMapping("/order/user/{userId}")
    public java.util.List<Map<String, Object>> getOrdersByUserId(@PathVariable("userId") String userId) {
        Map<String, Object> order1 = new HashMap<>();
        order1.put("orderId", "1001");
        order1.put("userId", userId);
        order1.put("product", "商品A");
        order1.put("amount", 2);
        order1.put("price", 99.99);
        order1.put("status", "已支付");

        Map<String, Object> order2 = new HashMap<>();
        order2.put("orderId", "1002");
        order2.put("userId", userId);
        order2.put("product", "商品B");
        order2.put("amount", 1);
        order2.put("price", 49.99);
        order2.put("status", "待发货");

        java.util.List<Map<String, Object>> orders = new java.util.ArrayList<>();
        orders.add(order1);
        orders.add(order2);
        return orders;
    }
}
