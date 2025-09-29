-- Part A: Database and Table Setup

-- 1. Create database and tables

-- Create table departments
CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(100) UNIQUE NOT NULL,
    budget     INTEGER NOT NULL DEFAULT 0,
    manager_id INTEGER
);

-- Create table employees
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(100) DEFAULT 'Unassigned',
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

-- Create table projects
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    dept_id      INTEGER REFERENCES departments(dept_id),
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);


-- Insert sample data to test queries 

INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT',      200000, NULL),
('Sales',   120000, NULL),
('Finance', 150000, NULL),
('R&D',     300000, NULL),
('HR',       80000, NULL);

-- Insert sample employees 
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
('Alice',  'Johnson', 'IT',     75000, '2018-06-15', 'Active'),
('Bob',    'Smith',   'Sales',  55000, '2021-03-01', 'Active'),
('Carol',  'Davis',   'Finance',90000, '2015-10-20', 'Active'),
('Dave',   'Wilson',  'IT',     48000, '2024-02-10', 'Active'),
('Eve',    'Taylor',  NULL,     35000, '2023-05-05', 'Terminated'),
('Frank',  'Miller',  'Sales',  45000, '2022-11-11', 'Active'),
('Grace',  'Lee',     'R&D',    120000,'2017-01-01', 'Active'),
('Heidi',  'Brown',   'IT',     65000, '2019-08-08', 'Inactive');

-- Insert sample projects
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
('Platform Upgrade',  (SELECT dept_id FROM departments WHERE dept_name='IT'),    '2023-01-15', '2023-12-31', 60000),
('Sales Campaign',    (SELECT dept_id FROM departments WHERE dept_name='Sales'), '2022-05-01', '2022-11-30', 30000),
('R&D Prototype',     (SELECT dept_id FROM departments WHERE dept_name='R&D'),   '2024-03-01', '2025-01-31', 120000),
('Legacy Migration',  (SELECT dept_id FROM departments WHERE dept_name='IT'),    '2020-01-01', '2022-12-31', 45000);


-- Part B: Advanced INSERT Operations

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (9999, 'Zed', 'Example', 'Contractors');

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Ivy', 'Green', 'HR', CURRENT_DATE);

-- 4. INSERT multiple rows in single statement (3 departments at once)
INSERT INTO departments (dept_name, budget, manager_id) VALUES
('Legal', 60000, NULL),
('Support', 90000, NULL),
('Marketing', 110000, NULL);

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES (
    'Jon', 'Working',
    'IT',
    CAST(50000 * 1.1 AS INTEGER),
    CURRENT_DATE,
    DEFAULT
);

-- 6. INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees AS
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
WHERE department = 'IT';


-- Part C: Complex UPDATE Operations

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = CAST(ROUND(COALESCE(salary, 0) * 1.10) AS INTEGER)
WHERE salary IS NOT NULL;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE COALESCE(salary,0) > 60000
  AND hire_date < DATE '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = CAST( (COALESCE((
    SELECT AVG(salary::NUMERIC)
    FROM employees e
    WHERE e.department = d.dept_name
    AND e.salary IS NOT NULL
), 0) * 1.20) AS INTEGER )
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = CAST(ROUND(COALESCE(salary,0) * 1.15) AS INTEGER),
    status = 'Promoted'
WHERE department = 'Sales' AND salary IS NOT NULL;


-- Part D: Advanced DELETE Operations

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT d.dept_id
    FROM departments d
    LEFT JOIN employees e ON e.department = d.dept_name
    WHERE e.department IS NOT NULL
);


-- 16. DELETE with RETURNING clause
WHERE end_date < DATE '2023-01-01'
RETURNING *;


-- Part E: Operations with NULL Values

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, salary, department, hire_date, status)
VALUES ('Null', 'Tester', NULL, NULL, CURRENT_DATE, 'Active');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;


-- Part F: RETURNING Clause Operations

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Laura', 'Adams', 'Marketing', 70000, CURRENT_DATE, 'Active')
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
WITH updated AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE department = 'IT' AND salary IS NOT NULL
)
UPDATE employees e
SET salary = salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING e.emp_id, u.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;


-- Part G: Advanced DML Patterns

-- 23. Conditional INSERT
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Sam', 'Unique', 'Support', 48000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Sam' AND last_name = 'Unique'
);

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = CAST(ROUND(
    CASE WHEN COALESCE(d.budget,0) > 100000 THEN COALESCE(e.salary,0) * 1.10
         ELSE COALESCE(e.salary,0) * 1.05
    END
) AS INTEGER)
FROM departments d
WHERE e.department = d.dept_name
  AND e.salary IS NOT NULL;

-- 25. Bulk operations
-- Insert 5 employees in single statement
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
('Bulk1','User1','Support', 42000, CURRENT_DATE, 'Active'),
('Bulk2','User2','Support', 43000, CURRENT_DATE, 'Active'),
('Bulk3','User3','Support', 44000, CURRENT_DATE, 'Active'),
('Bulk4','User4','Support', 45000, CURRENT_DATE, 'Active'),
('Bulk5','User5','Support', 46000, CURRENT_DATE, 'Active');

UPDATE employees
SET salary = CAST(ROUND(salary * 1.10) AS INTEGER)
WHERE department = 'Support' AND hire_date = CURRENT_DATE;

-- 26. Data migration simulation

-- Create archive table 
CREATE TABLE IF NOT EXISTS employee_archive (
    emp_id     INTEGER PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(100),
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(20),
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert into archive
INSERT INTO employee_archive (emp_id, first_name, last_name, department, salary, hire_date, status)
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
WHERE status = 'Inactive'
ON CONFLICT (emp_id) DO NOTHING;  -- avoid duplicates if re-run

DELETE FROM employees WHERE status = 'Inactive';

-- 27. Complex business logic
WITH dept_emp_count AS (
    SELECT e.department AS dept_name, COUNT(*) AS emp_count
    FROM employees e
    GROUP BY e.department
)
UPDATE projects p
SET end_date = p.end_date + INTERVAL '30 days'
FROM departments d
LEFT JOIN dept_emp_count dec ON dec.dept_name = d.dept_name
WHERE p.dept_id = d.dept_id
  AND p.budget > 50000
  AND COALESCE(dec.emp_count, 0) > 3
RETURNING p.project_id, p.project_name, p.end_date;



-- SELECT * FROM employees ORDER BY emp_id LIMIT 100;
