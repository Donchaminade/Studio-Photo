package com.studiophoto.photoappbackend.admin;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/admin/monitoring")
public class AdminMonitoringController {

    @GetMapping
    public String monitoring() {
        return "admin/monitoring";
    }
}
