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
public class PatientController {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/pacienti")
    public String listaPacienti(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null) {
            return "redirect:/login";
        }
        List<Map<String, Object>> patients = jdbcTemplate.queryForList("SELECT p.id, p.first_name, p.last_name, p.birth_date, p.email, p.phone_number," +
            "DATE_PART('year', AGE(CURRENT_DATE, p.birth_date)) AS varsta, CASE WHEN p.tutor_id IS NOT NULL THEN 'Minor' ELSE 'Adult' END AS tip, " +
                        "COALESCE(s.status, 'fara abonament') AS abonament FROM PATIENT p LEFT JOIN SUBSCRIPTION s ON s.patient_id = p.id AND " +
                        "s.end_date = (SELECT MAX(end_date) FROM SUBSCRIPTION WHERE patient_id = p.id) ORDER BY p.last_name, p.first_name");
        model.addAttribute("pacienti", patients);
        return "pacienti";
    }
}
