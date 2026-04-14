DO $$ BEGIN
    CREATE TYPE telemedicina_exception AS ENUM (
        'ABONAMENT_INACTIV',
        'PACIENT_INEXISTENT',
        'SIMPTOME_INSUFICIENTE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION get_age_years(p_birth_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN DATE_PART('year', AGE(CURRENT_DATE, p_birth_date));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_active_subscription(p_patient_id INT)
RETURNS VOID AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM SUBSCRIPTION WHERE patient_id = p_patient_id
      AND status = 'activ' AND end_date >= CURRENT_DATE;

    IF v_count = 0 THEN
        RAISE EXCEPTION 'ABONAMENT_INACTIV: Pacientul cu id % nu are un abonament activ.', p_patient_id USING ERRCODE = 'P0001';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE genereaza_fisa_medicala(
    p_patient_id INT,
    p_symptom1 TEXT,
    p_symptom2 TEXT,
    p_symptom3 TEXT,
    OUT p_form_id INT,
    OUT p_diagnosis TEXT,
    OUT p_complexity INT,
    OUT p_extra_questions TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_age INT;
    v_is_child BOOLEAN := FALSE;
    v_has_chronic BOOLEAN := FALSE;
    v_chronic_names TEXT := '';
    v_patient_exists INT;
    v_simptome TEXT[];
    v_symptom_combined TEXT;

BEGIN

    SELECT COUNT(*) INTO v_patient_exists FROM PATIENT WHERE id = p_patient_id;

    IF v_patient_exists = 0 THEN
        RAISE EXCEPTION 'PACIENT_INEXISTENT: Nu exista pacient cu id %.', p_patient_id USING ERRCODE = 'P0002';
    END IF;

    IF p_symptom1 IS NULL OR p_symptom2 IS NULL OR p_symptom3 IS NULL
       OR TRIM(p_symptom1) = '' OR TRIM(p_symptom2) = '' OR TRIM(p_symptom3) = '' THEN
        RAISE EXCEPTION 'SIMPTOME_INSUFICIENTE: Trebuie introduse exact 3 simptome.' USING ERRCODE = 'P0003';
    END IF;

    PERFORM check_active_subscription(p_patient_id);

    SELECT get_age_years(birth_date) INTO v_age
    FROM PATIENT WHERE id = p_patient_id;

    IF v_age < 18 THEN
        v_is_child := TRUE;
    END IF;

    SELECT COUNT(*) > 0, STRING_AGG(name, ', ') INTO v_has_chronic, v_chronic_names FROM CHRONIC_CONDITION WHERE patient_id = p_patient_id;

    v_symptom_combined := LOWER(p_symptom1 || ' ' || p_symptom2 || ' ' || p_symptom3);

    IF v_symptom_combined LIKE '%durere abdominal%' AND
       v_symptom_combined LIKE '%varsaturi%' THEN

        p_complexity := 3;
        p_diagnosis  := 'Posibila apendicita sau afectiune digestiva acuta - redirectionare urgenta recomandata';
        p_extra_questions :=
            'Durerea abdominala este localizata in partea dreapta jos? (da/nu) | ' ||
            'Durerea s-a intensificat in ultimele ore? (da/nu) | ' ||
            'Aveti febra peste 38.5 grade? (da/nu) | ' ||
            'Ati mancat ceva suspect in ultimele 24h? (da/nu) | ' ||
            'ATENTIE: Daca durerea este severa, mergeti la urgente imediat.';

    ELSIF v_is_child AND
          v_symptom_combined LIKE '%febra%' AND
          v_symptom_combined LIKE '%varsaturi%' THEN

        p_complexity := 2;
        p_diagnosis  := 'Posibila viroза digestiva sau afectiune specifica copilariei';
        p_extra_questions :=
            'Ce temperatura a inregistrat copilul? (sub 38 / 38-39 / peste 39) | ' ||
            'De cate ore are febra? | ' ||
            'A vomitat de mai mult de 3 ori? (da/nu) | ' ||
            'Are eruptii pe piele? (da/nu) | ' ||
            'A fost in contact cu alti copii bolnavi recent? (da/nu)';

    ELSIF v_symptom_combined LIKE '%febra%' AND
          (v_symptom_combined LIKE '%durere de cap%' OR
           v_symptom_combined LIKE '%durere in gat%') THEN

        IF v_has_chronic THEN
            p_complexity := 2;
            p_diagnosis  := 'Posibila gripa sezoniera - atentie sporita datorita afectiunilor cronice: ' || v_chronic_names;
            p_extra_questions :=
                'Aveti febra peste 39 grade? (da/nu) | ' ||
                'Ati luat medicamentele pentru afectiunile cronice astazi? (da/nu) | ' ||
                'Simptomele s-au agravat in ultimele 24h? (da/nu) | ' ||
                'Aveti dificultati de respiratie? (da/nu)';
        ELSE
            p_complexity := 1;
            p_diagnosis  := 'Posibila viroза sau gripa usoara';
            p_extra_questions :=
                'Aveti febra peste 38 grade? (da/nu) | ' ||
                'De cate zile aveti simptomele? | ' ||
                'Ati luat vreun medicament pana acum? (da/nu) | ' ||
                'Aveti tuse productiva (cu secretii)? (da/nu)';
        END IF;

    ELSIF v_symptom_combined LIKE '%durere in piept%' OR
          v_symptom_combined LIKE '%dificultati de respiratie%' THEN

        p_complexity := 3;
        p_diagnosis  := 'Simptome posibil cardiace sau pulmonare - necesita evaluare urgenta';
        p_extra_questions :=
            'Durerea in piept iradiaza spre brat sau mandibula? (da/nu) | ' ||
            'Aveti senzatie de presiune sau strangere in piept? (da/nu) | ' ||
            'Va este greu sa respirati in repaus? (da/nu) | ' ||
            'Aveti istoric de boli cardiace? (da/nu) | ' ||
            'ATENTIE: Daca simptomele sunt severe, sunati la 112 imediat.';

    ELSIF v_symptom_combined LIKE '%greata%' AND
          v_symptom_combined LIKE '%durere abdominal%' THEN

        p_complexity := 2;
        p_diagnosis  := 'Posibila toxiinfectie alimentara sau gastroenterita';
        p_extra_questions :=
            'Ati mancat ceva neobisnuit in ultimele 12h? (da/nu) | ' ||
            'Aveti si diaree? (da/nu) | ' ||
            'Cati membrii ai familiei au aceleasi simptome? | ' ||
            'Aveti febra? (da/nu) | ' ||
            'Puteti tolera lichide? (da/nu)';

    ELSIF v_symptom_combined LIKE '%eruptie cutanata%' THEN

        p_complexity := 2;
        p_diagnosis  := 'Posibila reactie alergica sau afectiune dermatologica';
        p_extra_questions :=
            'Eruptia este insotita de mancarime? (da/nu) | ' ||
            'Ati folosit un produs nou recent (sapun, crema, detergent)? (da/nu) | ' ||
            'Eruptia s-a extins in ultimele ore? (da/nu) | ' ||
            'Aveti alergii cunoscute? (da/nu) | ' ||
            'Aveti dificultati de respiratie sau umflarea fetei? (da/nu)';

    ELSE
        IF v_has_chronic THEN
            p_complexity := 2;
            p_diagnosis  := 'Simptome generale - evaluare necesara tinand cont de afectiunile cronice: ' || v_chronic_names;
        ELSE
            p_complexity := 1;
            p_diagnosis  := 'Simptome generale usoare - posibila viroза sau oboseala';
        END IF;

        p_extra_questions :=
            'De cate zile aveti simptomele? | ' ||
            'Simptomele s-au agravat recent? (da/nu) | ' ||
            'Aveti febra? (da/nu) | ' ||
            'Ati fost in contact cu persoane bolnave? (da/nu)';
    END IF;

    INSERT INTO MEDICAL_FORM (patient_id, created_at, status, provisional_diagnosis, complexity_level) VALUES (p_patient_id, 
		NOW(), 'completat', p_diagnosis, p_complexity) RETURNING id INTO p_form_id;

    INSERT INTO SYMPTOM (form_id, description, type) VALUES (p_form_id, p_symptom1, 'primar');
    INSERT INTO SYMPTOM (form_id, description, type) VALUES (p_form_id, p_symptom2, 'primar');
    INSERT INTO SYMPTOM (form_id, description, type) VALUES (p_form_id, p_symptom3, 'primar');

    RAISE NOTICE 'Fisa medicala generata: id=%, complexitate=%, diagnostic=%', p_form_id, p_complexity, p_diagnosis;

END;
$$;



DO $$
DECLARE
    v_form_id INT;
    v_diagnosis TEXT;
    v_complexity INT;
    v_extra TEXT;
BEGIN
    CALL genereaza_fisa_medicala(1, 'febra', 'durere de cap', 'durere in gat', v_form_id, v_diagnosis, v_complexity, v_extra);

    RAISE NOTICE 'REZULTAT:';
    RAISE NOTICE 'Form ID: %', v_form_id;
    RAISE NOTICE 'Diagnostic: %', v_diagnosis;
    RAISE NOTICE 'Complexitate: %', v_complexity;
    RAISE NOTICE 'Intrebari extra: %', v_extra;
END;
$$;

DO $$
DECLARE
    v_form_id INT;
    v_diagnosis TEXT;
    v_complexity INT;
    v_extra TEXT;
BEGIN
    CALL genereaza_fisa_medicala(999, 'febra', 'tuse', 'oboseala', v_form_id, v_diagnosis, v_complexity, v_extra);
EXCEPTION
    WHEN SQLSTATE 'P0002' THEN
        RAISE NOTICE 'Exceptie prinsa: PACIENT_INEXISTENT - %', SQLERRM;
    WHEN SQLSTATE 'P0001' THEN
        RAISE NOTICE 'Exceptie prinsa: ABONAMENT_INACTIV - %', SQLERRM;
END;
$$;