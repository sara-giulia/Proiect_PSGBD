DO $$
DECLARE
    lista_nume TEXT[] := ARRAY[
        'Popescu','Ionescu','Constantin','Gheorghe','Popa','Lazar','Stan',
        'Stoica','Dumitru','Ion','Matei','Dinu','Rusu','Moldovan','Nistor',
        'Mihai','Florea','Lungu','Marin','Tudor','Radu','Diaconu','Oprea',
        'Chiriac','Manolache','Ciobanu','Badea','Serban','Mocanu','Vlad'
    ];
    lista_prenume_fete TEXT[] := ARRAY[
        'Ana','Maria','Ioana','Elena','Andreea','Alexandra','Cristina',
        'Mihaela','Raluca','Diana','Iulia','Laura','Simona','Bianca',
        'Gabriela','Teodora','Alina','Daniela','Monica','Oana'
    ];
    lista_prenume_baieti TEXT[] := ARRAY[
        'Ion','Mihai','Andrei','Alexandru','Cristian','Bogdan','Stefan',
        'Radu','Vlad','Dan','Catalin','Florin','Adrian','Lucian','Marius',
        'Cosmin','Tudor','Gabriel','Razvan','Paul'
    ];
    lista_specializations TEXT[] := ARRAY[
        'Medicina generala','Pediatrie','Cardiologie',
        'Neurologie','Dermatologie','Gastroenterologie'
    ];
    lista_simptome_primare TEXT[] := ARRAY[
        'febra','durere de cap','tuse','durere abdominala','varsaturi',
        'oboseala','durere in gat','ameteala','durere in piept','greata',
        'dificultati de respiratie','dureri musculare','frisoane','diaree',
        'pierderea poftei de mancare','dureri articulare','nas infundat',
        'durere de urechi','eruptie cutanata','palpitati'
    ];
    lista_simptome_secundare TEXT[] := ARRAY[
        'durere la inghitit','sensibilitate la lumina','durere la miscare',
        'balonare','arsuri stomacale','insomnie','transpiratii nocturne',
        'pierdere in greutate','umflarea picioarelor','vedere incetosata'
    ];
    lista_conditii_cronice TEXT[] := ARRAY[
        'Diabet tip 2','Hipertensiune arteriala','Astm bronsic',
        'Hipotiroidism','Boala de reflux gastroesofagian','Epilepsie',
        'Artrita reumatoida','Depresie','Anxietate','Colesterol marit'
    ];
    lista_medicamente TEXT[] := ARRAY[
        'Paracetamol 500mg, 3x/zi, 5 zile',
        'Ibuprofen 400mg, 2x/zi, 3 zile + Vitamina C 1000mg/zi',
        'Amoxicilina 500mg, 3x/zi, 7 zile + Probiotice',
        'Nurofen 200mg la nevoie + repaus la pat',
        'Antiacide dupa mese + dieta blanda 3 zile',
        'Claritromicina 500mg, 2x/zi, 5 zile',
        'Metoclopramid 10mg, 3x/zi + hidratare abundenta',
        'Antihistaminice + crema cu cortizon local'
    ];
    lista_recomandari TEXT[] := ARRAY[
        'Repaus la pat, hidratare abundenta, reveniti daca simptomele persista peste 5 zile.',
        'Evitati efortul fizic, consumati lichide calde, monitorizati temperatura.',
        'Dieta blanda, evitati alimentele grase si picante, reveniti la control dupa 7 zile.',
        'Aer proaspat, exercitii usoare de respiratie, evitati fumul si praful.',
        'Monitorizati tensiunea zilnic, reduceti consumul de sare, reveniti la 2 saptamani.'
    ];
 
    v_nume TEXT;
    v_prenume TEXT;
    v_email TEXT;
    v_email_check INT;
    v_patient_id INT;
    v_doctor_id INT;
    v_sub_id INT;
    v_form_id INT;
    v_cons_id INT;
    v_tutor_id INT;
    v_birth_date DATE;
    v_start_date DATE;
    v_end_date DATE;
    v_scheduled_at TIMESTAMP;
    v_complexity INT;
    v_duration INT;
    v_type TEXT;
    v_diagnosis TEXT;
    v_symptom1 TEXT;
    v_symptom2 TEXT;
    v_symptom3 TEXT;
    v_counter INT;
 
