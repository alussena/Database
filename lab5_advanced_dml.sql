/*
USSENBAYEVA ALUA
24B032088
*/


--PART 1
--TASK 1.1
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age >=18 AND age <= 65),
	salary NUMERIC CHECK( salary > 0)
	
);
--TASK 1.2
CREATE TABLE products_catalog (
	product_id INTEGER,
	product_name TEXT, 
	regular_price NUMERIC,
	discount_price NUMERIC,
	CONSTRAINT valid_discount CHECK(
		regular_price > 0
		AND discount_price > 0
		AND discount_price < regular_price
	)
);
--TASK 1.3
CREATE TABLE bookings (
	booking_id INTEGER,
	check_in_date DATE,
	check_out_date DATE,
	num_guests INTEGER CHECK(num_guests BETWEEN 1 AND 10),
	CHECK(check_out_date > check_in_date)
);

--TASK 1.4
--valid insertion
INSERT INTO employees VALUES(1, 'Alua', 'Ussenbayeva', 18, 10000000);
INSERT INTO employees VALUES(2, 'Inzhu', 'Aitakhyn', 18, 500000);

INSERT INTO products_catalog VALUES(1,'MacBook', 500000, 420000);
INSERT INTO products_catalog VALUES(2, 'iPhone', 720000, 680000);

INSERT INTO bookings VALUES(1, '2025-10-10', '2025-10-11', 7);
INSERT INTO bookings VALUES(2, '2025-09-10', '2025-09-15', 10);

--invalid insertion

INSERT INTO employees VALUES(3, 'Aikumis', 'Anuarbek', 68, 600000); --age > 65
INSERT INTO employees VALUES(4, 'Dilnara', 'Akan', 20, 0); --salary = 0 (case: salary > 0)

/*
ОШИБКА:  новая строка в отношении "employees" нарушает ограничение-проверку "employees_age_check"
SQL state: 23514
Detail: Ошибочная строка содержит (3, Aikumis, Anuarbek, 68, 600000).
*/

INSERT INTO products_catalog VALUES(3, 'iPad', 0, 250000); --regular price = 0 (must be > 0)
INSERT INTO products_catalog VALUES(4, 'iPods', 280000, 300000); --discount_price > regular_price (should be visa-versa)

/*
ERROR:  новая строка в отношении "products_catalog" нарушает ограничение-проверку "valid_discount"
Ошибочная строка содержит (3, iPad, 0, 250000).
*/

INSERT INTO bookings VALUES(3, '2025-10-01', '2025-09-01', 5); -- must be check_in < check_out
INSERT INTO bookings VALUES(4, '2025-08-13', '2025-08-20', 0); --num_guests is only between 1 and 10, not 0

/*
ОШИБКА:  новая строка в отношении "bookings" нарушает ограничение-проверку "bookings_check"
SQL state: 23514
Detail: Ошибочная строка содержит (3, 2025-10-01, 2025-09-01, 5).
*/

--PART 2
--Task 2.1
CREATE TABLE customers(
	customer_id INTEGER NOT NULL,
	email TEXT NOT NULL,
	phone TEXT,
	registration_date DATE NOT NULL
);
--Task 2.2
CREATE TABLE inventory(
	item_id INTEGER NOT NULL,
	item_name TEXT NOT NULL,
	quantity INTEGER NOT NULL CHECK(quantity>=0),
	unit_price NUMERIC NOT NULL CHECK(unit_price>0),
	last_updated TIMESTAMP NOT NULL
);
--Task 2.3
--valid insertion
INSERT INTO customers VALUES(1, 'a_ussenbayeva@kbtu.kz', '87771112233', '2024-12-01');
INSERT INTO customers(customer_id, email, registration_date) VALUES(2, 'i_aitakhyn@kbtu.kz', '2025-05-21');

INSERT INTO inventory VALUES(1, 'Computer', 50, 1500.5, '2025-12-10 21:00:00');
INSERT INTO inventory VALUES(2, 'Processor', 100, 1000, '2025-12-11 09:00:00');

--invalid insertion
INSERT INTO customers(customer_id, email, registration_date)
VALUES(NULL, 'di_akan@kbtu.kz','2025-08-02');

INSERT INTO customers(customer_id, email, registration_date)
VALUES (3, NULL, '2025-06-24');

--phone is nullable in customers
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (4, 'aluuua9@gmail.com', NULL, '2025-01-01');


--PART 3
--Task 3.1
CREATE TABLE users(
	user_id INTEGER,
	username TEXT UNIQUE,
	email TEXT UNIQUE,
	created_at TIMESTAMP
);
--Task 3.2
CREATE TABLE course_enrollments(
	enrollment_id INTEGER,
	student_id INTEGER,
	course_code TEXT,
	semester TEXT,
	CONSTRAINT unique_enrollment UNIQUE  (student_id, course_code, semester)
);
--Task 3.3
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

