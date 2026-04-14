package com.telemedicina.telemedicina;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

@Controller
public class ConsultatieController {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/consultatie/noua")
    public String formNoua (Model model){
        List<Map<String, Object>> patients = jdbcTemplate.queryForList(
                "SELECT id, first_name, last_name FROM PATIENT ORDER BY last_name");
        model.addAttribute("pacienti", patients);
        return "consultatie-noua";
    }

    @PostMapping("/consultatie/proceseaza")
    public String proceseaza(@RequestParam int patientId, @RequestParam String symptom1, @RequestParam String symptom2,
        @RequestParam String symptom3, RedirectAttributes redirectAttributes) {
        try {
            Map<String, Object> result = jdbcTemplate.queryForMap(
                    "SELECT * FROM genereaza_fisa_wrapper(?, ?, ?, ?)",
                    patientId, symptom1, symptom2, symptom3);

            int formId = ((Number) result.get("p_form_id")).intValue();
            String diagnosis = (String) result.get("p_diagnosis");
            int complexity = ((Number) result.get("p_complexity")).intValue();
            String extra = (String) result.get("p_extra_questions");

            redirectAttributes.addFlashAttribute("formId", formId);
            redirectAttributes.addFlashAttribute("diagnosis", diagnosis);
            redirectAttributes.addFlashAttribute("complexity", complexity);
            redirectAttributes.addFlashAttribute("extraQuestions", extra);
            redirectAttributes.addFlashAttribute("success", true);

        } catch (Exception exception){
            String message = exception.getMessage();
            if(message != null && message.contains("ABONAMENT_INACTIV")){
                redirectAttributes.addFlashAttribute("error",
                        "Pacientul nu are un abonament activ. Va rugăm să reînnoiti abonamentul.");
            } else if (message!= null && message.contains("PACIENT_INEXISTENT")) {
                redirectAttributes.addFlashAttribute("error", "Pacientul selectat nu există în sistem.");
            } else if (message != null && message.contains("SIMPTOME_INSUFICIENTE")) {
                redirectAttributes.addFlashAttribute("error", "Introduceți cele 3 simptome obligatorii.");
            } else {
                redirectAttributes.addFlashAttribute("error", "Eroare neașteptată: " + message);
            }
        }
        return "redirect:/consultatie/noua";
    }

    @PostMapping("/consultatie/programeaza")
    public String programeaza(@RequestParam int formId, @RequestParam int complexity, RedirectAttributes redirectAttributes) {
        try {
            Map<String, Object> result = jdbcTemplate.queryForMap("SELECT * FROM schedule_wrapper(?, ?)", formId, complexity);

            redirectAttributes.addFlashAttribute("consultationId", result.get("p_consultation_id"));
            redirectAttributes.addFlashAttribute("doctorId", result.get("p_doctor_id"));
            redirectAttributes.addFlashAttribute("scheduledAt", result.get("p_scheduled_at"));
            redirectAttributes.addFlashAttribute("programat", true);

        } catch (Exception exception) {
            String message = exception.getMessage();
            if (message != null && message.contains("CONSULTATIE_EXISTENTA")) {
                redirectAttributes.addFlashAttribute("error", "Această fișă are deja o consultație programată.");
            } else if (message != null && message.contains("NICIO_DISPONIBILITATE")) {
                redirectAttributes.addFlashAttribute("error", "Nu există niciun slot disponibil în următoarele 14 zile.");
            } else {
                redirectAttributes.addFlashAttribute("error", "Eroare la programare: " + message);
            }
            redirectAttributes.addFlashAttribute("formId", formId);
            redirectAttributes.addFlashAttribute("complexity", complexity);
        }
        return "redirect:/consultatie/noua";
    }
}




