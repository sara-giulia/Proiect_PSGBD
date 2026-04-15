package com.telemedicina.telemedicina;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class DashboardController {
    @GetMapping("/")
    public String dashboard(HttpSession session) {
        if (session.getAttribute("userRole") == null) {
            return "redirect:/login";
        }
        if (session.getAttribute("userRole").equals("doctor")) {
            return "redirect:/doctor/dashboard";
        }
        return "redirect:/pacient/dashboard";
    }
}
