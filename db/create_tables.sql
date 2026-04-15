DROP TABLE IF EXISTS PRESCRIPTION CASCADE;
DROP TABLE IF EXISTS CONSULTATION CASCADE;
DROP TABLE IF EXISTS SYMPTOM CASCADE;
DROP TABLE IF EXISTS MEDICAL_FORM CASCADE;
DROP TABLE IF EXISTS CHRONIC_CONDITION CASCADE;
DROP TABLE IF EXISTS SUBSCRIPTION_PAYMENT CASCADE;
DROP TABLE IF EXISTS SUBSCRIPTION CASCADE;
DROP TABLE IF EXISTS DOCTOR CASCADE;
DROP TABLE IF EXISTS PATIENT CASCADE;
DROP TABLE IF EXISTS FORM_ANSWER CASCADE;

DROP SEQUENCE IF EXISTS seq_patient;
DROP SEQUENCE IF EXISTS seq_subscription;
DROP SEQUENCE IF EXISTS seq_payment;
DROP SEQUENCE IF EXISTS seq_chronic;
DROP SEQUENCE IF EXISTS seq_form;
DROP SEQUENCE IF EXISTS seq_symptom;
DROP SEQUENCE IF EXISTS seq_doctor;
DROP SEQUENCE IF EXISTS seq_consultation;
DROP SEQUENCE IF EXISTS seq_prescription;
DROP SEQUENCE IF EXISTS seq_answer;

CREATE SEQUENCE seq_patient START 1 INCREMENT 1;
CREATE SEQUENCE seq_subscription START 1 INCREMENT 1;
CREATE SEQUENCE seq_payment START 1 INCREMENT 1;
CREATE SEQUENCE seq_chronic START 1 INCREMENT 1;
CREATE SEQUENCE seq_form START 1 INCREMENT 1;
CREATE SEQUENCE seq_symptom START 1 INCREMENT 1;
CREATE SEQUENCE seq_doctor START 1 INCREMENT 1;
CREATE SEQUENCE seq_consultation START 1 INCREMENT 1;
CREATE SEQUENCE seq_prescription START 1 INCREMENT 1;
CREATE SEQUENCE seq_answer START 1 INCREMENT 1;

CREATE TABLE PATIENT (
	id INT DEFAULT nextval('seq_patient') PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	birth_date DATE NOT NULL,
	phone_number VARCHAR(15) NOT NULL,
	email VARCHAR(100) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	address TEXT,
	tutor_id INT,

	CONSTRAINT fk_patient_tutor FOREIGN KEY (tutor_id) REFERENCES PATIENT(id) ON DELETE SET NULL
);

CREATE TABLE DOCTOR (
	id INT DEFAULT nextval('seq_doctor') PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(100) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	specialization VARCHAR(100) NOT NULL,
	schedule_start TIME NOT NULL,
	schedule_end TIME NOT NULL,

	CONSTRAINT chk_doctor_schedule CHECK (schedule_end > schedule_start)
);

CREATE TABLE SUBSCRIPTION (
	id INT DEFAULT nextval('seq_subscription') PRIMARY KEY,
	patient_id INT NOT NULL,
	type VARCHAR(10) NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	cost DECIMAL(10,2) NOT NULL,
	status VARCHAR(10) NOT NULL DEFAULT 'activ',

	CONSTRAINT fk_sub_patient FOREIGN KEY (patient_id) REFERENCES PATIENT(id) ON DELETE CASCADE,
	CONSTRAINT chk_sub_type CHECK (type IN ('lunar', 'anual')),
	CONSTRAINT chk_sub_status CHECK (status IN ('activ', 'expirat')),
	CONSTRAINT chk_sub_dates CHECK (end_date > start_date)
);

CREATE TABLE SUBSCRIPTION_PAYMENT (
	id INT DEFAULT nextval('seq_payment') PRIMARY KEY,
	subscription_id INT NOT NULL,
	paid_at TIMESTAMP NOT NULL DEFAULT now(),
	amount DECIMAL(10,2) NOT NULL,
	method VARCHAR(30) NOT NULL,

	CONSTRAINT fk_payment_sub FOREIGN KEY (subscription_id) REFERENCES SUBSCRIPTION(id) ON DELETE CASCADE,
	CONSTRAINT chk_payment_method CHECK (method IN ('card', 'transfer', 'cash'))
);

