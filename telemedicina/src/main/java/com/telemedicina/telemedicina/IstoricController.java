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
public class IstoricController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/istoric")
    public String istoric(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("pacient")) {
            return "redirect:/login";
        }

        int patientId = (int) session.getAttribute("userId");
        model.addAttribute("userName", session.getAttribute("userName"));

        List<Map<String, Object>> istoric = jdbcTemplate.queryForList(
                "SELECT form_id, " +
                        "TO_CHAR(form_date, 'DD.MM.YYYY HH24:MI') AS form_date, " +
                        "symptom1, symptom2, symptom3, " +
                        "provisional_diagnosis, complexity_level, form_status, " +
                        "TO_CHAR(consultation_date, 'DD.MM.YYYY HH24:MI') AS consultation_date, " +
                        "doctor_name, confirmed_diagnosis, medications, recommendations " +
                        "FROM get_istoric_pacient(?)", patientId
        );
        model.addAttribute("istoric", istoric);

        List<Map<String, Object>> conditiiCronice = jdbcTemplate.queryForList(
                "SELECT name, diagnosed_date FROM CHRONIC_CONDITION " +
                        "WHERE patient_id = ? ORDER BY diagnosed_date DESC", patientId);
        model.addAttribute("conditiiCronice", conditiiCronice);

        List<Map<String, Object>> abonamente = jdbcTemplate.queryForList(
                "SELECT type, start_date, end_date, cost, status FROM SUBSCRIPTION " +
                        "WHERE patient_id = ? ORDER BY start_date DESC", patientId);
        model.addAttribute("abonamente", abonamente);

        return "istoric";
    }
}