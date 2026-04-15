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

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/pacient")
public class ConsultatieController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/consultatie")
    public String formNoua(HttpSession session, Model model) {
        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("pacient")) {
            return "redirect:/login";
        }
        model.addAttribute("userName", session.getAttribute("userName"));
        return "consultatie-noua";
    }

    @PostMapping("/consultatie/proceseaza")
    public String proceseaza(@RequestParam String symptom1, @RequestParam String symptom2,
            @RequestParam String symptom3, HttpSession session, RedirectAttributes redirectAttributes) {

        if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("pacient")) {
            return "redirect:/login";
        }

        int patientId = (int) session.getAttribute("userId");

        try {
            Map<String, Object> result = jdbcTemplate.queryForMap(
                    "SELECT * FROM genereaza_fisa_wrapper(?, ?, ?, ?)",
                    patientId, symptom1, symptom2, symptom3);

            try {
                List<Map<String, Object>> simptomeSimilare = jdbcTemplate.queryForList(
                        "SELECT * FROM detecteaza_simptome_similare(?, ?, ?, ?)",
                        patientId, symptom1, symptom2, symptom3
                );
                if (!simptomeSimilare.isEmpty()) {
                    redirectAttributes.addFlashAttribute("simptomeSimilare", simptomeSimilare);
                }
            } catch (Exception ignored) {}

            int formId = ((Number) result.get("p_form_id")).intValue();
            String diagnosis = (String) result.get("p_diagnosis");
            int complexity = ((Number) result.get("p_complexity")).intValue();
            String extra = (String) result.get("p_extra_questions");

            redirectAttributes.addFlashAttribute("formId", formId);
            redirectAttributes.addFlashAttribute("diagnosis", diagnosis);
            redirectAttributes.addFlashAttribute("complexity", complexity);
            redirectAttributes.addFlashAttribute("extraQuestions", extra);
            redirectAttributes.addFlashAttribute("step", 2);

        } catch (Exception exception) {
            String message = exception.getMessage();
            if (message != null && message.contains("ABONAMENT_INACTIV")) {
                redirectAttributes.addFlashAttribute("error",
                        "Nu ai un abonament activ. Te rugam sa iti reinnoiesti abonamentul.");
            } else if (message != null && message.contains("PACIENT_INEXISTENT")) {
                redirectAttributes.addFlashAttribute("error",
                        "Contul tau nu a fost gasit in sistem.");
            } else if (message != null && message.contains("SIMPTOME_INSUFICIENTE")) {
                redirectAttributes.addFlashAttribute("error",
                        "Introduceți cele 3 simptome obligatorii.");
            } else {
                redirectAttributes.addFlashAttribute("error",
                        "Eroare neasteptata: " + message);
            }
        }
        return "redirect:/pacient/consultatie";
    }

    @PostMapping("/consultatie/raspunsuri")
    public String salveazaRaspunsuri(@RequestParam int formId, @RequestParam int complexity,
            @RequestParam String diagnosis, @RequestParam Map<String, String> allParams,
            HttpSession session, RedirectAttributes redirectAttrs) {

        if (session.getAttribute("userRole") == null ||
                !session.getAttribute("userRole").equals("pacient")) {
            return "redirect:/login";
        }

        try {
            for (Map.Entry<String, String> entry : allParams.entrySet()) {
                if (entry.getKey().startsWith("intrebare_")) {
                    String question = entry.getKey().replace("intrebare_", "").replace("_", " ");
                    String answer = entry.getValue();
                    if (!answer.isBlank()) {
                        jdbcTemplate.update(
                                "INSERT INTO FORM_ANSWER (form_id, question, answer) VALUES (?, ?, ?)", formId, question, answer);
                    }
                }
            }

            if (complexity == 1) {
                Map<String, Object> reteta = jdbcTemplate.queryForMap(
                        "SELECT * FROM genereaza_reteta_automata(?)", formId);
                redirectAttrs.addFlashAttribute("reteta", reteta);
                redirectAttrs.addFlashAttribute("retetaAutomata", true);
                redirectAttrs.addFlashAttribute("diagnosis", diagnosis);
            } else {
                Map<String, Object> result = jdbcTemplate.queryForMap(
                        "SELECT * FROM schedule_wrapper(?, ?)", formId, complexity);

                int doctorId = ((Number) result.get("p_doctor_id")).intValue();

                Map<String, Object> doctor = jdbcTemplate.queryForMap(
                        "SELECT first_name, last_name, specialization FROM DOCTOR WHERE id = ?", doctorId);

                redirectAttrs.addFlashAttribute("doctorNume",
                        "Dr. " + doctor.get("last_name") + " " + doctor.get("first_name") +
                                " (" + doctor.get("specialization") + ")");
                redirectAttrs.addFlashAttribute("scheduledAt",
                        new java.sql.Timestamp(
                                ((java.sql.Timestamp) result.get("p_scheduled_at")).getTime()
                        ).toLocalDateTime().format(
                                java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm")));
                redirectAttrs.addFlashAttribute("programat", true);
            }

        } catch (Exception e) {
            redirectAttrs.addFlashAttribute("error", "Eroare: " + e.getMessage());
        }
        return "redirect:/pacient/consultatie";
    }
}