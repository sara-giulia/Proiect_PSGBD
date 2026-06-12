# Telemedicine Platform - PSGBD Project

A web-based telemedicine management system built with **Java Spring Boot** and **PostgreSQL**, developed as part of the Databases course (PSGBD) at university.

## Overview

This application allows patients to schedule consultations, fill in medical forms, and receive prescriptions online. Doctors can manage their schedule, view patient history, and issue recommendations - all through a secure web interface.

## Features

- **Authentication & Authorization** - Separate login flows for patients and doctors
- **Patient Dashboard** - View appointments, medical history, and active subscriptions
- **Doctor Dashboard** - Manage consultations, view patient medical forms, issue prescriptions
- **Medical Forms** - Patients fill in symptoms and medical history before consultations
- **Automatic Prescription Generation** - PL/pgSQL function that generates prescriptions based on diagnosis and complexity level
- **Consultation Scheduling** - Patients can book appointments within doctor availability hours
- **Subscription Management** - Monthly and annual subscription plans with payment tracking
- **Medical Reports** - Generate and view reports per patient or doctor

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3.5 |
| Frontend | Thymeleaf, HTML/CSS |
| Database | PostgreSQL |
| ORM / DB Access | Spring Data JDBC |
| Session Management | Spring Session Core |
| Build Tool | Maven |

## Database Structure

The PostgreSQL schema includes the following tables:

- `PATIENT` - Patient accounts with optional tutor relationship (for minors)
- `DOCTOR` - Doctor accounts with specialization and schedule
- `SUBSCRIPTION` / `SUBSCRIPTION_PAYMENT` - Subscription plans and payment tracking
- `CONSULTATION` - Scheduled consultations between patients and doctors
- `MEDICAL_FORM` - Pre-consultation medical forms filled by patients
- `SYMPTOM` - Symptoms reported by patients
- `CHRONIC_CONDITION` - Chronic conditions associated with patients
- `PRESCRIPTION` - Prescriptions issued after consultations
- `FORM_ANSWER` - Answers to standardized medical form questions

The database also includes **PL/pgSQL stored procedures, functions, triggers, and wrappers** for business logic such as automatic prescription generation and consultation scheduling validation.

## Project Structure

```
Proiect_PSGBD/
├── db/
│   ├── create_tables.sql         # Schema definition
│   ├── populate.sql              # Sample data
│   ├── functii.sql               # PL/pgSQL functions
│   ├── triggere.sql              # Database triggers
│   ├── wrappere.sql              # Wrapper procedures
│   ├── fisa_medicala.sql         # Medical form logic
│   └── programeaza_consultatie.sql  # Consultation scheduling logic
├── telemedicina/                 # Spring Boot application
│   └── src/main/java/...        # Controllers and application logic
│   └── src/main/resources/
│       ├── templates/            # Thymeleaf HTML templates
│       └── application.properties
└── Referat_PSGBD.pdf            # Project documentation
```

## Getting Started

### Prerequisites

- Java 21+
- PostgreSQL 14+
- Maven 3.8+

### Setup

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd Proiect_PSGBD
   ```

2. Create the database and run the SQL scripts in order:
   ```sql
   psql -U postgres -d your_db -f db/create_tables.sql
   psql -U postgres -d your_db -f db/populate.sql
   psql -U postgres -d your_db -f db/functii.sql
   psql -U postgres -d your_db -f db/triggere.sql
   psql -U postgres -d your_db -f db/wrappere.sql
   ```

3. Configure the database connection in `telemedicina/src/main/resources/application.properties`:
   ```properties
   spring.datasource.url=jdbc:postgresql://localhost:5432/your_db
   spring.datasource.username=your_username
   spring.datasource.password=your_password
   ```

4. Run the application:
   ```bash
   cd telemedicina
   ./mvnw spring-boot:run
   ```

5. Open your browser at `http://localhost:8080`

## Key Concepts Demonstrated

- Relational database design with normalization
- PL/pgSQL stored procedures and triggers
- Spring Boot MVC architecture
- Session-based authentication
- Dynamic HTML rendering with Thymeleaf
