--Ussenbayeva Alua

--CREATE

--customers
CREATE TABLE IF NOT EXISTS customers (
    customer_id     BIGSERIAL PRIMARY KEY,
    iin             VARCHAR(12) NOT NULL UNIQUE,     
    full_name       TEXT NOT NULL,
    phone           VARCHAR(32),
    email           TEXT,
    status          VARCHAR(10) NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    daily_limit_kzt NUMERIC(18,2) NOT NULL DEFAULT 500000.00,
    CONSTRAINT customers_status_check CHECK (status IN ('active','blocked','frozen'))
);

--accounts
CREATE TABLE IF NOT EXISTS accounts (
    account_id     BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number TEXT NOT NULL UNIQUE, -- IBAN-format string
    currency       VARCHAR(3) NOT NULL,
    balance        NUMERIC(20,2) NOT NULL DEFAULT 0.00,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at      TIMESTAMPTZ,
    CONSTRAINT accounts_currency_check CHECK (currency IN ('KZT','USD','EUR','RUB'))
);

--transactions
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id   BIGSERIAL PRIMARY KEY,
    from_account_id  BIGINT REFERENCES accounts(account_id),
    to_account_id    BIGINT REFERENCES accounts(account_id),
    amount           NUMERIC(20,2) NOT NULL,           
    currency         VARCHAR(3) NOT NULL,
    exchange_rate    NUMERIC(30,10),                    
    amount_kzt       NUMERIC(20,2),                      
    type             VARCHAR(20) NOT NULL,               
    status           VARCHAR(10) NOT NULL DEFAULT 'pending', 
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at     TIMESTAMPTZ,
    description      TEXT,
    CONSTRAINT transactions_currency_check CHECK (currency IN ('KZT','USD','EUR','RUB')),
    CONSTRAINT transactions_type_check CHECK (type IN ('transfer','deposit','withdrawal','salary')), --in 4th tasl we will need salary column
    CONSTRAINT transactions_status_check CHECK (status IN ('pending','completed','failed','reversed'))
);

--exchange_rates
CREATE TABLE IF NOT EXISTS exchange_rates (
    rate_id      BIGSERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency   VARCHAR(3) NOT NULL,
    rate          NUMERIC(30,10) NOT NULL,
    valid_from    TIMESTAMPTZ NOT NULL,
    valid_to      TIMESTAMPTZ,
    CONSTRAINT exchange_rates_currency_check CHECK (char_length(from_currency) > 0 AND char_length(to_currency) > 0)
);

--audit_log
CREATE TABLE IF NOT EXISTS audit_log (
    log_id     BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id  BIGINT,
    action     VARCHAR(10) NOT NULL, 
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ip_address TEXT,
    CONSTRAINT audit_action_check CHECK (action IN ('INSERT','UPDATE','DELETE'))
);

--INSERT

--customers
INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
('111111111111','Alua Ussenbayeva','87076645065','a_ussenbayeva@kbtu.kz','active', 2000000.00),
('222222222222','Inzhu Aitakhyn','87076562802','i_aitakhyn@kbtu.kz','active', 1000000.00),
('333333333333','Dilnara Akan','+87772319170','di_akan@kbtu.kz','frozen', 500000.00),
('444444444444','Aikumis Anuarbek','87046585064','a_anuarbek@gmail.com','active', 300000.00),
('555555555555','Aisha Rakhimberdieva','87003125465','aisharkh@gmail.com','blocked', 100000.00),
('666666666666','Samira Urmanova','87472259160','s_urmanova@kbtu.kz','active', 800000.00),
('777777777777','Nurzhan Manapbayev','87076007191','nurzhan1998@gmail.com','active', 500000.00),
('888888888888','Omar Uzak','87077777777','omaru@gmail.com','active', 1200000.00),
('999999999999','Kairat Almasov','87055052030','kairat@gmail.com','active', 2500000.00),
('000000000000','Taimas Sattarov','87073455432','taimass@gmail.com','active', 600000.00);

