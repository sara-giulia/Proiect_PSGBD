package com.telemedicina.telemedicina;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;
import java.util.Map;

@Controller
public class RapoarteController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/doctor/rapoarte")
    public String rapoarte(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("doctor")) {
            return "redirect:/login";
        }

        model.addAttribute("userName", session.getAttribute("userName"));

        List<Map<String, Object>> statistici = jdbcTemplate.queryForList(
                "SELECT * FROM get_raport_statistic()");
        model.addAttribute("statistici", statistici);

        List<Map<String, Object>> alerte = jdbcTemplate.queryForList(
                "SELECT * FROM get_abonamente_expira_curand()");
        model.addAttribute("alerte", alerte);

        return "rapoarte";
    }
}