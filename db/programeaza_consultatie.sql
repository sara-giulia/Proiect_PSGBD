CREATE OR REPLACE PROCEDURE schedule_consultatie(
    p_form_id INT,
    p_complexity INT,
    OUT p_consultation_id INT,
    OUT p_doctor_id INT,
    OUT p_scheduled_at TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_duration INT;
    v_current_day DATE;
    v_slot_start TIMESTAMP;
    v_slot_end TIMESTAMP;
    v_doc RECORD;
    v_day_start TIMESTAMP;
    v_day_end TIMESTAMP;
    v_occupied RECORD;
    v_found BOOLEAN := FALSE;
    v_max_days INT := 14;
    v_day_counter INT := 0;
    v_form_exists INT;
    v_already_scheduled INT;
BEGIN
    SELECT COUNT(*) INTO v_form_exists
    FROM MEDICAL_FORM WHERE id = p_form_id;

    IF v_form_exists = 0 THEN
        RAISE EXCEPTION 'FISA_INEXISTENTA: Nu exista fisa cu id %.', p_form_id
            USING ERRCODE = 'P0004';
    END IF;

    SELECT COUNT(*) INTO v_already_scheduled
    FROM CONSULTATION WHERE form_id = p_form_id;

    IF v_already_scheduled > 0 THEN
        RAISE EXCEPTION 'CONSULTATIE_EXISTENTA: Fisa % are deja o consultatie programata.', p_form_id
            USING ERRCODE = 'P0005';
    END IF;

    v_duration := CASE p_complexity
        WHEN 1 THEN 10
        WHEN 2 THEN 20
        WHEN 3 THEN 30
        ELSE 20
    END;

    v_current_day := CURRENT_DATE;

    WHILE v_day_counter < v_max_days AND NOT v_found LOOP
        FOR v_doc IN
            SELECT id, schedule_start, schedule_end
            FROM DOCTOR
            ORDER BY id
        LOOP
            v_day_start := v_current_day + v_doc.schedule_start;
            v_day_end   := v_current_day + v_doc.schedule_end;

            IF v_day_start < NOW() THEN
                v_day_start := DATE_TRUNC('minute', NOW()) + INTERVAL '1 minute';
            END IF;

            v_slot_start := v_day_start;

            FOR v_occupied IN
                SELECT scheduled_at,
                       scheduled_at + (duration_minutes || ' minutes')::INTERVAL AS ends_at
                FROM CONSULTATION
                WHERE doctor_id = v_doc.id
                  AND scheduled_at::DATE = v_current_day
                  AND status != 'anulata'
                  AND waiting_list = FALSE
                ORDER BY scheduled_at
            LOOP
                v_slot_end := v_slot_start + (v_duration || ' minutes')::INTERVAL;

                IF v_slot_end <= v_occupied.scheduled_at
                   AND v_slot_end <= v_day_end THEN
                    v_found    := TRUE;
                    p_doctor_id := v_doc.id;
                    p_scheduled_at := v_slot_start;
                    EXIT;
                END IF;

                IF v_slot_start < v_occupied.ends_at THEN
                    v_slot_start := v_occupied.ends_at;
                END IF;
            END LOOP;

            IF NOT v_found THEN
                v_slot_end := v_slot_start + (v_duration || ' minutes')::INTERVAL;
                IF v_slot_end <= v_day_end THEN
                    v_found        := TRUE;
                    p_doctor_id    := v_doc.id;
                    p_scheduled_at := v_slot_start;
                END IF;
            END IF;

            EXIT WHEN v_found;
        END LOOP;

        v_current_day   := v_current_day + 1;
        v_day_counter   := v_day_counter + 1;
    END LOOP;

    IF NOT v_found THEN
        INSERT INTO CONSULTATION (
            form_id, doctor_id, scheduled_at,
            duration_minutes, status, waiting_list
        )
        SELECT p_form_id, id, NULL, v_duration, 'programata', TRUE
        FROM DOCTOR ORDER BY id LIMIT 1
        RETURNING id, doctor_id, scheduled_at
        INTO p_consultation_id, p_doctor_id, p_scheduled_at;

        RAISE NOTICE 'Pacient adaugat in lista de asteptare pentru fisa %', p_form_id;
        RETURN;
    END IF;

    INSERT INTO CONSULTATION (
        form_id, doctor_id, scheduled_at,
        duration_minutes, status, waiting_list
    )
    VALUES (
        p_form_id, p_doctor_id, p_scheduled_at,
        v_duration, 'programata', FALSE
    )
    RETURNING id INTO p_consultation_id;

    RAISE NOTICE 'Consultatie programata: id=%, doctor_id=%, la=%',
        p_consultation_id, p_doctor_id, p_scheduled_at;
END;
$$;