--accounts (create multiple currencies)
INSERT INTO accounts (customer_id, account_number, currency, balance)
SELECT c.customer_id,
       concat('KZ', lpad((100000 + row_number() over (order by c.customer_id))::text, 14, '0')) as iban,
       CASE ((row_number() over (order by c.customer_id)-1) % 4)
         WHEN 0 THEN 'KZT' WHEN 1 THEN 'USD' WHEN 2 THEN 'EUR' ELSE 'RUB' END,
       (10000 + (row_number() over (order by c.customer_id) * 1000))::numeric
FROM customers c
LIMIT 12;

--add second account for some customers
INSERT INTO accounts (customer_id, account_number, currency, balance)
VALUES
((SELECT customer_id FROM customers WHERE iin='111111111111'), 'KZ0000000000000015','KZT', 150000.00),
((SELECT customer_id FROM customers WHERE iin='222222222222'), 'KZ0000000000000016','USD', 5000.00),
((SELECT customer_id FROM customers WHERE iin='333333333333'), 'KZ0000000000000017','EUR', 3000.00);

--exchange rates(to kzt) - valid ranges(simple dataset)
INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to)
VALUES
('USD','KZT', 470.0000, now() - interval '1 day', now() + interval '30 day'),
('EUR','KZT', 515.0000, now() - interval '1 day', now() + interval '30 day'),
('RUB','KZT', 5.5000, now() - interval '1 day', now() + interval '30 day'),
('KZT','KZT', 1.0, now() - interval '1 day', now() + interval '30 day');

--sample transactions
INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at)
SELECT a1.account_id, a2.account_id, 1000.00, a1.currency,
    (SELECT rate FROM exchange_rates r WHERE r.from_currency = a1.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to LIMIT 1),
    1000.00 * (SELECT rate FROM exchange_rates r WHERE r.from_currency = a1.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to LIMIT 1),
    'transfer', 'completed', now() - interval '1 hour'
FROM accounts a1 CROSS JOIN accounts a2
WHERE a1.account_id <> a2.account_id
LIMIT 10;

--minimal audit entries
INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, changed_at, ip_address)
VALUES ('customers', (SELECT customer_id FROM customers LIMIT 1), 'INSERT', NULL, to_jsonb((SELECT row_to_json(c) FROM (SELECT * FROM customers LIMIT 1) c)), current_user, now(), '127.0.0.1');


--Tasks

