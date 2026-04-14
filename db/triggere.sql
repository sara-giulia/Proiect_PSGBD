CREATE OR REPLACE FUNCTION trg_update_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date < CURRENT_DATE THEN
        NEW.status := 'expirat';
    ELSE
        NEW.status := 'activ';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_subscription_status
    BEFORE INSERT OR UPDATE ON SUBSCRIPTION
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_subscription_status();

CREATE OR REPLACE FUNCTION trg_close_form_on_consultation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'finalizata' AND OLD.status != 'finalizata' THEN
        UPDATE MEDICAL_FORM
        SET status = 'inchis'
        WHERE id = NEW.form_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_consultation_finalizata
    AFTER UPDATE ON CONSULTATION
    FOR EACH ROW
    EXECUTE FUNCTION trg_close_form_on_consultation();

INSERT INTO SUBSCRIPTION (patient_id, type, start_date, end_date, cost, status)
VALUES (1, 'lunar', CURRENT_DATE - 60, CURRENT_DATE - 30, 49.99, 'activ');

SELECT id, status, end_date FROM SUBSCRIPTION ORDER BY id DESC LIMIT 1;

UPDATE CONSULTATION SET status = 'programata' WHERE id = 1;

UPDATE CONSULTATION SET status = 'finalizata' WHERE id = 1;

SELECT mf.id, mf.status
FROM MEDICAL_FORM mf
JOIN CONSULTATION c ON c.form_id = mf.id
WHERE c.id = 1;
	