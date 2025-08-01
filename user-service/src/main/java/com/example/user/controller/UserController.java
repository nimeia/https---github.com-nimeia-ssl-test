package com.example.user.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
import java.util.HashMap;

@RestController
public class UserController {
    @GetMapping("/user/{id}")
    public Map<String, Object> getUser(@PathVariable("id") String id) {
        Map<String, Object> user = new HashMap<>();
        user.put("id", id);
        user.put("name", "测试用户");
        user.put("email", "user" + id + "@example.com");
        user.put("age", 25);
        return user;
    }
}