--Task 1: Transaction Management
CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number TEXT,
    p_to_account_number   TEXT,
    p_amount              NUMERIC,
    p_currency            VARCHAR,
    p_description         TEXT,
    p_changed_by          TEXT DEFAULT current_user,
    p_ip                  TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
    v_from_account RECORD;
    v_to_account   RECORD;
    v_from_customer RECORD;
    v_today_total NUMERIC := 0;
    v_rate NUMERIC;
    v_amount_kzt NUMERIC;
    v_old_from JSONB;
    v_old_to   JSONB;
    v_tx_id BIGINT;
    v_result JSONB;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'AMOUNT_MUST_BE_POSITIVE: amount must be > 0' USING ERRCODE = 'P0001';
    END IF;

    --acquire row locks to prevent race conditions
    SELECT * INTO v_from_account FROM accounts WHERE account_number = p_from_account_number FOR UPDATE;
    IF NOT FOUND THEN
        PERFORM audit_log_insert('transactions', NULL, 'INSERT', NULL, jsonb_build_object('error','from_account_not_found','from_account',p_from_account_number), p_changed_by, p_ip);
        RAISE EXCEPTION 'FROM_ACCOUNT_NOT_FOUND: source account % not found', p_from_account_number USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_to_account FROM accounts WHERE account_number = p_to_account_number FOR UPDATE;
    IF NOT FOUND THEN
        PERFORM audit_log_insert('transactions', NULL, 'INSERT', NULL, jsonb_build_object('error','to_account_not_found','to_account',p_to_account_number), p_changed_by, p_ip);
        RAISE EXCEPTION 'TO_ACCOUNT_NOT_FOUND: destination account % not found', p_to_account_number USING ERRCODE = 'P0003';
    END IF;

    --ccheck accounts active
    IF NOT v_from_account.is_active THEN
        PERFORM audit_log_insert('accounts', v_from_account.account_id, 'UPDATE', to_jsonb(v_from_account), NULL, p_changed_by, p_ip);
        RAISE EXCEPTION 'FROM_ACCOUNT_INACTIVE: source account is not active' USING ERRCODE = 'P0004';
    END IF;
    IF NOT v_to_account.is_active THEN
        PERFORM audit_log_insert('accounts', v_to_account.account_id, 'UPDATE', to_jsonb(v_to_account), NULL, p_changed_by, p_ip);
        RAISE EXCEPTION 'TO_ACCOUNT_INACTIVE: destination account is not active' USING ERRCODE = 'P0005';
    END IF;

    --check customer status
    SELECT * INTO v_from_customer FROM customers WHERE customer_id = v_from_account.customer_id;
    IF v_from_customer.status <> 'active' THEN
        PERFORM audit_log_insert('customers', v_from_customer.customer_id, 'UPDATE', to_jsonb(v_from_customer), NULL, p_changed_by, p_ip);
        RAISE EXCEPTION 'SENDER_NOT_ACTIVE: customer status is %', v_from_customer.status USING ERRCODE = 'P0006';
    END IF;

    --computing exchange rate(convert transfer currency to KZT)
    IF p_currency = 'KZT' THEN
        v_rate := 1.0;
    ELSE
        SELECT rate INTO v_rate FROM exchange_rates
        WHERE from_currency = p_currency AND to_currency = 'KZT' AND now() BETWEEN valid_from AND valid_to
        ORDER BY valid_from DESC LIMIT 1;
        IF v_rate IS NULL THEN
            PERFORM audit_log_insert('exchange_rates', NULL, 'INSERT', NULL, jsonb_build_object('error','rate_not_found','currency',p_currency), p_changed_by, p_ip);
            RAISE EXCEPTION 'EXCHANGE_RATE_NOT_FOUND for currency %', p_currency USING ERRCODE = 'P0007';
        END IF;
    END IF;

    v_amount_kzt := round(p_amount * v_rate, 2);

    --check sufficient balance in source account (balance stored in its account currency)
    --if sending currency differs from from_account currency, compute equivalent withdrawal in from_account currency using exchange_rates between p_currency and account currency.
    --approach: convert p_amount (in p_currency) to KZT (v_amount_kzt), then to from_account currency.
    DECLARE
        v_rate_from_acc NUMERIC;
        v_withdraw_amount NUMERIC;
    BEGIN
        IF v_from_account.currency = p_currency THEN
            v_withdraw_amount := p_amount;
        ELSE
            --convert p_currency -> KZT using v_rate (already), then KZT -> from_account.currency
            SELECT rate INTO v_rate_from_acc FROM exchange_rates
            WHERE from_currency = v_from_account.currency AND to_currency = 'KZT' AND now() BETWEEN valid_from AND valid_to LIMIT 1;
            IF v_rate_from_acc IS NULL THEN
                RAISE EXCEPTION 'RATE_NOT_FOUND_FOR_FROM_ACCOUNT: %', v_from_account.currency USING ERRCODE = 'P0008';
            END IF;
            --amount in from_account currency = v_amount_kzt / v_rate_from_acc
            v_withdraw_amount := round(v_amount_kzt / v_rate_from_acc, 2);
        END IF;
    END;

    IF v_from_account.balance < v_withdraw_amount THEN
        PERFORM audit_log_insert('accounts', v_from_account.account_id, 'UPDATE', to_jsonb(v_from_account), NULL, p_changed_by, p_ip);
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS: required % available %', v_withdraw_amount, v_from_account.balance USING ERRCODE = 'P0009';
    END IF;

    --check daily transaction limit: sum of today's transactions for this sender (converting each to KZT) + current <= daily_limit_kzt
    SELECT COALESCE(SUM(amount_kzt),0) INTO v_today_total FROM transactions
    WHERE from_account_id = v_from_account.account_id
      AND created_at::date = now()::date
      AND status = 'completed';

    IF (v_today_total + v_amount_kzt) > v_from_customer.daily_limit_kzt THEN
        PERFORM audit_log_insert('transactions', NULL, 'INSERT', NULL, jsonb_build_object('error','daily_limit_exceeded','today_total',v_today_total,'attempt',v_amount_kzt), p_changed_by, p_ip);
        RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED: attempted % + today % > limit %', v_amount_kzt, v_today_total, v_from_customer.daily_limit_kzt USING ERRCODE = 'P0010';
    END IF;

    --create transaction row as pending
    INSERT INTO transactions(from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
    VALUES (v_from_account.account_id, v_to_account.account_id, p_amount, p_currency, v_rate, v_amount_kzt, 'transfer', 'pending', now(), p_description)
    RETURNING transaction_id INTO v_tx_id;

    --save old states for audit
    v_old_from := to_jsonb(v_from_account);
    v_old_to   := to_jsonb(v_to_account);

    --savepoint if we will encounter fails
    SAVEPOINT sp_transfer;

    BEGIN
        --debit from source in its currency
        UPDATE accounts
        SET balance = balance - v_withdraw_amount
        WHERE account_id = v_from_account.account_id;

        --credit to destination
        DECLARE
            v_credit_amount NUMERIC;
        BEGIN
            IF v_to_account.currency = p_currency THEN
                v_credit_amount := p_amount;
            ELSE
                --convert p_currency -> KZT (v_amount_kzt) then to to_account currency
                SELECT rate INTO STRICT v_rate FROM exchange_rates
                WHERE from_currency = v_to_account.currency AND to_currency = 'KZT' AND now() BETWEEN valid_from AND valid_to LIMIT 1;
                IF v_rate IS NULL THEN
                    -- fallback: convert KZT - to_account.currency by dividing by rate found earlier
                    RAISE EXCEPTION 'RATE_NOT_FOUND_FOR_TO_ACCOUNT: %', v_to_account.currency USING ERRCODE = 'P0011';
                END IF;
                --v_rate is rate for to_account.currency to KZT. credit = v_amount_kzt / v_rate
                v_credit_amount := round(v_amount_kzt / v_rate, 2);
            END IF;

            UPDATE accounts
            SET balance = balance + v_credit_amount
            WHERE account_id = v_to_account.account_id;
        END;

        --transaction completed
        UPDATE transactions SET status='completed', completed_at = now() WHERE transaction_id = v_tx_id;

        --audit: log changes (old -> new)
        PERFORM audit_log_insert('accounts', v_from_account.account_id, 'UPDATE', v_old_from, (SELECT to_jsonb(a) FROM (SELECT * FROM accounts WHERE account_id = v_from_account.account_id) a), p_changed_by, p_ip);
        PERFORM audit_log_insert('accounts', v_to_account.account_id, 'UPDATE', v_old_to, (SELECT to_jsonb(a) FROM (SELECT * FROM accounts WHERE account_id = v_to_account.account_id) a), p_changed_by, p_ip);
        PERFORM audit_log_insert('transactions', v_tx_id, 'INSERT', NULL, (SELECT to_jsonb(t) FROM (SELECT * FROM transactions WHERE transaction_id = v_tx_id) t), p_changed_by, p_ip);

        v_result := jsonb_build_object('status','ok','transaction_id',v_tx_id,'amount_kzt',v_amount_kzt);
        RETURN v_result;
    EXCEPTION WHEN OTHERS THEN
        --partial rollback to savepoint then mark transaction failed
        ROLLBACK TO SAVEPOINT sp_transfer;
        UPDATE transactions SET status='failed', completed_at = now(), description = coalesce(description, '') || ' -- failed: ' || SQLERRM WHERE transaction_id = v_tx_id;
        PERFORM audit_log_insert('transactions', v_tx_id, 'UPDATE', NULL, jsonb_build_object('status','failed','error',SQLERRM), p_changed_by, p_ip);
        RAISE; --propagate
    END;

EXCEPTION WHEN SQLSTATE 'P0001' THEN
    RAISE;
WHEN SQLSTATE 'P0002' THEN
    RAISE;
WHEN SQLSTATE 'P0003' THEN
    RAISE;
WHEN OTHERS THEN
    --generic catch: log and rethrow
    PERFORM audit_log_insert('transactions', NULL, 'INSERT', NULL, jsonb_build_object('error','unexpected','message',SQLERRM), p_changed_by, p_ip);
    RAISE;
END;
$$;

--Task 2: Views for Reporting

--View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.iin,
    c.email,
    c.daily_limit_kzt,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance AS account_balance,
    --convert each account balance to KZT using latest rate
    round(
        a.balance *
        COALESCE(
            (SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to ORDER BY valid_from DESC LIMIT 1),
            1.0
        ), 2
    ) AS balance_kzt,
    --total for customer (window)
    round(SUM(
        a.balance *
        COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to ORDER BY valid_from DESC LIMIT 1),1.0)
    ) OVER (PARTITION BY c.customer_id), 2) AS total_kzt,
    --limit utilization
    round(100.0 * (SUM(
        a.balance *
        COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to ORDER BY valid_from DESC LIMIT 1),1.0)
    ) OVER (PARTITION BY c.customer_id) / NULLIF(c.daily_limit_kzt,0)),2) AS daily_limit_util_pct,
    --rank customers by total balance
    RANK() OVER (ORDER BY SUM(
        a.balance *
        COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to ORDER BY valid_from DESC LIMIT 1),1.0)
    ) OVER (PARTITION BY c.customer_id) DESC) AS balance_rank
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id;