--testing
INSERT INTO users VALUES(1, 'alussena', 'a_ussenbayeva@kbtu.kz', '2025-01-01 08:00:00');
INSERT INTO users VALUES(2, 'innlan', 'i_aitakhyn@kbtu.kz', '2025-01-02 09:00:00');

INSERT INTO users VALUES(3, 'alussena', 'aluuua9@gmail.com', '2025-03-03 10:00:00');
INSERT INTO users VALUES(4, 'innlann', 'i_aitakhyn@kbtu.kz', '2025-03-04 11:00:00');

-- SELECT * FROM users


--PART 4
--Task 4.1
CREATE TABLE departments(
	dept_id INTEGER PRIMARY KEY,
	dept_name TEXT NOT NULL,
	"location" TEXT
);

INSERT INTO departments VALUES(1, 'Fronted', 'Zurich');
INSERT INTO departments VALUES(2, 'Finance', 'Bern');
INSERT INTO departments VALUES(3, 'Backend', 'Colifornia');

--1
INSERT INTO departments VALUES(1, 'HR', 'Zurich');
--2
INSERT INTO departments VALUES(NULL, 'Marketing', 'LA');

--Task 4.2
CREATE TABLE student_courses(
	student_id INTEGER,
	course_id INTEGER,
	enrollment_date DATE,
	grade TEXT,
	PRIMARY KEY (student_id, course_id)
);

--Task 4.3
/*
1. PRIMARY KEY: ensures uniqueness and NOT NULL (cannot be empty). Only one per table.
UNIQUE: ensures uniqueness but allows NULLs (considering each NULL as unique, so in the table can be seberal NULLs).

2. Single-column PK: we use when one cloumn (like id) can uniquely identify a row by itself. F,e task 4.1.
Composite PK: use when no single column is enough, but a combintation of columns together makes a row unique, 
as order_id + product_id. F,e task 4.2.

3.A table needs one main identifier which is the PRIAMRY KEY.
But it may have other attributes that must also be unique, so multiple UNIQUE constraints are allowed.
*/

--PART 5
--Task 5.1

CREATE TABLE employees_dept(
	emp_id INTEGER PRIMARY KEY,
	emp_name TEXT NOT NULL,
	dept_id INTEGER REFERENCES departments(dept_id),
	hire_id DATE
);
INSERT INTO employees_dept VALUES(100, 'Alua', 1, '2022-02-22');
INSERT INTO employees_dept VALUES(101, 'Inzhu', 2, '2022-02-22');
INSERT INTO employees_dept VALUES(102, 'Aikumis', 3, '2023-01-17');

--Task 5.2
CREATE TABLE authors(
	author_id INTEGER PRIMARY KEY,
	author_name TEXT NOT NULL,
	country TEXT
);
CREATE TABLE publishers(
	publisher_id INTEGER PRIMARY KEY,
	publisher_name TEXT NOT NULL,
	city TEXT
);
CREATE TABLE books(
	book_id INTEGER PRIMARY KEY,
	title TEXT NOT NULL,
	author_id INTEGER REFERENCES authors(author_id),
	publisher_id INTEGER REFERENCES publishers(publisher_id),
	publication_year INTEGER,
	isbn TEXT UNIQUE
);

INSERT INTO authors VALUES(1, 'Joanne Rowling', 'United Kingdom');
INSERT INTO authors VALUES(2, 'Sanzhar Kerimbay', 'Kazakhstan');

INSERT INTO publishers VALUES(1, 'Qasym baspahanasy', 'Almaty');
INSERT INTO publishers VALUES(2, 'EKSMO', 'Moscow');

INSERT INTO books VALUES(100, 'Harry Potter', 1, 2, 2001, '978-140-8856-78-9');
INSERT INTO books VALUES(101, 'Quyskeude', 2, 1, 2023, '978-601-7088-13-2');

--Task 5.3
CREATE TABLE categories(
	category_id INTEGER PRIMARY KEY,
	category_name TEXT NOT NULL
);
CREATE TABLE products_fk(
	product_id INTEGER PRIMARY KEY,
	product_name TEXT NOT NULL,
	category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);
