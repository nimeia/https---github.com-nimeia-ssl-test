package com.example.product.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
import java.util.HashMap;

@RestController
public class ProductController {
    @GetMapping("/product/{id}")
    public Map<String, Object> getProduct(@PathVariable("id") String id) {
        Map<String, Object> product = new HashMap<>();
        product.put("id", id);
        product.put("name", "测试商品");
        product.put("price", 99.99);
        product.put("description", "这是一个模拟商品，ID为 " + id);
        return product;
    }
}
