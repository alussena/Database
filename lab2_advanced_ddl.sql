-- ** Part 1: Multiple Database Management ** --
-- Task 1.1: Database Creation with Parameters
CREATE DATABASE university_main TEMPLATE template0 ENCODING UTF8;
CREATE DATABASE university_archive CONNECTION LIMIT 50 TEMPLATE template0;
CREATE DATABASE university_test IS_TEMPLATE true CONNECTION LIMIT 10;

-- Task 1.2: Tablespace Operations
CREATE TABLESPACE student_data LOCATION '/data/students';
CREATE TABLESPACE course_data OWNER CURRENT_USER LOCATION '/data/courses';

CREATE DATABASE university_distributed
    TABLESPACE student_data
    -- Line below allow us to change encoding, i.e. LC_CTYPE and LC_COLLATE
    TEMPLATE template0
    -- Two line below just sets appropriate options for the latin9 encoding.
    -- I use these general values, because my machine does not support ISO885915
    LC_CTYPE 'C'
    LC_COLLATE 'C'
    ENCODING 'LATIN9';


-- ** Part 2: Complex Table Creation ** --
-- Task 2.1: University Management System
-- Line below just needs to select required table.
-- Normally, it's done in psql manually, but if you
-- run this file in psql, then it should work
\c university_main
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa DECIMAL(2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(2),
    is_tenured BOOLEAN,
    years_experience INT
);
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INT,
    course_fee DECIMAL(2),
    is_online BOOLEAN,
    created_at TIMESTAMP
);

-- Task 2.2: Time-based and Specialized Tables --
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INT,
    professor_id INT,
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME,
    end_time TIME,
    duration INTERVAL
);
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    year INT,
    grade CHAR(2),
    attendance_percentage DECIMAL(1),
    submission_timestamp TIMESTAMPTZ,
    last_updated TIMESTAMPTZ
);

-- ** Part 3: Advanced ALTER TABLE Operations ** --
-- Task 3.1: Modifying Existing Tables
ALTER TABLE students ADD COLUMN middle_name VARCHAR(30);
ALTER TABLE students ADD COLUMN student_status VARCHAR(20);
ALTER TABLE students ALTER COLUMN phone TYPE VARCHAR(20);
ALTER TABLE students ALTER COLUMN student_status SET DEFAULT 'ACTIVE';
ALTER TABLE students ALTER COLUMN gpa SET DEFAULT 0.00;

ALTER TABLE professors ADD COLUMN department_code CHAR(5);
ALTER TABLE professors ADD COLUMN research_area TEXT;
ALTER TABLE professors ALTER COLUMN years_experience TYPE SMALLINT;
ALTER TABLE professors ALTER COLUMN is_tenured SET DEFAULT false;
ALTER TABLE professors ADD COLUMN last_promotion_date DATE;

ALTER TABLE courses ADD COLUMN prerequisite_course_id INT;
ALTER TABLE courses ADD COLUMN difficulty_level SMALLINT;
ALTER TABLE courses ALTER COLUMN course_code TYPE VARCHAR(10);
ALTER TABLE courses ALTER COLUMN credits SET DEFAULT 3;
ALTER TABLE courses ADD COLUMN lab_required BOOLEAN DEFAULT false;

-- Task 3.2: Column Management Operations
ALTER TABLE class_schedule ADD COLUMN room_capacity INT;
ALTER TABLE class_schedule DROP COLUMN duration;
ALTER TABLE class_schedule ADD COLUMN session_type VARCHAR(15);
ALTER TABLE class_schedule ALTER COLUMN classroom TYPE VARCHAR(30);
ALTER TABLE class_schedule ADD COLUMN equipment_needed TEXT;

ALTER TABLE student_records ADD COLUMN extra_credit_points DECIMAL(1);
ALTER TABLE student_records ALTER COLUMN grade TYPE VARCHAR(5);
ALTER TABLE student_records ALTER COLUMN extra_credit_points SET DEFAULT 0.0;
ALTER TABLE student_records ADD COLUMN final_exam_date DATE;
ALTER TABLE student_records DROP COLUMN last_updated;


-- ** Part 4: Table Relationships and Management ** --
-- Task 4.1: Additional Supporting Tables
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(2),
    established_year INT
);
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price DECIMAL(2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP
);
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INT,
    book_id INT,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(2),
    loan_status VARCHAR(20)
);

-- Task 4.2: Table Modifications for Integration
ALTER TABLE professors ADD COLUMN department_id INT;
ALTER TABLE students ADD COLUMN advisor_id INT;
ALTER TABLE courses ADD COLUMN department_id INT;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(1),
    max_percentage DECIMAL(1),
    gpa_point DECIMAL(2)
);
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);


-- ** Part 5: Table Deletion and Cleanup ** --
-- Task 5.1: Conditional Table Operations
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(1),
    max_percentage DECIMAL(1),
    gpa_point DECIMAL(2),
    description TEXT
);

DROP TABLE semester_calendar CASCADE;
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);

-- Task 5.2: Database Cleanup
-- One line below is needed to drop table 'university_test'.
-- By default, postgres doesn't allow you to drop a template database.
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'university_test';
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;
CREATE DATABASE university_backup TEMPLATE university_main;