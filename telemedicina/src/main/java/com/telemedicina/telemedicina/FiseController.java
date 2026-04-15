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
public class FiseController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/fise")
    public String listaFise(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null) {
            return "redirect:/login";
        }
        List<Map<String, Object>> fise = jdbcTemplate.queryForList(
                "SELECT mf.id, mf.created_at, mf.status, mf.provisional_diagnosis, " +
                        "mf.complexity_level, p.first_name, p.last_name, " +
                        "c.scheduled_at, c.confirmed_diagnosis, " +
                        "d.first_name AS doctor_first, d.last_name AS doctor_last " +
                        "FROM MEDICAL_FORM mf " +
                        "JOIN PATIENT p ON p.id = mf.patient_id " +
                        "LEFT JOIN CONSULTATION c ON c.form_id = mf.id " +
                        "LEFT JOIN DOCTOR d ON d.id = c.doctor_id " +
                        "ORDER BY mf.created_at DESC"
        );
        model.addAttribute("fise", fise);
        return "fise";
    }
}