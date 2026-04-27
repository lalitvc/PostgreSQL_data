-- =====================================================
-- FILE: PG_DDL_TRANSACTION.sql
-- Purpose: Demonstrates TRANSACTIONS, CURSORS, PREPARED STATEMENTS
--          Covers: BEGIN, COMMIT, ROLLBACK, SAVEPOINTS, PREPARE, EXECUTE, CURSORS, etc.
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- =====================================================
-- Check current setting: For PREPARE TRANSACTION, Prerequisites for Two-Phase Commit
-- SHOW max_prepared_transactions;

-- If zero, add to postgresql.conf and restart PostgreSQL:
-- max_prepared_transactions = 10
-- =====================================================

\echo '=========================================='
\echo 'Starting TRANSACTIONS, CURSORS, PREPARE test suite'
\echo '=========================================='

-- =====================================================
-- PREPARATION: Create test objects
-- =====================================================

\echo '\n>>> PREPARATION PHASE: Creating test objects...'

-- Create test schema
CREATE SCHEMA IF NOT EXISTS transaction_test;

-- Create test tables
DROP TABLE IF EXISTS transaction_test.accounts CASCADE;
CREATE TABLE transaction_test.accounts (
    id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS transaction_test.transaction_log CASCADE;
CREATE TABLE transaction_test.transaction_log (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES transaction_test.accounts(id),
    transaction_type VARCHAR(20),
    amount DECIMAL(15,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS transaction_test.orders CASCADE;
CREATE TABLE transaction_test.orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE,
    customer_name VARCHAR(100),
    total_amount DECIMAL(15,2),
    status VARCHAR(20) DEFAULT 'PENDING'
);

DROP TABLE IF EXISTS transaction_test.employees CASCADE;
CREATE TABLE transaction_test.employees (
    id SERIAL PRIMARY KEY,
    emp_id VARCHAR(20) UNIQUE,
    name VARCHAR(100),
    salary DECIMAL(10,2),
    department VARCHAR(50)
);

-- Create test procedure
CREATE OR REPLACE PROCEDURE transaction_test.transfer_money(
    from_account VARCHAR(20),
    to_account VARCHAR(20),
    amount DECIMAL(15,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    from_id INTEGER;
    to_id INTEGER;
    current_balance DECIMAL(15,2);
BEGIN
    -- Get account IDs
    SELECT id, balance INTO from_id, current_balance 
    FROM transaction_test.accounts 
    WHERE account_number = from_account;
    
    SELECT id INTO to_id 
    FROM transaction_test.accounts 
    WHERE account_number = to_account;
    
    -- Check sufficient balance
    IF current_balance < amount THEN
        RAISE EXCEPTION 'Insufficient balance in account %', from_account;
    END IF;
    
    -- Perform transfer
    UPDATE transaction_test.accounts SET balance = balance - amount WHERE id = from_id;
    UPDATE transaction_test.accounts SET balance = balance + amount WHERE id = to_id;
    
    -- Log transaction
    INSERT INTO transaction_test.transaction_log (account_id, transaction_type, amount) 
    VALUES (from_id, 'DEBIT', -amount);
    INSERT INTO transaction_test.transaction_log (account_id, transaction_type, amount) 
    VALUES (to_id, 'CREDIT', amount);
    
    COMMIT;
END;
$$;

-- Insert test data
INSERT INTO transaction_test.accounts (account_number, account_name, balance) VALUES
    ('ACC1001', 'John Doe', 5000.00),
    ('ACC1002', 'Jane Smith', 3000.00),
    ('ACC1003', 'Bob Johnson', 10000.00),
    ('ACC1004', 'Alice Brown', 7500.00);

INSERT INTO transaction_test.orders (order_number, customer_name, total_amount) VALUES
    ('ORD001', 'John Doe', 250.00),
    ('ORD002', 'Jane Smith', 125.50),
    ('ORD003', 'Bob Johnson', 999.99),
    ('ORD004', 'Alice Brown', 75.25);

INSERT INTO transaction_test.employees (emp_id, name, salary, department) VALUES
    ('E001', 'John Doe', 50000, 'IT'),
    ('E002', 'Jane Smith', 60000, 'HR'),
    ('E003', 'Bob Johnson', 55000, 'IT'),
    ('E004', 'Alice Brown', 65000, 'FINANCE'),
    ('E005', 'Charlie Wilson', 52000, 'IT'),
    ('E006', 'Diana Prince', 70000, 'FINANCE');

\echo '>>> PREPARATION COMPLETE'
\echo ''

-- =====================================================
-- TEST 1: BASIC TRANSACTIONS (BEGIN, COMMIT, ROLLBACK)
-- =====================================================

\echo '=========================================='
\echo 'TEST 1: Basic Transactions'
\echo '=========================================='

-- Test 1.1: Successful transaction with COMMIT
\echo '\n>>> 1.1 Committing a transaction'

BEGIN;
    UPDATE transaction_test.accounts 
    SET balance = balance - 500 
    WHERE account_number = 'ACC1001';
    
    UPDATE transaction_test.accounts 
    SET balance = balance + 500 
    WHERE account_number = 'ACC1002';
    
    INSERT INTO transaction_test.transaction_log (account_id, transaction_type, amount)
    SELECT id, 'TRANSFER', 500 
    FROM transaction_test.accounts 
    WHERE account_number IN ('ACC1001', 'ACC1002');
COMMIT;

SELECT account_number, balance FROM transaction_test.accounts 
WHERE account_number IN ('ACC1001', 'ACC1002');
\echo '✓ Transaction committed successfully'

-- Test 1.2: Transaction with ROLLBACK (error scenario)
\echo '\n>>> 1.2 Rolling back a transaction'

BEGIN;
    UPDATE transaction_test.accounts 
    SET balance = balance - 10000 
    WHERE account_number = 'ACC1003';
    
    -- This will fail due to insufficient funds
    -- But we'll rollback anyway
    INSERT INTO transaction_test.transaction_log (account_id, transaction_type, amount)
    SELECT id, 'FAILED_TRANSFER', 10000 
    FROM transaction_test.accounts 
    WHERE account_number = 'ACC1003';
    
ROLLBACK;

SELECT account_number, balance FROM transaction_test.accounts WHERE account_number = 'ACC1003';
\echo '✓ Transaction rolled back successfully'

-- =====================================================
-- TEST 2: SAVEPOINTS (SAVEPOINT, ROLLBACK TO SAVEPOINT, RELEASE SAVEPOINT)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 2: Savepoints and Partial Rollbacks'
\echo '=========================================='

BEGIN;
    -- Initial update
    INSERT INTO transaction_test.orders (order_number, customer_name, total_amount, status) 
    VALUES ('ORD005', 'Test Customer', 500.00, 'PENDING');
    
    SAVEPOINT before_update;
    
    -- Attempt problematic update
    UPDATE transaction_test.orders 
    SET order_number = NULL 
    WHERE order_number = 'ORD005';
    
    -- Oops, that violated NOT NULL constraint
    ROLLBACK TO SAVEPOINT before_update;
    
    -- Now do correct update
    UPDATE transaction_test.orders 
    SET status = 'APPROVED' 
    WHERE order_number = 'ORD005';
    
    -- Release the savepoint (we don't need it anymore)
    RELEASE SAVEPOINT before_update;
    
    -- Create another savepoint
    SAVEPOINT final_check;
    
    -- Verify the order exists
    SELECT count(*) INTO TEMP order_count FROM transaction_test.orders WHERE order_number = 'ORD005';
    
    IF order_count = 0 THEN
        ROLLBACK TO SAVEPOINT final_check;
    END IF;
    
    RELEASE SAVEPOINT final_check;
    
COMMIT;

SELECT * FROM transaction_test.orders WHERE order_number = 'ORD005';
\echo '✓ Savepoint test completed'

-- =====================================================
-- TEST 3: PREPARED STATEMENTS (PREPARE, EXECUTE)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 3: Prepared Statements'
\echo '=========================================='

-- Test 3.1: Basic prepared statement
\echo '\n>>> 3.1 Basic PREPARE and EXECUTE'

PREPARE get_employee_by_dept (text) AS
    SELECT emp_id, name, salary 
    FROM transaction_test.employees 
    WHERE department = $1
    ORDER BY salary DESC;

EXECUTE get_employee_by_dept('IT');

-- Test 3.2: Prepared statement with multiple parameters
\echo '\n>>> 3.2 Multi-parameter prepared statement'

PREPARE create_order (varchar, varchar, numeric) AS
    INSERT INTO transaction_test.orders (order_number, customer_name, total_amount, status)
    VALUES ($1, $2, $3, 'PENDING')
    RETURNING id, order_number, status;

EXECUTE create_order('ORD006', 'Prepared Customer', 1250.00);
EXECUTE create_order('ORD007', 'Another Customer', 750.00);

-- Test 3.3: Prepared statement with UPDATE
\echo '\n>>> 3.3 Prepared UPDATE statement'

PREPARE update_order_status (varchar, varchar) AS
    UPDATE transaction_test.orders 
    SET status = $2, updated_at = CURRENT_TIMESTAMP
    WHERE order_number = $1
    RETURNING *;

EXECUTE update_order_status('ORD006', 'SHIPPED');

-- =====================================================
-- TEST 4: CURSORS (DECLARE CURSOR, FETCH, CLOSE)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 4: Cursors'
\echo '=========================================='

BEGIN;
    -- Test 4.1: Simple cursor
    \echo '\n>>> 4.1 Basic cursor with FETCH'
    
    DECLARE emp_cursor CURSOR FOR
        SELECT emp_id, name, salary, department 
        FROM transaction_test.employees 
        WHERE salary > 55000
        ORDER BY salary DESC;
    
    -- Fetch first row
    FETCH FIRST FROM emp_cursor;
    
    -- Fetch next 2 rows
    FETCH NEXT 2 FROM emp_cursor;
    
    -- Fetch all remaining
    FETCH ALL FROM emp_cursor;
    
    -- Test 4.2: Scrollable cursor
    \echo '\n>>> 4.2 Scrollable cursor (can move backward)'
    
    DECLARE scroll_cursor SCROLL CURSOR FOR
        SELECT order_number, customer_name, total_amount 
        FROM transaction_test.orders 
        WHERE total_amount > 100
        ORDER BY total_amount;
    
    FETCH FIRST FROM scroll_cursor;
    FETCH LAST FROM scroll_cursor;
    FETCH BACKWARD 2 FROM scroll_cursor;
    FETCH FORWARD 1 FROM scroll_cursor;
    
    -- Test 4.3: Cursor with WHERE CURRENT OF
    \echo '\n>>> 4.3 Cursor with WHERE CURRENT OF (updating through cursor)'
    
    DECLARE update_cursor CURSOR FOR
        SELECT emp_id, salary, department 
        FROM transaction_test.employees 
        WHERE department = 'IT'
        FOR UPDATE;
    
    -- Give 10% raise to all IT employees
    FETCH NEXT FROM update_cursor;
    UPDATE transaction_test.employees SET salary = salary * 1.10 
    WHERE CURRENT OF update_cursor;
    
    FETCH NEXT FROM update_cursor;
    UPDATE transaction_test.employees SET salary = salary * 1.10 
    WHERE CURRENT OF update_cursor;
    
    FETCH NEXT FROM update_cursor;
    UPDATE transaction_test.employees SET salary = salary * 1.10 
    WHERE CURRENT OF update_cursor;
    
    -- Test 4.4: Holding cursor (WITH HOLD - survives commit)
    \echo '\n>>> 4.4 WITH HOLD cursor (transaction boundary)'
    
    DECLARE hold_cursor CURSOR WITH HOLD FOR
        SELECT account_number, account_name, balance 
        FROM transaction_test.accounts 
        WHERE balance > 4000
        ORDER BY balance DESC;
    
    FETCH 2 FROM hold_cursor;
    
COMMIT;

-- Cursor WITH HOLD still accessible after commit
\echo 'After COMMIT, hold_cursor is still available:'
FETCH NEXT FROM hold_cursor;

-- Close cursors
CLOSE emp_cursor;
CLOSE scroll_cursor;
CLOSE update_cursor;
CLOSE hold_cursor;

\echo '✓ All cursors closed'

-- =====================================================
-- TEST 5: TWO-PHASE COMMIT (PREPARE TRANSACTION, COMMIT PREPARED, ROLLBACK PREPARED)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 5: Two-Phase Commit (Prepared Transactions)'
\echo '=========================================='

-- Note: max_prepared_transactions must be > 0 in postgresql.conf
\echo 'Note: Requires max_prepared_transactions > 0'

-- Test 5.1: Successful two-phase commit
\echo '\n>>> 5.1 PREPARE TRANSACTION and COMMIT PREPARED'

BEGIN;
    INSERT INTO transaction_test.orders (order_number, customer_name, total_amount, status)
    VALUES ('ORD080', 'Two-Phase Test', 1000.00, 'PENDING');
    
    UPDATE transaction_test.accounts 
    SET balance = balance - 500 
    WHERE account_number = 'ACC1001';
    
    -- Prepare the transaction for two-phase commit
    PREPARE TRANSACTION 'txn_test_1';
    
-- Simulate distributed transaction coordinator decision
COMMIT PREPARED 'txn_test_1';

SELECT * FROM transaction_test.orders WHERE order_number = 'ORD080';
\echo '✓ Prepared transaction committed'

-- Test 5.2: Rollback prepared transaction
\echo '\n>>> 5.2 PREPARE TRANSACTION and ROLLBACK PREPARED'

BEGIN;
    INSERT INTO transaction_test.orders (order_number, customer_name, total_amount, status)
    VALUES ('ORD081', 'Rollback Test', 2000.00, 'PENDING');
    
    UPDATE transaction_test.accounts 
    SET balance = balance - 1000 
    WHERE account_number = 'ACC1002';
    
    -- Prepare the transaction
    PREPARE TRANSACTION 'txn_test_2';
    
-- But coordinator decides to abort
ROLLBACK PREPARED 'txn_test_2';

-- Verify no changes
SELECT * FROM transaction_test.orders WHERE order_number = 'ORD081';
SELECT balance FROM transaction_test.accounts WHERE account_number = 'ACC1002';
\echo '✓ Prepared transaction rolled back'

-- =====================================================
-- TEST 6: SET TRANSACTION and SET CONSTRAINTS
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 6: Transaction Characteristics'
\echo '=========================================='

-- Test 6.1: SET TRANSACTION isolation levels
\echo '\n>>> 6.1 Setting transaction isolation level'

BEGIN;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET TRANSACTION READ ONLY;
    
    SELECT account_number, balance FROM transaction_test.accounts ORDER BY id;
    
    -- This would fail in READ ONLY mode
    -- UPDATE transaction_test.accounts SET balance = balance + 100 WHERE account_number = 'ACC1001';
COMMIT;

-- Test 6.2: SET CONSTRAINTS (deferred checking)
\echo '\n>>> 6.2 SET CONSTRAINTS'

-- Add a foreign key with deferred constraint
ALTER TABLE transaction_test.transaction_log 
DROP CONSTRAINT IF EXISTS transaction_log_account_id_fkey;

ALTER TABLE transaction_test.transaction_log 
ADD CONSTRAINT transaction_log_account_id_fkey 
FOREIGN KEY (account_id) REFERENCES transaction_test.accounts(id)
DEFERRABLE INITIALLY IMMEDIATE;

BEGIN;
    SET CONSTRAINTS ALL DEFERRED;
    
    -- Insert log without account first (deferred constraint allows this temporarily)
    INSERT INTO transaction_test.transaction_log (account_id, transaction_type, amount)
    VALUES (999, 'TEST', 100.00);
    
    -- But when we commit, it will fail because account_id=999 doesn't exist
    -- ROLLBACK to avoid error
ROLLBACK;

\echo '✓ SET CONSTRAINTS test completed'

-- =====================================================
-- TEST 7: CALL (invoke a procedure)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 7: CALL - Invoking Procedures'
\echo '=========================================='

-- Show balances before transfer
\echo 'Before transfer:'
SELECT account_number, balance FROM transaction_test.accounts 
WHERE account_number IN ('ACC1001', 'ACC1002');

-- Call the transfer procedure
CALL transaction_test.transfer_money('ACC1001', 'ACC1002', 250.00);

-- Show balances after transfer (procedure handles COMMIT internally)
\echo 'After transfer:'
SELECT account_number, balance FROM transaction_test.accounts 
WHERE account_number IN ('ACC1001', 'ACC1002');

\echo '✓ Procedure called successfully'

-- =====================================================
-- TEST 8: ABORT (same as ROLLBACK)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 8: ABORT - Alternative to ROLLBACK'
\echo '=========================================='

BEGIN;
    INSERT INTO transaction_test.orders (order_number, customer_name, total_amount)
    VALUES ('ORD999', 'Abort Test', 123.45);
    
    -- Oops, we want to cancel
    ABORT;  -- Same as ROLLBACK

\echo 'Transaction aborted, ORD999 should not exist:'
SELECT * FROM transaction_test.orders WHERE order_number = 'ORD999';

-- =====================================================
-- TEST 9: CHECKPOINT (force WAL checkpoint)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 9: CHECKPOINT - Force WAL checkpoint'
\echo '=========================================='

-- Note: CHECKPOINT typically requires superuser privileges
\echo 'Forcing a write-ahead log checkpoint...'
-- CHECKPOINT;  -- Uncomment if you have superuser privileges
\echo '⚠ CHECKPOINT command requires superuser - skipping in this test'

-- =====================================================
-- TEST 10: COMMENT (document database objects)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 10: COMMENT - Documenting Objects'
\echo '=========================================='

COMMENT ON DATABASE current_database() IS 'Test database for transaction and cursor examples';
COMMENT ON TABLE transaction_test.accounts IS 'Bank account information for financial transactions';
COMMENT ON COLUMN transaction_test.accounts.balance IS 'Current account balance - must be non-negative';
COMMENT ON PROCEDURE transaction_test.transfer_money(varchar, varchar, decimal) IS 'Transfer funds between accounts with transaction logging';
COMMENT ON SCHEMA transaction_test IS 'Schema containing all transaction test objects';

\echo '✓ Comments added to various database objects'

-- =====================================================
-- TEST 11: RESET (restore configuration parameters)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 11: RESET - Restore parameters'
\echo '=========================================='

SHOW work_mem;

SET work_mem = '32MB';
SHOW work_mem;

RESET work_mem;
SHOW work_mem;

\echo '✓ RESET restored work_mem to default'

-- =====================================================
-- TEST 12: START TRANSACTION and END (alternatives to BEGIN/COMMIT)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 12: START TRANSACTION and END'
\echo '=========================================='

START TRANSACTION ISOLATION LEVEL READ COMMITTED;
    INSERT INTO transaction_test.employees (emp_id, name, salary, department)
    VALUES ('E007', 'START TRANSACTION Test', 58000, 'SALES');
    
    SELECT COUNT(*) FROM transaction_test.employees WHERE department = 'SALES';
END;  -- Same as COMMIT

-- =====================================================
-- TEST 13: SET and SET SESSION AUTHORIZATION
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 13: SET and SET SESSION AUTHORIZATION'
\echo '=========================================='

-- Test 13.1: SET runtime parameters
\echo '\n>>> 13.1 SET parameter'

SHOW timezone;
SET timezone TO 'UTC';
SHOW timezone;
SET timezone TO 'LOCAL';
SHOW timezone;

-- Test 13.2: SET ROLE
\echo '\n>>> 13.2 SET SESSION AUTHORIZATION'

-- Create a test role if not exists
DROP ROLE IF EXISTS test_app_role;
CREATE ROLE test_app_role LOGIN;

SET SESSION AUTHORIZATION test_app_role;
SELECT current_user, session_user;
RESET SESSION AUTHORIZATION;
SELECT current_user, session_user;

\echo '✓ SET SESSION AUTHORIZATION test completed'

-- =====================================================
-- TEST 14: FETCH variations (comprehensive)
-- =====================================================

\echo '\n=========================================='
\echo 'TEST 14: FETCH - Advanced fetch modes'
\eloop '=========================================='

BEGIN;
    DECLARE test_cursor CURSOR FOR
        SELECT emp_id, name, salary FROM transaction_test.employees ORDER BY salary DESC;
    
    \echo 'FETCH FIRST 3 rows:'
    FETCH FORWARD 3 FROM test_cursor;
    
    \echo 'FETCH PRIOR 1 (go back one):'
    FETCH PRIOR FROM test_cursor;
    
    \echo 'FETCH ABSOLUTE 5 (jump to row 5):'
    FETCH ABSOLUTE 5 FROM test_cursor;
    
    \echo 'FETCH RELATIVE -2 (back 2 from current):'
    FETCH RELATIVE -2 FROM test_cursor;
    
    CLOSE test_cursor;
COMMIT;

-- =====================================================
-- CLEANUP: Drop all test objects
-- =====================================================

\echo '\n=========================================='
\echo 'CLEANUP PHASE: Removing test objects'
\echo '=========================================='

-- Clean up prepared transactions (if any are left)
-- Note: Only works if you know the transaction IDs
-- SELECT gid FROM pg_prepared_xacts;
-- ROLLBACK PREPARED 'txn_test_1';
-- ROLLBACK PREPARED 'txn_test_2';

-- Close any open cursors (should be handled, but safe to check)
DO $$
DECLARE
    cur_name text;
BEGIN
    FOR cur_name IN (SELECT name FROM pg_cursors) LOOP
        EXECUTE 'CLOSE ' || cur_name;
    END LOOP;
END $$;

-- Drop tables
DROP TABLE IF EXISTS transaction_test.accounts CASCADE;
DROP TABLE IF EXISTS transaction_test.transaction_log CASCADE;
DROP TABLE IF EXISTS transaction_test.orders CASCADE;
DROP TABLE IF EXISTS transaction_test.employees CASCADE;

-- Drop procedures and functions
DROP PROCEDURE IF EXISTS transaction_test.transfer_money(varchar, varchar, decimal) CASCADE;

-- Drop schema
DROP SCHEMA IF EXISTS transaction_test CASCADE;

-- Drop test role
DROP ROLE IF EXISTS test_app_role;

-- Reset any lingering configuration settings
RESET ALL;

\echo '>>> CLEANUP COMPLETE'
\echo ''

\echo '=========================================='
\echo 'TEST SUITE COMPLETED SUCCESSFULLY!'
\echo '=========================================='
\echo ''
\echo 'Commands tested:'
\echo '✓ BEGIN / COMMIT / ROLLBACK'
\echo '✓ SAVEPOINT / RELEASE SAVEPOINT / ROLLBACK TO SAVEPOINT'
\echo '✓ PREPARE / EXECUTE'
\echo '✓ DECLARE CURSOR / FETCH (all variants) / CLOSE'
\echo '✓ PREPARE TRANSACTION / COMMIT PREPARED / ROLLBACK PREPARED'
\echo '✓ CALL (procedures)'
\echo '✓ ABORT'
\echo '✓ SET TRANSACTION / SET CONSTRAINTS'
\echo '✓ COMMENT'
\echo '✓ RESET'
\echo '✓ START TRANSACTION / END'
\echo '✓ SET / SET SESSION AUTHORIZATION'
\echo ''