--View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    t_date,
    type,
    SUM(total_volume) AS total_volume,
    SUM(tx_count) AS tx_count,
    ROUND(AVG(avg_amount)::numeric,2) AS avg_amount,
    SUM(total_volume) OVER (ORDER BY t_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_volume,
    tx_count - LAG(tx_count) OVER (ORDER BY t_date) AS day_over_day_count_diff,
    CASE WHEN LAG(total_volume) OVER (ORDER BY t_date) IS NULL THEN NULL
         WHEN LAG(total_volume) OVER (ORDER BY t_date) = 0 THEN NULL
         ELSE ROUND(100.0 * (SUM(total_volume) OVER (PARTITION BY type ORDER BY t_date ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) - LAG(SUM(total_volume)) OVER (PARTITION BY type ORDER BY t_date)) / NULLIF(LAG(SUM(total_volume)) OVER (PARTITION BY type ORDER BY t_date),0),2)
    END AS day_over_day_growth_pct
FROM (
    SELECT
        date_trunc('day', created_at) AS t_date,
        type,
        SUM(amount_kzt) AS total_volume,
        COUNT(*) AS tx_count,
        AVG(amount_kzt) AS avg_amount
    FROM transactions
    WHERE status = 'completed'
    GROUP BY 1,2
) s
GROUP BY t_date, type, SUM(total_volume), SUM(tx_count), AVG(avg_amount)
ORDER BY t_date DESC;

--View 3: suspicious_activity_view (WITH SECURITY BARRIER)
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
WITH tx_kzt AS (
    SELECT t.*,
        COALESCE(t.amount_kzt,
            (t.amount *
             COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = t.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to LIMIT 1),1.0)
            )
        ) AS computed_amount_kzt
    FROM transactions t
)
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.type,
    t.status,
    t.created_at,
    t.computed_amount_kzt,
    (t.computed_amount_kzt > 5000000) AS over_5m_kzt,
    --customers with >10 transactions in single hour
    EXISTS(
        SELECT 1 FROM transactions t2
        WHERE t2.from_account_id = t.from_account_id
          AND date_trunc('hour', t2.created_at) = date_trunc('hour', t.created_at)
        GROUP BY date_trunc('hour', t2.created_at)
        HAVING COUNT(*) > 10
    ) AS more_than_10_in_hour,
    --rapid sequential transfers: same sender within 1 minute of previous
    EXISTS(
        SELECT 1 FROM transactions t3
        WHERE t3.from_account_id = t.from_account_id
          AND t3.transaction_id <> t.transaction_id
          AND abs(extract(epoch from (t3.created_at - t.created_at))) < 60
        LIMIT 1
    ) AS rapid_seq