CREATE TABLE CHRONIC_CONDITION (
	id INT DEFAULT nextval('seq_chronic') PRIMARY KEY,
	patient_id INT NOT NULL,
	name VARCHAR(100) NOT NULL,
	diagnosed_date DATE,

	CONSTRAINT fk_chronic_patient FOREIGN KEY (patient_id) REFERENCES PATIENT(id) ON DELETE CASCADE
);

CREATE TABLE MEDICAL_FORM (
	id INT DEFAULT nextval('seq_form') PRIMARY KEY,
	patient_id INT NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT now(),
	status VARCHAR(20) NOT NULL DEFAULT 'nou',
	provisional_diagnosis TEXT,
	complexity_level INT NOT NULL DEFAULT 1,

	CONSTRAINT fk_form_patient FOREIGN KEY (patient_id) REFERENCES PATIENT(id) ON DELETE CASCADE,
	CONSTRAINT chk_form_status CHECK (status IN ('nou', 'completat', 'programat', 'inchis')),
	CONSTRAINT chk_form_complexity CHECK (complexity_level BETWEEN 1 AND 3)
);

CREATE TABLE SYMPTOM (
	id INT DEFAULT nextval('seq_symptom') PRIMARY KEY,
	form_id INT NOT NULL,
	description TEXT NOT NULL,
	type VARCHAR(10) NOT NULL DEFAULT 'primar',

	CONSTRAINT fk_symptom_form FOREIGN KEY (form_id) REFERENCES MEDICAL_FORM(id) ON DELETE CASCADE,
	CONSTRAINT chk_symptom_type CHECK (type IN ('primar', 'secundar'))
);

CREATE TABLE CONSULTATION (
	id INT DEFAULT nextval('seq_consultation') PRIMARY KEY,
	form_id INT NOT NULL UNIQUE,
	doctor_id INT NOT NULL,
	scheduled_at TIMESTAMP NOT NULL,
	duration_minutes INT NOT NULL,
	status VARCHAR(20) NOT NULL DEFAULT 'programata',
	confirmed_diagnosis TEXT,
	notes TEXT,
	referral_type VARCHAR(50),
	referral_details TEXT,
	waiting_list BOOLEAN DEFAULT FALSE,

	CONSTRAINT fk_cons_form FOREIGN KEY (form_id) REFERENCES MEDICAL_FORM(id) ON DELETE CASCADE,
	CONSTRAINT fk_cons_doctor FOREIGN KEY (doctor_id) REFERENCES DOCTOR(id) ON DELETE RESTRICT,
	CONSTRAINT chk_cons_status CHECK (status IN ('programata', 'finalizata', 'anulata')),
	CONSTRAINT chk_cons_duration CHECK (duration_minutes IN (10, 20, 30))
);

CREATE TABLE PRESCRIPTION (
	id INT DEFAULT nextval('seq_prescription') PRIMARY KEY,
	consultation_id INT NOT NULL UNIQUE,
	issued_at TIMESTAMP NOT NULL DEFAULT now(),
	medications TEXT NOT NULL,
	recommendations TEXT,

	CONSTRAINT fk_presc_consultation FOREIGN KEY (consultation_id) REFERENCES CONSULTATION(id) ON DELETE CASCADE
);

CREATE TABLE FORM_ANSWER (
    id INT DEFAULT nextval('seq_answer') PRIMARY KEY,
    form_id INT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    
    CONSTRAINT fk_answer_form FOREIGN KEY (form_id) REFERENCES MEDICAL_FORM(id) ON DELETE CASCADE
);

CREATE INDEX idx_patient_email ON PATIENT(email);
CREATE INDEX idx_sub_patient ON SUBSCRIPTION(patient_id);
CREATE INDEX idx_form_patient ON MEDICAL_FORM(patient_id);
CREATE INDEX idx_symptom_form ON SYMPTOM(form_id);
CREATE INDEX idx_consultation_doctor ON CONSULTATION(doctor_id);
CREATE INDEX idx_consultation_schedule ON CONSULTATION(scheduled_at);
CREATE INDEX idx_answer_form ON FORM_ANSWER(form_id);