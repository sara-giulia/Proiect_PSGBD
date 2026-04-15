CREATE OR REPLACE FUNCTION genereaza_reteta_automata(p_form_id INT)
RETURNS TABLE(medications TEXT, recommendations TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_diagnosis TEXT;
    v_complexity INT;
    v_consultation_id INT;
    v_medications TEXT;
    v_recommendations TEXT;
BEGIN
    SELECT provisional_diagnosis, complexity_level
    INTO v_diagnosis, v_complexity
    FROM MEDICAL_FORM WHERE id = p_form_id;

    IF v_complexity != 1 THEN
        RAISE EXCEPTION 'COMPLEXITATE_INVALIDA: Reteta automata doar pentru complexitate 1.'
            USING ERRCODE = 'P0007';
    END IF;

    v_medications := CASE
        WHEN v_diagnosis ILIKE '%viroза%' OR v_diagnosis ILIKE '%gripa%'
            THEN 'Paracetamol 500mg la 6 ore + Vitamina C 1000mg/zi + Zinc 10mg/zi'
        WHEN v_diagnosis ILIKE '%alergic%' OR v_diagnosis ILIKE '%dermatologic%'
            THEN 'Loratadina 10mg 1x/zi + crema hidratanta'
        WHEN v_diagnosis ILIKE '%digestiv%' OR v_diagnosis ILIKE '%toxiinfectie%'
            THEN 'Smecta 3x/zi + Hidrasec + hidratare abundenta'
        ELSE
            'Paracetamol 500mg la nevoie + repaus'
    END;

    v_recommendations := CASE
        WHEN v_diagnosis ILIKE '%viroза%' OR v_diagnosis ILIKE '%gripa%'
            THEN 'Repaus la pat 3-5 zile, lichide calde, evitati efortul fizic. Reveniti daca febra depaseste 39 grade sau simptomele persista peste 7 zile.'
        WHEN v_diagnosis ILIKE '%alergic%' OR v_diagnosis ILIKE '%dermatologic%'
            THEN 'Evitati factorii alergeni cunoscuti. Reveniti daca apar dificultati de respiratie sau umflarea fetei.'
        WHEN v_diagnosis ILIKE '%digestiv%' OR v_diagnosis ILIKE '%toxiinfectie%'
            THEN 'Dieta blanda 3 zile (orez, paine prajita, banana). Hidratare abundenta. Reveniti daca simptomele persista peste 48h.'
        ELSE
            'Repaus, hidratare, monitorizati simptomele. Reveniti daca starea se agraveaza.'
    END;

    SELECT id INTO v_consultation_id FROM CONSULTATION WHERE form_id = p_form_id;

    IF v_consultation_id IS NULL THEN
        INSERT INTO CONSULTATION (form_id, doctor_id, scheduled_at, duration_minutes, status, confirmed_diagnosis)
        SELECT p_form_id, id, NOW(), 10, 'finalizata', v_diagnosis
        FROM DOCTOR ORDER BY id LIMIT 1
        RETURNING id INTO v_consultation_id;
    END IF;

    INSERT INTO PRESCRIPTION (consultation_id, issued_at, medications, recommendations)
    VALUES (v_consultation_id, NOW(), v_medications, v_recommendations)
    ON CONFLICT (consultation_id) DO NOTHING;

    UPDATE MEDICAL_FORM SET status = 'inchis' WHERE id = p_form_id;

    RETURN QUERY SELECT v_medications, v_recommendations;
END;
$$;

CREATE OR REPLACE FUNCTION get_abonamente_expira_curand()
RETURNS TABLE(
    patient_id INT,
    patient_name TEXT,
    email VARCHAR(100),
    phone_number VARCHAR(15),
    subscription_type VARCHAR(10),
    end_date DATE,
    zile_ramase INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.last_name || ' ' || p.first_name,
        p.email,
        p.phone_number,
        s.type,
        s.end_date,
        (s.end_date - CURRENT_DATE)::INT
    FROM PATIENT p
    JOIN SUBSCRIPTION s ON s.patient_id = p.id
    WHERE s.status = 'activ'
        AND s.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7
    ORDER BY s.end_date;
END;
$$;

CREATE OR REPLACE FUNCTION get_istoric_pacient(p_patient_id INT)
RETURNS TABLE(
    form_id INT,
    form_date TIMESTAMP,
    symptom1 TEXT,
    symptom2 TEXT,
    symptom3 TEXT,
    provisional_diagnosis TEXT,
    complexity_level INT,
    form_status VARCHAR(20),
    consultation_date TIMESTAMP,
    doctor_name TEXT,
    confirmed_diagnosis TEXT,
    medications TEXT,
    recommendations TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PATIENT WHERE id = p_patient_id) THEN
        RAISE EXCEPTION 'PACIENT_INEXISTENT: Nu exista pacient cu id %.', p_patient_id
            USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT
        mf.id AS form_id,
        mf.created_at,
        MAX(CASE WHEN s.type = 'primar' AND s.id = (
            SELECT MIN(s2.id) FROM SYMPTOM s2 WHERE s2.form_id = mf.id AND s2.type = 'primar'
        ) THEN s.description END),
        MAX(CASE WHEN s.type = 'primar' AND s.id = (
            SELECT MIN(s2.id) FROM SYMPTOM s2 WHERE s2.form_id = mf.id AND s2.type = 'primar' AND s2.id > (
                SELECT MIN(s3.id) FROM SYMPTOM s3 WHERE s3.form_id = mf.id AND s3.type = 'primar'
            )
        ) THEN s.description END),
        MAX(CASE WHEN s.type = 'primar' AND s.id = (
            SELECT MAX(s2.id) FROM SYMPTOM s2 WHERE s2.form_id = mf.id AND s2.type = 'primar'
        ) THEN s.description END),
        mf.provisional_diagnosis,
        mf.complexity_level,
        mf.status,
        c.scheduled_at,
        d.last_name || ' ' || d.first_name,
        c.confirmed_diagnosis,
        pr.medications,
        pr.recommendations
    FROM MEDICAL_FORM mf
    LEFT JOIN SYMPTOM s ON s.form_id = mf.id
    LEFT JOIN CONSULTATION c ON c.form_id = mf.id
    LEFT JOIN DOCTOR d ON d.id = c.doctor_id
    LEFT JOIN PRESCRIPTION pr ON pr.consultation_id = c.id
    WHERE mf.patient_id = p_patient_id
    GROUP BY mf.id, mf.created_at, mf.provisional_diagnosis,
             mf.complexity_level, mf.status, c.scheduled_at,
             d.last_name, d.first_name, c.confirmed_diagnosis,
             pr.medications, pr.recommendations
    ORDER BY mf.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION get_raport_statistic()
RETURNS TABLE(
    sectiune TEXT,
    nume TEXT,
    valoare TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 'Consultatii per doctor'::TEXT, sub.nume, sub.valoare
    FROM (
        SELECT
            d.last_name || ' ' || d.first_name || ' (' || d.specialization || ')' AS nume,
            COUNT(c.id)::TEXT || ' consultatii (' ||
            ROUND(100.0 * COUNT(CASE WHEN c.status = 'finalizata' THEN 1 END) / NULLIF(COUNT(c.id), 0), 1)::TEXT || '% finalizate)' AS valoare
        FROM DOCTOR d
        LEFT JOIN CONSULTATION c ON c.doctor_id = d.id
        GROUP BY d.id, d.last_name, d.first_name, d.specialization
        ORDER BY COUNT(c.id) DESC
    ) sub

    UNION ALL

    SELECT 'Diagnostic frecvent'::TEXT, sub.nume, sub.valoare
    FROM (
        SELECT
            mf.provisional_diagnosis AS nume,
            COUNT(*)::TEXT || ' cazuri' AS valoare
        FROM MEDICAL_FORM mf
        WHERE mf.provisional_diagnosis IS NOT NULL
        GROUP BY mf.provisional_diagnosis
        ORDER BY COUNT(*) DESC
        LIMIT 5
    ) sub

    UNION ALL

    SELECT 'Pacient cu cele mai multe fise'::TEXT, sub.nume, sub.valoare
    FROM (
        SELECT
            p.last_name || ' ' || p.first_name AS nume,
            COUNT(mf.id)::TEXT || ' fise' AS valoare
        FROM PATIENT p
        JOIN MEDICAL_FORM mf ON mf.patient_id = p.id
        GROUP BY p.id, p.last_name, p.first_name
        ORDER BY COUNT(mf.id) DESC
        LIMIT 3
    ) sub

    UNION ALL

    SELECT
        'Timp mediu pana la programare'::TEXT,
        'Toate cazurile'::TEXT,
        ROUND(AVG(EXTRACT(EPOCH FROM (c.scheduled_at - mf.created_at)) / 3600), 1)::TEXT || ' ore'
    FROM MEDICAL_FORM mf
    JOIN CONSULTATION c ON c.form_id = mf.id

    UNION ALL

    SELECT
        'Abonamente active'::TEXT,
        'Total'::TEXT,
        COUNT(*)::TEXT || ' abonamente'
    FROM SUBSCRIPTION
    WHERE status = 'activ'

    UNION ALL

    SELECT 'Complexitate cazuri'::TEXT, sub.nume, sub.valoare
    FROM (
        SELECT
            'Nivel ' || complexity_level::TEXT AS nume,
            COUNT(*)::TEXT || ' fise (' ||
            ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM MEDICAL_FORM), 0), 1)::TEXT || '%)' AS valoare
        FROM MEDICAL_FORM
        GROUP BY complexity_level
        ORDER BY complexity_level
    ) sub;
