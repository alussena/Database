-- SQL Transactions and Isolation Levels

-- 3. Practical Tasks

--3.1 Setup

--Create
CREATE TABLE accounts(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00
);
CREATE TABLE products(
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);
--Insert
INSERT INTO accounts(name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products(shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

--3.2 Task 1: Basic Transaction with COMMIT
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;

--3.3 Task 2: Using ROLLBACK
BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

--3.4 Task 3: Working with SAVEPOINTs
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
--Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Wally';
COMMIT;

--3.5 Task 4: Isolation Level Demonstration
--Scenario A: READ COMITTED
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
--
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products(shop, product, price)
    VALUES('Joe''s Shop', 'Fanta', 3.50);
COMMIT;
--Scenario B:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

--3.6 Task 5: Phantom Read Demonstration
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';
--
SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
INSERT INTO products(shop, product, price)
    VALUES('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

--3.7 Task 6: Dirty Read Demonstration
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
--
SELECT * FROM products WHERE shop = 'Joe''s Shop';
--
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
UPDATE products SET price = 99.99
    WHERE product = 'Fanta';
--
--
ROLLBACK;

--INDEPENDENT EXERCISES

--ex.1
BEGIN;
DO $$
DECLARE current_balance numeric;
BEGIN
    SELECT balance INTO current_balance
    FROM accounts
    WHERE name = 'Bob';

    IF current_balance < 200 THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
END $$;

--Transfer
UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
COMMIT;

--without DO $$
BEGIN;
SELECT balance
FROM accounts
WHERE name = 'Bob'
FOR UPDATE;
--if Bob has insufficient funds, rollback manually
--simple check
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Bob'
    AND balance >= 200;
--chech if the withdrawl actually happened
WITH chk AS(
    SELECT balance FROM accounts WHERE name = 'Bob'
)
SELECT * FROM chk;
--
UPDATE accounts 
SET balance = balance + 200
WHERE name = 'Wally';
COMMIT;

--ex.2
BEGIN;
INSERT INTO products(shop, product, price)
VALUES('Joes''s Shop', 'Tea', 2.00);
SAVEPOINT s1;
UPDATE products SET price = 3.00
WHERE product = 'Tea';
SAVEPOINT s2;
DELETE FROM products WHERE product = 'Tea';
ROLLBACK TO s1;
COMMIT;

--ex.3
INSERT INTO accounts(name, balance)
VALUES('Alua', 500.00);
--READ UNCOMMIITED
--term1
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT balance FROM accounts WHERE name='Alua';
UPDATE accounts SET balance = balance - 400.00
WHERE name = 'Alua';
--term2
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT balance FROM accounts WHERE name='Alua';
UPDATE accounts SET balance = balance - 400.00
WHERE name = 'Alua';
-- Account becomes -300, Dirty reads, data corruption, no safety

--READ COMMITTED
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alua'; --sees 500
UPDATE accounts SET balance = balance - 400.00 WHERE name = 'Alua';
--term2
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Alua';
--sees 500, bcz T1 has not committed
UPDATE accounts SET balance = balance - 400.00;
--Both transactions succeed, final balance = -300, prevents dirty reads, but NOT race corruption

--REPEATABLE READ
--term 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name = 'Alua'; --500
UPDATE accounts SET balance = balance - 400.00;
--term2
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name = 'Alua'; --snapshot shows 500 (old state)
UPDATE accounts SET balance = balance - 400.00; 
--TERMINAL 1 COMMITs successfully
--Terminal 2 ets ERROR
--No corruption, only one withdrawl succeeds, second transaction fails and must retry

--SERIALIZABLE (Strongest level)
--term1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alua'; --500
UPDATE accounts SET balance = balance - 400.00; --100
--term2
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alua'; --SEES 500 AS snapshot
UPDATE accounts SET balance = balance - 400.00; 
/*
at COMMIT:
Only one transaction can succeed. The other receives ERROR
RESULT:
100% correct, prevents all anomalies, one withdrawl succeeds, one fails, 
application must retry failed transaction
*/


--ex.4
--INCORRECT 
SELECT MAX(price) FROM sells WHERE shop='A';
SELECT MIN(price) FROM sells WHERE shop='A';
--this can produce max<min
--CORRECT
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM sells WHERE shop ='A';
COMMIT;