FROM tx_kzt t
WHERE (t.amount_kzt IS NOT NULL AND t.amount_kzt > 5000000)
   OR EXISTS(
        SELECT 1 FROM transactions t2
        WHERE t2.from_account_id = t.from_account_id
          AND date_trunc('hour', t2.created_at) = date_trunc('hour', t.created_at)
        GROUP BY date_trunc('hour', t2.created_at)
        HAVING COUNT(*) > 10
   )
   OR EXISTS(
        SELECT 1 FROM transactions t3
        WHERE t3.from_account_id = t.from_account_id
          AND t3.transaction_id <> t.transaction_id
          AND abs(extract(epoch from (t3.created_at - t.created_at))) < 60
   );

-- Task 3: Performance Optimization Indexes

-- 1) B-tree index on accounts.customer_id for joins and lookups
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);

-- 2) Composite index (B-tree) for frequent query pattern: find transactions by from_account_id and created_at (range) and status
-- Also include amount_kzt as covering column using INCLUDE (Postgres supports INCLUDE)
CREATE INDEX idx_transactions_from_date_status ON transactions (from_account_id, created_at DESC, status) INCLUDE (amount_kzt);

-- 3) Partial index for active accounts only
CREATE INDEX idx_accounts_account_number_active ON accounts(account_number) WHERE is_active;