CREATE TABLE orders(
	order_id INTEGER PRIMARY KEY,
	order_date DATE NOT NULL
);
CREATE TABLE order_items(
	item_id INTEGER PRIMARY KEY,
	order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
	product_id INTEGER REFERENCES products_fk(product_id),
	quantity INTEGER CHECK(quantity>0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Books');


INSERT INTO products_fk VALUES (101, 'Laptop', 1);
INSERT INTO products_fk VALUES (102, 'Non-fiction', 2);


INSERT INTO orders VALUES (201, '2023-09-15');
INSERT INTO orders VALUES (202, '2023-09-20');

INSERT INTO order_items VALUES (301, 201, 101, 2);
INSERT INTO order_items VALUES (302, 201, 102, 1);
INSERT INTO order_items VALUES (303, 202, 102, 3);

--1
DELETE FROM categories WHERE category_id = 1;
/*
ERROR:  UPDATE или DELETE в таблице "categories" нарушает ограничение внешнего ключа "products_fk_category_id_fkey" таблицы "products_fk"
На ключ (category_id)=(1) всё ещё есть ссылки в таблице "products_fk". 
*/
--2
DELETE FROM orders WHERE order_id = 201;

-- SELECT * FROM order_items;

/*
ON DELETE RESTRICT prevents deleting parent row if child rows exist.
ON DELETE CASCADE automatically deletes child rows when parent row is deleted.
*/


--PART 6
--Task 6.1
CREATE TABLE customers(
	customer_id INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	email TEXT NOT NULL UNIQUE,
	phone TEXT,
	registration_date DATE NOT NULL
);
CREATE TABLE products(
	product_id INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	description TEXT NOT NULL,
	price NUMERIC CHECK(price>=0),
	stock_quantity INTEGER CHECK(stock_quantity >=0)
);
CREATE TABLE orders (
	order_id INTEGER PRIMARY KEY,
	customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
	order_date DATE NOT NULL,
	total_amount INTEGER,
	status TEXT CHECK(status IN('pending', 'processing', 'shipped', 'delivered','cancelled')) --BOOLEAN is not convenient to use.
);
CREATE TABLE order_details(
	order_detail_id INTEGER PRIMARY KEY,
	order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
	product_id INTEFER REFERENCES products(product_id) ON DELETE RESTRICT,
	quantity INTEGER CHECK(quantity>0),
	unit_price INTEGER NOT NULL CHECK(unit_price>=0)
);
INSERT INTO customers VALUES
(1, 'Alua Ussenbayeva', 'a_ussenbayeva@kbtu.kz', '87076645064', '2024-12-01'),
(2, 'Inzhu Aitakhyn', 'i_aitakhyn@kbtu.kz', '87772223131', '2024-05-21'),
(3, 'Dilnara Akan', 'di_akan@kbtu.kz', '87075554343', '2023-08-02'),
(4, 'Aikumis Anuarbek', 'a_anuarbek@kbtu.kz', '87076665454', '2023-06-24'),
(5, 'Aisha Salikh', 'a_salikh@kbtu.kz', '87473332121', '2025-04-30');

INSERT INTO products VALUES
(101, 'Laptop', '15-inch display, 16GB RAM', 1200.00, 10),
(102, 'Smartphone', '128GB storage, 5G support', 800.00, 20),
(103, 'Headphones', 'Noise cancelling wireless', 150.00, 50),
(104, 'Keyboard', 'Mechanical RGB keyboard', 90.00, 30),
(105, 'Monitor', '27-inch 4K display', 400.00, 15);

INSERT INTO orders VALUES
(201, 1, '2023-06-01', 1200.00, 'pending'),
(202, 2, '2023-06-05', 950.00, 'processing'),
(203, 3, '2023-06-10', 800.00, 'shipped'),
(204, 4, '2023-06-15', 490.00, 'delivered'),
(205, 5, '2023-06-20', 150.00, 'cancelled');

INSERT INTO order_details VALUES
(301, 201, 101, 10, 1200.00),
(302, 202, 102, 20, 800.00),
(303, 202, 104, 25, 90.00),
(304, 203, 102, 21, 800.00),
(305, 204, 103, 30, 150.00);

--duplicate email
INSERT INTO customers VALUES (6, 'Fake User', 'a_ussenbayeva@kbtu.kz', '0000000000', '2025-01-01');
--negative price
INSERT INTO products VALUES (106, 'Test Product', 'Invalid price', -10, 5);
--invalid status
INSERT INTO orders VALUES (206, 5, '2024-01-01', 100.00, 'returned');
--zero quantity
INSERT INTO order_details VALUES (306, 205, 101, 0, 1200.00);
--ON DELETE CASCADE (deleting customer 1 will delete order 201)
DELETE FROM customers WHERE customer_id = 1;
--ON DELETE RESTRICT (trying delete a product referenced in order_details)
DELETE FROM products WHERE product_id = 102;