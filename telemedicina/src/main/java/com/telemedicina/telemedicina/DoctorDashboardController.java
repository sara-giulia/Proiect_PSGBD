package com.telemedicina.telemedicina;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/doctor")
public class DoctorDashboardController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/dashboard")
    public String dashboard(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("doctor")) {
            return "redirect:/login";
        }

        int doctorId = (int) session.getAttribute("userId");
        String userName = (String) session.getAttribute("userName");
        model.addAttribute("userName", userName);

        List<Map<String, Object>> consultatiiAzi = jdbcTemplate.queryForList(
                "SELECT * FROM get_raport_zilnic_doctor(?)", doctorId);
        model.addAttribute("consultatiiAzi", consultatiiAzi);

        List<Map<String, Object>> consultatiiViitoare = jdbcTemplate.queryForList(
                "SELECT c.id, " +
                        "TO_CHAR(c.scheduled_at, 'DD.MM.YYYY HH24:MI') AS scheduled_at, " +
                        "c.duration_minutes, c.status, " +
                        "p.last_name || ' ' || p.first_name AS patient_name, " +
                        "mf.provisional_diagnosis, mf.complexity_level " +
                        "FROM CONSULTATION c " +
                        "JOIN MEDICAL_FORM mf ON mf.id = c.form_id " +
                        "JOIN PATIENT p ON p.id = mf.patient_id " +
                        "WHERE c.doctor_id = ? AND c.scheduled_at::DATE > CURRENT_DATE " +
                        "AND c.status = 'programata' " +
                        "ORDER BY c.scheduled_at LIMIT 10", doctorId);
        model.addAttribute("consultatiiViitoare", consultatiiViitoare);

        return "doctor-dashboard";
    }

    @PostMapping("/finalizeaza")
    public String finalizeaza(@RequestParam int consultationId, @RequestParam String confirmedDiagnosis,
            @RequestParam String medications, @RequestParam String recommendations,
            @RequestParam(required = false) String referralType, @RequestParam(required = false) String referralDetails,
            HttpSession session, RedirectAttributes redirectAttrs) {

        if (session.getAttribute("userRole") == null ||
                !session.getAttribute("userRole").equals("doctor")) {
            return "redirect:/login";
        }

        try {
            jdbcTemplate.update(
                    "UPDATE CONSULTATION SET status = 'finalizata', " +
                            "confirmed_diagnosis = ?, notes = ?, " +
                            "referral_type = ?, referral_details = ? WHERE id = ?",
                    confirmedDiagnosis, recommendations,
                    referralType, referralDetails, consultationId);

            jdbcTemplate.update(
                    "INSERT INTO PRESCRIPTION (consultation_id, issued_at, medications, recommendations) " +
                            "VALUES (?, NOW(), ?, ?) ON CONFLICT (consultation_id) DO UPDATE " +
                            "SET medications = EXCLUDED.medications, recommendations = EXCLUDED.recommendations",
                    consultationId, medications, recommendations);

            redirectAttrs.addFlashAttribute("success", "Consultatia a fost finalizata si reteta emisa.");
        } catch (Exception e) {
            redirectAttrs.addFlashAttribute("error", "Eroare la finalizare: " + e.getMessage());
        }
        return "redirect:/doctor/dashboard";
    }
}