BEGIN 
    INSERT INTO DOCTOR (first_name, last_name, specialization, schedule_start, schedule_end) VALUES
        ('Andrei', 'Popescu', 'Medicina generala', '08:00', '13:00'),
        ('Maria', 'Ionescu', 'Pediatrie', '11:00', '17:00'),
        ('Cristian', 'Gheorghe', 'Cardiologie', '14:00', '19:00'),
        ('Elena', 'Constantin', 'Neurologie', '08:00', '14:00'),
        ('Bogdan', 'Rusu', 'Dermatologie', '10:00', '16:00'),
        ('Ioana', 'Matei', 'Gastroenterologie', '13:00', '19:00');

    v_counter := 0;
    FOR v_i IN 1..20 LOOP
 
        v_nume := lista_nume[FLOOR(RANDOM() * array_length(lista_nume, 1)) + 1];
 
        IF v_i % 2 = 0 THEN
            v_prenume := lista_prenume_fete[FLOOR(RANDOM() * array_length(lista_prenume_fete, 1)) + 1];
        ELSE
            v_prenume := lista_prenume_baieti[FLOOR(RANDOM() * array_length(lista_prenume_baieti, 1)) + 1];
        END IF;
 
        v_email := LOWER(v_prenume || '.' || v_nume);
        LOOP
            SELECT COUNT(*) INTO v_email_check FROM PATIENT WHERE email = v_email || '@gmail.com';
            EXIT WHEN v_email_check = 0;
            v_email := v_email || FLOOR(RANDOM() * 99 + 1)::TEXT;
        END LOOP;
        v_email := v_email || '@gmail.com';
 
        v_birth_date := CURRENT_DATE - (FLOOR(RANDOM() * 365 * 35) + 365 * 25)::INT;
 
        INSERT INTO PATIENT (first_name, last_name, birth_date, phone_number, email, address)
        VALUES (v_prenume, v_nume, v_birth_date, '07' || FLOOR(RANDOM() * 90000000 + 10000000)::TEXT, v_email,
            'Str. ' || lista_nume[FLOOR(RANDOM() * array_length(lista_nume, 1)) + 1] || ' nr. ' || FLOOR(RANDOM() * 50 + 1)::TEXT);
 
        v_counter := v_counter + 1;
    END LOOP;
 
    FOR v_i IN 1..5 LOOP
        SELECT id INTO v_tutor_id FROM PATIENT ORDER BY id LIMIT 1 OFFSET (v_i % 3);
 
        v_prenume := lista_prenume_baieti[FLOOR(RANDOM() * array_length(lista_prenume_baieti, 1)) + 1];
        SELECT last_name INTO v_nume FROM PATIENT WHERE id = v_tutor_id;
 
        v_email := LOWER(v_prenume || '.junior.' || v_nume || v_i::TEXT || '@gmail.com');
 
        v_birth_date := CURRENT_DATE - (FLOOR(RANDOM() * 365 * 14) + 365 * 3)::INT;
 
        INSERT INTO PATIENT (first_name, last_name, birth_date, phone_number, email, address, tutor_id)
        VALUES (v_prenume, v_nume, v_birth_date, '07' || FLOOR(RANDOM() * 90000000 + 10000000)::TEXT, v_email,
            (SELECT address FROM PATIENT WHERE id = v_tutor_id), v_tutor_id );
    END LOOP;
 
    FOR v_patient_id IN (SELECT id FROM PATIENT ORDER BY id) LOOP
 
        IF RANDOM() > 0.5 THEN
            v_type := 'lunar';
            v_start_date := CURRENT_DATE - FLOOR(RANDOM() * 60)::INT;
            v_end_date   := v_start_date + 30;
        ELSE
            v_type := 'anual';
            v_start_date := CURRENT_DATE - FLOOR(RANDOM() * 200)::INT;
            v_end_date   := v_start_date + 365;
        END IF;
 
        INSERT INTO SUBSCRIPTION (patient_id, type, start_date, end_date, cost, status)
        VALUES (v_patient_id, v_type, v_start_date, v_end_date,
            CASE v_type WHEN 'lunar' THEN 49.99 ELSE 499.99 END,
            CASE WHEN v_end_date >= CURRENT_DATE THEN 'activ' ELSE 'expirat' END);
 
    END LOOP;
 
    FOR v_sub_id IN (SELECT id FROM SUBSCRIPTION ORDER BY id) LOOP
        FOR v_i IN 1..FLOOR(RANDOM() * 3 + 1)::INT LOOP
            INSERT INTO SUBSCRIPTION_PAYMENT (subscription_id, paid_at, amount, method)
            VALUES (v_sub_id,
                NOW() - (FLOOR(RANDOM() * 200))::INT * INTERVAL '1 day',
                CASE WHEN RANDOM() > 0.5 THEN 49.99 ELSE 499.99 END,
                (ARRAY['card', 'transfer', 'cash'])[FLOOR(RANDOM() * 3 + 1)::INT]);
        END LOOP;
    END LOOP;
 
    FOR v_patient_id IN (SELECT id FROM PATIENT ORDER BY id) LOOP
        IF RANDOM() > 0.4 THEN
            INSERT INTO CHRONIC_CONDITION (patient_id, name, diagnosed_date)
            VALUES (v_patient_id,
                lista_conditii_cronice[FLOOR(RANDOM() * array_length(lista_conditii_cronice, 1)) + 1],
                CURRENT_DATE - FLOOR(RANDOM() * 365 * 5)::INT);
 
            IF RANDOM() > 0.7 THEN
                INSERT INTO CHRONIC_CONDITION (patient_id, name, diagnosed_date)
                VALUES (v_patient_id,
                    lista_conditii_cronice[FLOOR(RANDOM() * array_length(lista_conditii_cronice, 1)) + 1],
                    CURRENT_DATE - FLOOR(RANDOM() * 365 * 3)::INT
                );
            END IF;
        END IF;
    END LOOP;
 
    FOR v_patient_id IN (SELECT id FROM PATIENT ORDER BY id) LOOP
 
        v_complexity := FLOOR(RANDOM() * 3 + 1)::INT;
 
        v_diagnosis := CASE v_complexity
            WHEN 1 THEN 'Virozа usoara'
            WHEN 2 THEN 'Gripa sezoniera'
            WHEN 3 THEN 'Afectiune ce necesita investigatii suplimentare'
        END;
 
        INSERT INTO MEDICAL_FORM (patient_id, created_at, status, provisional_diagnosis, complexity_level)
        VALUES (v_patient_id, NOW() - (FLOOR(RANDOM() * 30))::INT * INTERVAL '1 day', 'completat', v_diagnosis, v_complexity)
        RETURNING id INTO v_form_id;
 
        v_symptom1 := lista_simptome_primare[FLOOR(RANDOM() * array_length(lista_simptome_primare, 1)) + 1];
        v_symptom2 := lista_simptome_primare[FLOOR(RANDOM() * array_length(lista_simptome_primare, 1)) + 1];
        v_symptom3 := lista_simptome_primare[FLOOR(RANDOM() * array_length(lista_simptome_primare, 1)) + 1];
 
        INSERT INTO SYMPTOM (form_id, description, type) VALUES (v_form_id, v_symptom1, 'primar');
        INSERT INTO SYMPTOM (form_id, description, type) VALUES (v_form_id, v_symptom2, 'primar');
        INSERT INTO SYMPTOM (form_id, description, type) VALUES (v_form_id, v_symptom3, 'primar');
 
        FOR v_i IN 1..FLOOR(RANDOM() * 3 + 1)::INT LOOP
            INSERT INTO SYMPTOM (form_id, description, type)
            VALUES (v_form_id, lista_simptome_secundare[FLOOR(RANDOM() * array_length(lista_simptome_secundare, 1)) + 1], 'secundar');
        END LOOP;
 
    END LOOP;
 
    FOR v_form_id IN (SELECT id FROM MEDICAL_FORM ORDER BY id) LOOP
 
        SELECT complexity_level INTO v_complexity FROM MEDICAL_FORM WHERE id = v_form_id;
 
        v_duration := CASE v_complexity
            WHEN 1 THEN 10
            WHEN 2 THEN 20
            WHEN 3 THEN 30
        END;
 
        SELECT id INTO v_doctor_id FROM DOCTOR ORDER BY RANDOM() LIMIT 1;
 
        v_scheduled_at := NOW() + (FLOOR(RANDOM() * 14))::INT * INTERVAL '1 day';
        v_scheduled_at := DATE_TRUNC('hour', v_scheduled_at) + INTERVAL '9 hours';
 
        INSERT INTO CONSULTATION (form_id, doctor_id, scheduled_at, duration_minutes, status, confirmed_diagnosis)
        VALUES (v_form_id, v_doctor_id, v_scheduled_at, v_duration,
            CASE WHEN RANDOM() > 0.4 THEN 'finalizata' ELSE 'programata' END,
            CASE v_complexity
                WHEN 1 THEN 'Viroза usoara confirmata'
                WHEN 2 THEN 'Gripa sezoniera confirmata'
                WHEN 3 THEN 'Caz complex - trimitere investigatii'
            END
        )
        RETURNING id INTO v_cons_id;
 
    END LOOP;

    FOR v_cons_id IN (SELECT id FROM CONSULTATION WHERE status = 'finalizata' ORDER BY id) LOOP
        IF RANDOM() > 0.3 THEN
            INSERT INTO PRESCRIPTION (consultation_id, issued_at, medications, recommendations)
            VALUES (v_cons_id, NOW() - (FLOOR(RANDOM() * 10))::INT * INTERVAL '1 day',
                lista_medicamente[FLOOR(RANDOM() * array_length(lista_medicamente, 1)) + 1],
                lista_recomandari[FLOOR(RANDOM() * array_length(lista_recomandari, 1)) + 1]
            );
        END IF;
    END LOOP;
  
END $$;

SELECT COUNT(*) || ' doctori inserati' AS rezultat FROM DOCTOR;
SELECT COUNT(*) || ' pacienti inserati' AS rezultat FROM PATIENT;
SELECT COUNT(*) || ' abonamente inserate' AS rezultat FROM SUBSCRIPTION;
SELECT COUNT(*) || ' plati inserate' AS rezultat FROM SUBSCRIPTION_PAYMENT;
SELECT COUNT(*) || ' afectiuni cronice' AS rezultat FROM CHRONIC_CONDITION;
SELECT COUNT(*) || ' fise medicale' AS rezultat FROM MEDICAL_FORM;
SELECT COUNT(*) || ' simptome inserate' AS rezultat FROM SYMPTOM;
SELECT COUNT(*) || ' consultatii inserate' AS rezultat FROM CONSULTATION;
SELECT COUNT(*) || ' prescriptii inserate' AS rezultat FROM PRESCRIPTION;
 