END;
$$;

CREATE OR REPLACE FUNCTION detecteaza_simptome_similare(
    p_patient_id INT,
    p_symptom1 TEXT,
    p_symptom2 TEXT,
    p_symptom3 TEXT
)
RETURNS TABLE(
    form_id_anterior INT,
    data_anterioara TIMESTAMP,
    diagnostic_anterior TEXT,
    simptom_comun TEXT,
    avertisment TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        mf.id,
        mf.created_at,
        mf.provisional_diagnosis,
        s.description,
        CASE
            WHEN mf.complexity_level = 3
                THEN 'ATENTIE: Simptom similar cu un caz de urgenta din istoricul dumneavoastra!'
            WHEN mf.complexity_level = 2
                THEN 'Simptom similar cu un caz mediu din istoricul dumneavoastra.'
            ELSE
                'Simptom similar cu un caz anterior.'
        END
    FROM MEDICAL_FORM mf
    JOIN SYMPTOM s ON s.form_id = mf.id
    WHERE mf.patient_id = p_patient_id
        AND mf.created_at < NOW() - INTERVAL '1 day'
        AND (
            LOWER(s.description) ILIKE '%' || LOWER(p_symptom1) || '%' OR
            LOWER(s.description) ILIKE '%' || LOWER(p_symptom2) || '%' OR
            LOWER(s.description) ILIKE '%' || LOWER(p_symptom3) || '%'
        )
    ORDER BY mf.created_at DESC
    LIMIT 5;
END;
$$;

CREATE OR REPLACE FUNCTION get_raport_zilnic_doctor(p_doctor_id INT)
RETURNS TABLE(
    consultation_id INT,
    scheduled_at TEXT,
    duration_minutes INT,
    patient_name TEXT,
    patient_age INT,
    chronic_conditions TEXT,
    symptoms TEXT,
    provisional_diagnosis TEXT,
    complexity_level INT,
    status VARCHAR(20)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM DOCTOR WHERE id = p_doctor_id) THEN
        RAISE EXCEPTION 'DOCTOR_INEXISTENT: Nu exista doctor cu id %.', p_doctor_id
            USING ERRCODE = 'P0008';
    END IF;

    RETURN QUERY
    SELECT
        c.id,
        TO_CHAR(c.scheduled_at, 'DD.MM.YYYY HH24:MI'),
        c.duration_minutes,
        p.last_name || ' ' || p.first_name,
        DATE_PART('year', AGE(CURRENT_DATE, p.birth_date))::INT,
        COALESCE(STRING_AGG(DISTINCT cc.name, ', '), 'Niciuna'),
        COALESCE(STRING_AGG(DISTINCT s.description, ', '), '-'),
        mf.provisional_diagnosis,
        mf.complexity_level,
        c.status
    FROM CONSULTATION c
    JOIN MEDICAL_FORM mf ON mf.id = c.form_id
    JOIN PATIENT p ON p.id = mf.patient_id
    LEFT JOIN CHRONIC_CONDITION cc ON cc.patient_id = p.id
    LEFT JOIN SYMPTOM s ON s.form_id = mf.id AND s.type = 'primar'
    WHERE c.doctor_id = p_doctor_id
        AND c.scheduled_at::DATE = CURRENT_DATE
        AND c.status = 'programata'
    GROUP BY c.id, c.scheduled_at, c.duration_minutes,
             p.last_name, p.first_name, p.birth_date,
             mf.provisional_diagnosis, mf.complexity_level, c.status
    ORDER BY c.scheduled_at;
END;
$$;

CREATE OR REPLACE FUNCTION calculeaza_scor_risc(p_patient_id INT)
RETURNS TABLE(
    scor INT,
    nivel_risc TEXT,
    factori TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_scor INT := 0;
    v_varsta INT;
    v_nr_cronice INT;
    v_nr_urgente INT;
    v_nr_fise INT;
    v_factori TEXT := '';
BEGIN
    SELECT DATE_PART('year', AGE(CURRENT_DATE, birth_date))::INT
    INTO v_varsta FROM PATIENT WHERE id = p_patient_id;

    SELECT COUNT(*) INTO v_nr_cronice
    FROM CHRONIC_CONDITION WHERE patient_id = p_patient_id;

    SELECT COUNT(*) INTO v_nr_urgente
    FROM MEDICAL_FORM
    WHERE patient_id = p_patient_id AND complexity_level = 3;

    SELECT COUNT(*) INTO v_nr_fise
    FROM MEDICAL_FORM WHERE patient_id = p_patient_id;

    IF v_varsta > 65 THEN
        v_scor := v_scor + 30;
        v_factori := v_factori || 'Varsta peste 65 ani (+30). ';
    ELSIF v_varsta > 50 THEN
        v_scor := v_scor + 15;
        v_factori := v_factori || 'Varsta peste 50 ani (+15). ';
    ELSIF v_varsta < 5 THEN
        v_scor := v_scor + 20;
        v_factori := v_factori || 'Varsta sub 5 ani (+20). ';
    END IF;

    v_scor := v_scor + (v_nr_cronice * 15);
    IF v_nr_cronice > 0 THEN
        v_factori := v_factori || v_nr_cronice::TEXT || ' afectiuni cronice (+' || (v_nr_cronice * 15)::TEXT || '). ';
    END IF;

    v_scor := v_scor + (v_nr_urgente * 20);
    IF v_nr_urgente > 0 THEN
        v_factori := v_factori || v_nr_urgente::TEXT || ' cazuri urgente in istoric (+' || (v_nr_urgente * 20)::TEXT || '). ';
    END IF;

    IF v_nr_fise > 5 THEN
        v_scor := v_scor + 10;
        v_factori := v_factori || 'Istoric medical bogat (+10). ';
    END IF;

    RETURN QUERY SELECT
        v_scor,
        CASE
            WHEN v_scor >= 70 THEN 'RISC RIDICAT'
            WHEN v_scor >= 40 THEN 'RISC MEDIU'
            ELSE 'RISC SCAZUT'
        END,
        COALESCE(NULLIF(v_factori, ''), 'Niciun factor de risc identificat.');
END;
$$;