-- 4) Expression index for case-insensitive email search
CREATE INDEX idx_customers_lower_email ON customers (lower(email));

-- 5) GIN index on audit_log JSONB columns (old_values and new_values)
CREATE INDEX idx_audit_log_jsonb ON audit_log USING GIN (coalesce(old_values,'{}'::jsonb) || coalesce(new_values,'{}'::jsonb));

-- 6) Hash index on customers.iin (lookup by IIN)
CREATE INDEX idx_customers_iin_hash ON customers USING HASH (iin);

-- 7) Additional B-tree index on transactions(amount_kzt) for suspicious queries
CREATE INDEX idx_transactions_amount_kzt ON transactions (amount_kzt);

-- EXPLAIN ANALYZE SELECT * FROM transactions WHERE from_account_id = <some_id> AND created_at > now()-interval '1 day';
-- EXPLAIN ANALYZE SELECT * FROM accounts WHERE account_number = '<acct>' AND is_active = TRUE;
-- EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = lower('a_ussenbayeva@kbtu.kz');
-- EXPLAIN ANALYZE SELECT * FROM audit_log WHERE old_values @> '{"full_name":"Alua Ussenbayeva"}';

-- Task 4: Advanced Procedure - Batch Processing
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number TEXT,
    p_payments JSONB, -- iin, amount, description
    p_changed_by TEXT DEFAULT current_user,
    p_ip TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
    v_company_account RECORD;
    v_total NUMERIC := 0;
    v_payment RECORD;
    v_results JSONB := '[]'::jsonb;
    v_success_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::jsonb;
    v_tx_id BIGINT;
    v_idx INT := 0;
