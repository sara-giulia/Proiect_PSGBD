CREATE OR REPLACE FUNCTION genereaza_fisa_wrapper(
    p_patient_id INT, p_s1 TEXT, p_s2 TEXT, p_s3 TEXT
) RETURNS TABLE(p_form_id INT, p_diagnosis TEXT, p_complexity INT, p_extra_questions TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_form_id INT; v_diagnosis TEXT; v_complexity INT; v_extra TEXT;
BEGIN
    CALL genereaza_fisa_medicala(p_patient_id, p_s1, p_s2, p_s3,
        v_form_id, v_diagnosis, v_complexity, v_extra);
    RETURN QUERY SELECT v_form_id, v_diagnosis, v_complexity, v_extra;
END;
$$;

CREATE OR REPLACE FUNCTION schedule_wrapper(p_form_id INT, p_complexity INT)
RETURNS TABLE(p_consultation_id INT, p_doctor_id INT, p_scheduled_at TIMESTAMP)
LANGUAGE plpgsql AS $$
DECLARE
    v_cons_id INT;
    v_doctor_id INT;
    v_scheduled TIMESTAMP;
BEGIN
    CALL scheduleaza_consultatie(p_form_id, p_complexity,
        v_cons_id, v_doctor_id, v_scheduled);
    RETURN QUERY SELECT v_cons_id, v_doctor_id, v_scheduled;
END;
$$;