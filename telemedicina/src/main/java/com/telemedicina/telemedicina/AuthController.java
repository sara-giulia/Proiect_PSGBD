package com.telemedicina.telemedicina;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

@Controller
public class AuthController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @PostMapping("/login")
    public String login(@RequestParam String email, @RequestParam String password, @RequestParam String role,
            HttpSession session, RedirectAttributes redirectAttributes) {

        try {
            if (role.equals("pacient")) {
                Map<String, Object> patient = jdbcTemplate.queryForMap(
                        "SELECT id, first_name, last_name, email FROM PATIENT " +
                                "WHERE email = ? AND password = ?", email, password);
                session.setAttribute("userId", patient.get("id"));
                session.setAttribute("userName", patient.get("first_name") + " " + patient.get("last_name"));
                session.setAttribute("userEmail", patient.get("email"));
                session.setAttribute("userRole", "pacient");
                return "redirect:/pacient/dashboard";

            } else {
                Map<String, Object> doctor = jdbcTemplate.queryForMap(
                        "SELECT id, first_name, last_name, email FROM DOCTOR " +
                                "WHERE email = ? AND password = ?", email, password);
                session.setAttribute("userId", doctor.get("id"));
                session.setAttribute("userName", doctor.get("first_name") + " " + doctor.get("last_name"));
                session.setAttribute("userEmail", doctor.get("email"));
                session.setAttribute("userRole", "doctor");
                return "redirect:/doctor/dashboard";
            }

        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Email sau parolă incorecte.");
            return "redirect:/login";
        }
    }

    @GetMapping("/logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/login";
    }
}