BEGIN
    --acquire advisory lock per company account number to prevent concurrent processing
    PERFORM pg_advisory_xact_lock(hashtext(p_company_account_number)::bigint);

    SELECT * INTO v_company_account FROM accounts WHERE account_number = p_company_account_number FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'COMPANY_ACCOUNT_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;

    --calculate total batch amount
    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
        v_total := v_total + (v_payment->>'amount')::numeric;
    END LOOP;

    IF v_company_account.balance < v_total THEN
        RAISE EXCEPTION 'INSUFFICIENT_COMPANY_FUNDS: % < %', v_company_account.balance, v_total USING ERRCODE = 'P0021';
    END IF;

    --create a transactions array in memory, but update balances atomically at COMMIT by making adjustments to temp table.
    CREATE TEMP TABLE tmp_salary_effects (
        account_id BIGINT,
        amount_delta NUMERIC
    ) ON COMMIT DROP;

    --process each payment individually with SAVEPOINT so failures don't abort the entire batch.
    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
        v_idx := v_idx + 1;
        BEGIN
            SAVEPOINT sp_salary_pay;
            --find recipient account by IIN (customer -> account). We choose first active account of customer for simplicity.
            PERFORM 1;
            DECLARE
                v_rec_customer RECORD;
                v_rec_account RECORD;
                v_amount NUMERIC := (v_payment->>'amount')::numeric;
                v_desc TEXT := coalesce(v_payment->>'description','salary');
            BEGIN
                SELECT * INTO v_rec_customer FROM customers WHERE iin = (v_payment->>'iin');
                IF NOT FOUND THEN
                    ROLLBACK TO SAVEPOINT sp_salary_pay;
                    v_failed_count := v_failed_count + 1;
                    v_failed_details := v_failed_details || jsonb_build_object('index', v_idx, 'iin', v_payment->>'iin', 'error','recipient_not_found');
                    CONTINUE;
                END IF;

                --choose recipient active account in same currency as company if possible, else pick any active account.
                SELECT * INTO v_rec_account FROM accounts
                 WHERE customer_id = v_rec_customer.customer_id AND is_active = TRUE
                 ORDER BY CASE WHEN currency = v_company_account.currency THEN 0 ELSE 1 END
                 LIMIT 1 FOR UPDATE;

                IF NOT FOUND THEN
                    ROLLBACK TO SAVEPOINT sp_salary_pay;
                    v_failed_count := v_failed_count + 1;
                    v_failed_details := v_failed_details || jsonb_build_object('index', v_idx, 'iin', v_payment->>'iin', 'error','recipient_has_no_active_account');
                    CONTINUE;
                END IF;

                --create transaction row but mark as pending; salary bypasses daily limit
                INSERT INTO transactions(from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
                VALUES (v_company_account.account_id, v_rec_account.account_id, v_amount, v_company_account.currency,
                        (SELECT rate FROM exchange_rates r WHERE r.from_currency = v_company_account.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to LIMIT 1),
                        v_amount * COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = v_company_account.currency AND r.to_currency = 'KZT' AND now() BETWEEN r.valid_from AND r.valid_to LIMIT 1),1.0),
                        'salary', 'pending', now(), v_desc)
                RETURNING transaction_id INTO v_tx_id;

                --accumulate effect in tmp table 
                INSERT INTO tmp_salary_effects(account_id, amount_delta) VALUES (v_rec_account.account_id, v_amount);
                --debit will be recorded as negative on company account later
                v_success_count := v_success_count + 1;
                PERFORM audit_log_insert('transactions', v_tx_id, 'INSERT', NULL, (SELECT to_jsonb(t) FROM (SELECT * FROM transactions WHERE transaction_id = v_tx_id) t), p_changed_by, p_ip);
            END;
        EXCEPTION WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_salary_pay;
            v_failed_count := v_failed_count + 1;
            v_failed_details := v_failed_details || jsonb_build_object('index', v_idx, 'error', SQLERRM);
            CONTINUE;
        END;
    END LOOP;

    SELECT * INTO v_company_account FROM accounts WHERE account_number = p_company_account_number FOR UPDATE;

    DECLARE v_total_delta NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(amount_delta),0) INTO v_total_delta FROM tmp_salary_effects;
    END;

    IF v_company_account.balance < v_total_delta THEN
        --should not happen because we checked earlier, but guard again
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS_AT_COMMIT: % < %', v_company_account.balance, v_total_delta USING ERRCODE = 'P0022';
    END IF;

    --apply credits to recipients
    UPDATE accounts a
    SET balance = a.balance + e.amount_delta
    FROM (SELECT account_id, SUM(amount_delta) AS amount_delta FROM tmp_salary_effects GROUP BY account_id) e
    WHERE a.account_id = e.account_id;

    --debit company account
    UPDATE accounts SET balance = balance - v_total_delta WHERE account_id = v_company_account.account_id;

    --mark all salary transactions inserted in this batch as completed
    UPDATE transactions SET status='completed', completed_at = now()
    WHERE from_account_id = v_company_account.account_id AND type='salary' AND status='pending' AND created_at >= (now() - interval '1 hour');

    --insert audit logs for company and recipients
    PERFORM audit_log_insert('accounts', v_company_account.account_id, 'UPDATE', NULL, (SELECT to_jsonb(a) FROM (SELECT * FROM accounts WHERE account_id = v_company_account.account_id) a), p_changed_by, p_ip);
    FOR v_payment IN SELECT * FROM tmp_salary_effects LOOP
        PERFORM audit_log_insert('accounts', v_payment.account_id, 'UPDATE', NULL, (SELECT to_jsonb(a) FROM (SELECT * FROM accounts WHERE account_id = v_payment.account_id) a), p_changed_by, p_ip);
    END LOOP;

    --materialized view population handled below (in separate MV creation)
    v_results := jsonb_build_object('successful_count', v_success_count, 'failed_count', v_failed_count, 'failed_details', v_failed_details);

    RETURN v_results;
