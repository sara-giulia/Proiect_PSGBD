package com.telemedicina.telemedicina;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/pacient")
public class PacientDashboardController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/dashboard")
    public String dashboard(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("pacient")) {
            return "redirect:/login";
        }

        int patientId =(int) session.getAttribute("userId");
        String userName =(String) session.getAttribute("userName");

        model.addAttribute("userName", userName);

        Map<String, Object> abonament = null;
        try {
            abonament = jdbcTemplate.queryForMap(
                    "SELECT type, end_date, status, " +
                            "(end_date - CURRENT_DATE) AS zile_ramase " +
                            "FROM SUBSCRIPTION WHERE patient_id = ? AND status = 'activ' " +
                            "ORDER BY end_date DESC LIMIT 1", patientId);
        } catch (Exception e) {
        }
        model.addAttribute("abonament", abonament);

        List<Map<String, Object>> fiseRecente = jdbcTemplate.queryForList(
                "SELECT mf.id, TO_CHAR(mf.created_at, 'DD.MM.YYYY HH24:MI') AS created_at, mf.status, mf.provisional_diagnosis, " +
                        "mf.complexity_level, TO_CHAR(c.scheduled_at, 'DD.MM.YYYY HH24:MI') AS scheduled_at, " +
                        "d.last_name || ' ' || d.first_name AS doctor_name " +
                        "FROM MEDICAL_FORM mf " +
                        "LEFT JOIN CONSULTATION c ON c.form_id = mf.id " +
                        "LEFT JOIN DOCTOR d ON d.id = c.doctor_id " +
                        "WHERE mf.patient_id = ? " +
                        "ORDER BY mf.created_at DESC LIMIT 5", patientId);
        model.addAttribute("fiseRecente", fiseRecente);

        List<Map<String, Object>> scorRisc = jdbcTemplate.queryForList(
                "SELECT * FROM calculeaza_scor_risc(?)", patientId
        );
        if (!scorRisc.isEmpty()) {
            model.addAttribute("scorRisc", scorRisc.get(0));
        }

        return "pacient-dashboard";
    }
}