END;
$$;


--materialized view summary for salary batches (simple): summarize salary transactions by company per day
CREATE MATERIALIZED VIEW IF NOT EXISTS salary_batch_summary AS
SELECT
    date_trunc('day', completed_at) AS day,
    from_account_id AS company_account_id,
    COUNT(*) AS payments_count,
    SUM(amount) AS total_amount,
    SUM(amount_kzt) AS total_amount_kzt
FROM transactions
WHERE type = 'salary' AND status = 'completed'
GROUP BY 1,2
WITH DATA;

--grant refresh privileges
GRANT SELECT ON salary_batch_summary TO PUBLIC;

-- Test 1: successful same-currency transfer
-- SELECT process_transfer('KZ0000000000000001', 'KZ0000000000000002', 100.00, 'KZT', 'test transfer', current_user, '127.0.0.1');

-- Test 2: insufficient funds
-- SELECT process_transfer('KZ0000000000000001', 'KZ0000000000000002', 99999999999.00, 'KZT', 'big transfer', current_user, '127.0.0.1');

-- Test 3: account not found
-- SELECT process_transfer('NONEXIST', 'KZ0000000000000002', 100, 'KZT', 'x', current_user, '127.0.0.1');

-- Test 4: cross-currency transfer USD -> KZT
-- SELECT process_transfer((SELECT account_number FROM accounts WHERE currency='USD' LIMIT 1), (SELECT account_number FROM accounts WHERE currency='KZT' LIMIT 1), 10.00, 'USD', 'usd->kzt', current_user, '127.0.0.1');

-- Test 5: Batch salary processing (company must have enough balance)
-- SELECT process_salary_batch('KZ0000000000000001', '[{"iin":"222222222222","amount":100.00,"description":"June salary"},{"iin":"111111111111","amount":200.00,"description":"June salary"}]'::jsonb, current_user, '127.0.0.1');
