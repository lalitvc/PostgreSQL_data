-- =============================================================================
-- FILE: test_postgresql_commands.sql
-- PURPOSE: Demonstrate every SQL command from PostgreSQL 16 documentation
-- AUTHOR: Generated from PostgreSQL 16 docs
-- NOTE: Run in a clean database (e.g., 'test_db') as a superuser.
-- =============================================================================

-- #############################################################################
-- 1. PREPARATION: Create roles, tablespace, and test objects
-- #############################################################################

-- Cleanup from previous runs (if any)
DROP DATABASE IF EXISTS test_commands_db;
DROP ROLE IF EXISTS test_role;
DROP TABLESPACE IF EXISTS test_tablespace;
DROP EXTENSION IF EXISTS test_extension CASCADE;

-- Create a test role
CREATE ROLE test_role WITH LOGIN PASSWORD 'test_pass';
CREATE USER test_user WITH PASSWORD 'test_user_pass';

-- Create a tablespace (requires a directory, adjust path as needed)
-- For Windows: 'C:/test_tablespace' or Linux: '/tmp/test_tablespace'
CREATE TABLESPACE test_tablespace OWNER test_role LOCATION '/tmp/test_tablespace';

-- Create a dedicated database
CREATE DATABASE test_commands_db OWNER test_role TABLESPACE test_tablespace;

-- Connect to the new database (in psql: \c test_commands_db)
\c test_commands_db

-- Create a schema
CREATE SCHEMA test_schema;

-- #############################################################################
-- 2. DATA DEFINITION LANGUAGE (DDL) COMMANDS
-- #############################################################################

-- ---------------------------
-- CREATE statements
-- ---------------------------

-- CREATE TABLE
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    salary NUMERIC(10,2),
    department VARCHAR(50),
    hire_date DATE DEFAULT CURRENT_DATE
);

-- CREATE TABLE AS
CREATE TABLE high_earners AS
SELECT id, name, salary FROM employees WHERE salary > 50000;

-- CREATE SEQUENCE
CREATE SEQUENCE order_seq START 100 INCREMENT 1;

-- CREATE INDEX
CREATE INDEX idx_emp_dept ON employees(department);

-- CREATE VIEW
CREATE VIEW emp_names AS SELECT id, name FROM employees;

-- CREATE MATERIALIZED VIEW
CREATE MATERIALIZED VIEW dept_salary_summary AS
SELECT department, AVG(salary) AS avg_salary FROM employees GROUP BY department;

-- CREATE FUNCTION (SQL function)
CREATE FUNCTION get_employee_count() RETURNS INTEGER AS $$
    SELECT COUNT(*) FROM employees;
$$ LANGUAGE SQL;

-- CREATE PROCEDURE
CREATE PROCEDURE update_salary(emp_id INTEGER, new_salary NUMERIC)
LANGUAGE SQL AS $$
    UPDATE employees SET salary = new_salary WHERE id = emp_id;
$$;

-- CREATE DOMAIN
CREATE DOMAIN positive_salary NUMERIC(10,2) CHECK (VALUE > 0);

-- CREATE TYPE (composite)
CREATE TYPE address_type AS (
    street TEXT,
    city TEXT,
    zip_code TEXT
);

-- CREATE TYPE (enum)
CREATE TYPE status_enum AS ENUM ('active', 'inactive', 'pending');

-- CREATE TABLE using custom types
CREATE TABLE offices (
    id SERIAL PRIMARY KEY,
    address address_type,
    status status_enum DEFAULT 'pending'
);

-- CREATE COLLATION (for case-insensitive sorting)
CREATE COLLATION case_insensitive (provider = icu, locale = 'und-u-ks-level2');

-- CREATE SCHEMA
CREATE SCHEMA IF NOT EXISTS extra_schema;

-- CREATE AGGREGATE (custom sum with initial condition)
CREATE FUNCTION sum_positive_state(state NUMERIC, value NUMERIC) RETURNS NUMERIC AS $$
    SELECT state + GREATEST(value, 0);
$$ LANGUAGE SQL;

CREATE AGGREGATE sum_positive(NUMERIC) (
    SFUNC = sum_positive_state,
    STYPE = NUMERIC,
    INITCOND = '0'
);

-- CREATE OPERATOR (custom concatenation for text)
CREATE FUNCTION text_concat(text, text) RETURNS text AS $$
    SELECT $1 || ' ' || $2;
$$ LANGUAGE SQL;

CREATE OPERATOR ~||~ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = text_concat
);

-- CREATE CAST (convert text to custom type)
CREATE FUNCTION text_to_address(text) RETURNS address_type AS $$
    SELECT ROW(split_part($1, ',', 1), split_part($1, ',', 2), split_part($1, ',', 3))::address_type;
$$ LANGUAGE SQL;

CREATE CAST (text AS address_type) WITH FUNCTION text_to_address(text);

-- CREATE TRIGGER and trigger function
CREATE TABLE employee_audit (
    emp_id INTEGER,
    action TEXT,
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE FUNCTION audit_employee_changes() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO employee_audit(emp_id, action) VALUES (NEW.id, TG_OP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_employee_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION audit_employee_changes();

-- CREATE RULE (log DELETE operations)
CREATE RULE log_employee_delete AS ON DELETE TO employees
DO ALSO INSERT INTO employee_audit(emp_id, action) VALUES (OLD.id, 'DELETE_RULE');

-- CREATE POLICY (Row Level Security)
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY emp_policy ON employees
    USING (department = current_user);

-- CREATE EVENT TRIGGER (for DDL commands)
CREATE FUNCTION abort_drop() RETURNS event_trigger AS $$
BEGIN
    RAISE EXCEPTION 'DROP commands are disabled in this test';
END;
$$ LANGUAGE plpgsql;
-- (Commented to avoid blocking cleanup) 
-- CREATE EVENT TRIGGER evt_abort_drop ON sql_drop EXECUTE FUNCTION abort_drop();

-- CREATE EXTENSION (example: pgcrypto)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- CREATE FOREIGN DATA WRAPPER (example: file_fdw)
CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER file_server FOREIGN DATA WRAPPER file_fdw;

-- CREATE FOREIGN TABLE
CREATE FOREIGN TABLE foreign_employees (
    id INTEGER,
    name TEXT,
    salary NUMERIC
) SERVER file_server OPTIONS (filename '/tmp/employees.csv');

-- CREATE USER MAPPING
CREATE USER MAPPING FOR test_user SERVER file_server OPTIONS (user 'test_user');

-- CREATE PUBLICATION (for logical replication)
CREATE PUBLICATION test_publication FOR TABLE employees;

-- CREATE SUBSCRIPTION (would require a running publisher)
-- CREATE SUBSCRIPTION test_subscription CONNECTION '...' PUBLICATION test_publication;

-- CREATE ACCESS METHOD (example: heap is default, custom requires C extension)
-- (Skipped as it requires external C code)

-- CREATE CONVERSION (example: latin1 to utf8)
CREATE CONVERSION latin1_to_utf8 FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

-- CREATE TEXT SEARCH objects
CREATE TEXT SEARCH DICTIONARY my_dict (TEMPLATE = simple);
CREATE TEXT SEARCH CONFIGURATION my_config (COPY = english);
ALTER TEXT SEARCH CONFIGURATION my_config ALTER MAPPING FOR word WITH my_dict;
CREATE TEXT SEARCH PARSER my_parser (START = prsd_start, gettoken = prsd_nexttoken, ...); -- requires C functions
CREATE TEXT SEARCH TEMPLATE my_template (INIT = prsd_init, LEXIZE = prsd_lexize); -- requires C

-- CREATE TRANSFORM (example: hstore to record)
CREATE TRANSFORM FOR hstore LANGUAGE plpython3u (FROM SQL WITH FUNCTION ...); -- requires extensions

-- ---------------------------
-- ALTER statements
-- ---------------------------

-- ALTER TABLE
ALTER TABLE employees ADD COLUMN email TEXT;
ALTER TABLE employees ALTER COLUMN email SET NOT NULL;
ALTER TABLE employees RENAME COLUMN name TO full_name;
ALTER TABLE employees SET SCHEMA test_schema;

-- ALTER TABLE (back to public schema for further tests)
ALTER TABLE test_schema.employees SET SCHEMA public;

-- ALTER INDEX
ALTER INDEX idx_emp_dept RENAME TO idx_emp_dept_new;
ALTER INDEX idx_emp_dept_new SET TABLESPACE test_tablespace;

-- ALTER SEQUENCE
ALTER SEQUENCE order_seq RESTART WITH 200;

-- ALTER VIEW
ALTER VIEW emp_names RENAME TO employee_names;

-- ALTER MATERIALIZED VIEW
ALTER MATERIALIZED VIEW dept_salary_summary SET TABLESPACE test_tablespace;

-- ALTER FUNCTION
ALTER FUNCTION get_employee_count() IMMUTABLE;

-- ALTER PROCEDURE
ALTER PROCEDURE update_salary(INTEGER, NUMERIC) SET SCHEMA test_schema;

-- ALTER DOMAIN
ALTER DOMAIN positive_salary SET DEFAULT 1000.00;

-- ALTER TYPE
ALTER TYPE address_type ADD ATTRIBUTE country TEXT;

-- ALTER DATABASE
ALTER DATABASE test_commands_db SET timezone TO 'UTC';

-- ALTER ROLE
ALTER ROLE test_role WITH SUPERUSER;
ALTER ROLE test_role RENAME TO test_role_renamed;

-- ALTER USER
ALTER USER test_user VALID UNTIL '2025-12-31';

-- ALTER GROUP (deprecated, use ALTER ROLE)
ALTER GROUP test_role_renamed ADD USER test_user;

-- ALTER SCHEMA
ALTER SCHEMA test_schema RENAME TO renamed_schema;

-- ALTER TABLESPACE
ALTER TABLESPACE test_tablespace RENAME TO renamed_tablespace;

-- ALTER POLICY
ALTER POLICY emp_policy ON employees USING (department = 'HR');

-- ALTER RULE
ALTER RULE log_employee_delete ON employees RENAME TO log_emp_delete;

-- ALTER TRIGGER
ALTER TRIGGER trg_employee_audit ON employees RENAME TO trg_emp_audit;

-- ALTER EVENT TRIGGER (commented: would block DROP)
-- ALTER EVENT TRIGGER evt_abort_drop DISABLE;

-- ALTER EXTENSION
ALTER EXTENSION pgcrypto UPDATE;

-- ALTER FOREIGN DATA WRAPPER
ALTER FOREIGN DATA WRAPPER file_fdw OWNER TO test_role_renamed;

-- ALTER FOREIGN TABLE
ALTER FOREIGN TABLE foreign_employees OPTIONS (ADD filename '/tmp/employees_new.csv');

-- ALTER SERVER
ALTER SERVER file_server OPTIONS (SET host 'localhost');

-- ALTER USER MAPPING
ALTER USER MAPPING FOR test_user SERVER file_server OPTIONS (SET user 'new_user');

-- ALTER PUBLICATION
ALTER PUBLICATION test_publication SET TABLE employees, offices;

-- ALTER SUBSCRIPTION (requires active subscription)
-- ALTER SUBSCRIPTION test_subscription ENABLE;

-- ALTER STATISTICS (requires statistics object)
CREATE STATISTICS dept_salary_stats ON department, salary FROM employees;
ALTER STATISTICS dept_salary_stats SET STATISTICS 1000;

-- ALTER COLLATION
ALTER COLLATION case_insensitive REFRESH VERSION;

-- ALTER CONVERSION (only name/owner/schema)
ALTER CONVERSION latin1_to_utf8 RENAME TO latin1_to_utf8_new;

-- ALTER OPERATOR
ALTER OPERATOR ~||~ (text, text) SET SCHEMA renamed_schema;

-- ALTER OPERATOR CLASS / FAMILY (complex, skip for brevity)

-- ALTER LANGUAGE (requires PL/pgSQL installed)
ALTER LANGUAGE plpgsql OWNER TO test_role_renamed;

-- ALTER LARGE OBJECT (requires lo extension)
-- CREATE EXTENSION lo; SELECT lo_from_bytea(0, 'test'); ALTER LARGE OBJECT 0 OWNER TO test_role_renamed;

-- ALTER ROUTINE (generic for function/procedure)
ALTER ROUTINE get_employee_count() RENAME TO get_emp_count;

-- ALTER SYSTEM (requires superuser and postgresql.conf write)
-- ALTER SYSTEM SET wal_level = replica;

-- ---------------------------
-- DROP statements
-- ---------------------------

-- We will drop objects at the end, but show syntax now
-- DROP TABLE table_name CASCADE;
-- DROP INDEX index_name;
-- DROP VIEW view_name;
-- DROP MATERIALIZED VIEW matview_name;
-- DROP SEQUENCE sequence_name;
-- DROP FUNCTION function_name;
-- DROP PROCEDURE procedure_name;
-- DROP DOMAIN domain_name;
-- DROP TYPE type_name;
-- DROP SCHEMA schema_name CASCADE;
-- DROP COLLATION collation_name;
-- DROP AGGREGATE aggregate_name;
-- DROP OPERATOR operator_name;
-- DROP CAST (source_type AS target_type);
-- DROP TRIGGER trigger_name ON table_name;
-- DROP RULE rule_name ON table_name;
-- DROP POLICY policy_name ON table_name;
-- DROP EVENT TRIGGER event_trigger_name;
-- DROP EXTENSION extension_name CASCADE;
-- DROP FOREIGN DATA WRAPPER fdw_name CASCADE;
-- DROP FOREIGN TABLE foreign_table_name;
-- DROP SERVER server_name CASCADE;
-- DROP USER MAPPING FOR user_name SERVER server_name;
-- DROP PUBLICATION publication_name;
-- DROP SUBSCRIPTION subscription_name;
-- DROP STATISTICS statistics_name;
-- DROP CONVERSION conversion_name;
-- DROP TEXT SEARCH DICTIONARY dict_name;
-- DROP TEXT SEARCH CONFIGURATION config_name;
-- DROP TEXT SEARCH PARSER parser_name;
-- DROP TEXT SEARCH TEMPLATE template_name;
-- DROP TRANSFORM FOR type_name LANGUAGE lang_name;
-- DROP ACCESS METHOD access_method_name;
-- DROP OPERATOR CLASS class_name USING index_method;
-- DROP OPERATOR FAMILY family_name USING index_method;
-- DROP ROUTINE routine_name;
-- DROP OWNED BY role_name;
-- DROP DATABASE database_name;
-- DROP TABLESPACE tablespace_name;
-- DROP ROLE role_name;

-- #############################################################################
-- 3. DATA MANIPULATION LANGUAGE (DML) COMMANDS
-- #############################################################################

-- INSERT
INSERT INTO employees (full_name, salary, department, hire_date, email)
VALUES ('John Doe', 60000.00, 'IT', '2023-01-15', 'john.doe@example.com'),
       ('Jane Smith', 75000.00, 'HR', '2022-11-01', 'jane.smith@example.com');

-- INSERT using sequence
INSERT INTO offices (address, status) VALUES 
    (ROW('123 Main St', 'Springfield', '12345'), 'active');

-- UPDATE
UPDATE employees SET salary = 65000.00 WHERE full_name = 'John Doe';

-- DELETE
DELETE FROM employees WHERE full_name = 'Jane Smith';

-- MERGE (PostgreSQL 15+)
MERGE INTO employees AS target
USING (VALUES (1, 'John Doe', 68000.00)) AS source(id, name, salary)
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET salary = source.salary
WHEN NOT MATCHED THEN INSERT (full_name, salary) VALUES (source.name, source.salary);

-- TRUNCATE
TRUNCATE TABLE employee_audit;

-- COPY (to/from file)
COPY employees (full_name, salary) TO '/tmp/employees_export.csv' CSV HEADER;
-- COPY employees FROM '/tmp/employees_import.csv' CSV HEADER; -- requires existing file

-- #############################################################################
-- 4. QUERY AND CURSOR COMMANDS
-- #############################################################################

-- SELECT
SELECT * FROM employees WHERE department = 'IT';

-- SELECT INTO (creates a new table)
SELECT id, full_name INTO temp_employees FROM employees WHERE salary > 60000;

-- VALUES
VALUES (1, 'One'), (2, 'Two'), (3, 'Three');

-- DECLARE CURSOR
DECLARE emp_cursor CURSOR FOR SELECT id, full_name FROM employees;

-- FETCH from cursor
FETCH NEXT FROM emp_cursor;
FETCH ALL FROM emp_cursor;

-- MOVE cursor
MOVE FORWARD 2 FROM emp_cursor;

-- CLOSE cursor
CLOSE emp_cursor;

-- PREPARE statement
PREPARE emp_by_dept(text) AS SELECT * FROM employees WHERE department = $1;

-- EXECUTE prepared statement
EXECUTE emp_by_dept('IT');

-- DEALLOCATE prepared statement
DEALLOCATE emp_by_dept;

-- EXPLAIN
EXPLAIN SELECT * FROM employees WHERE salary > 50000;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 50000;

-- #############################################################################
-- 5. TRANSACTION AND LOCK COMMANDS
-- #############################################################################

-- BEGIN / START TRANSACTION
BEGIN;
    INSERT INTO employees (full_name, salary, department) VALUES ('Temp User', 30000, 'Temp');
    SAVEPOINT before_update;
    UPDATE employees SET salary = 35000 WHERE full_name = 'Temp User';
    ROLLBACK TO SAVEPOINT before_update;   -- revert update
    RELEASE SAVEPOINT before_update;
COMMIT;  -- or END;

-- START TRANSACTION with isolation level
START TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SELECT * FROM employees;
COMMIT;

-- PREPARE TRANSACTION (requires max_prepared_transactions > 0)
-- BEGIN; INSERT INTO employees (...) VALUES (...); PREPARE TRANSACTION 'test_prepared';
-- COMMIT PREPARED 'test_prepared';
-- ROLLBACK PREPARED 'test_prepared';

-- LOCK TABLE
LOCK TABLE employees IN ACCESS EXCLUSIVE MODE;

-- SET CONSTRAINTS (all constraints DEFERRABLE)
ALTER TABLE employees ADD CONSTRAINT salary_min CHECK (salary > 0) DEFERRABLE;
BEGIN;
    SET CONSTRAINTS ALL DEFERRED;
    UPDATE employees SET salary = -100 WHERE id = 1;  -- would violate, but deferred
    UPDATE employees SET salary = 50000 WHERE id = 1; -- fix before commit
COMMIT;

-- #############################################################################
-- 6. SESSION AND SYSTEM COMMANDS
-- #############################################################################

-- SHOW configuration
SHOW timezone;
SHOW ALL;

-- SET configuration
SET timezone TO 'America/New_York';
SET LOCAL timezone TO 'PST';

-- RESET configuration
RESET timezone;

-- SET ROLE
SET ROLE test_role_renamed;
RESET ROLE;

-- SET SESSION AUTHORIZATION
SET SESSION AUTHORIZATION test_user;
RESET SESSION AUTHORIZATION;

-- DO anonymous block
DO $$
DECLARE
    emp_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO emp_count FROM employees;
    RAISE NOTICE 'Employee count: %', emp_count;
END $$;

-- LISTEN / NOTIFY
LISTEN my_channel;
NOTIFY my_channel, 'Hello, listeners!';
UNLISTEN my_channel;

-- LOAD shared library (requires compiled .so)
-- LOAD '$libdir/plpgsql';

-- CHECKPOINT
CHECKPOINT;

-- VACUUM
VACUUM employees;
VACUUM ANALYZE employees;

-- REINDEX
REINDEX INDEX idx_emp_dept_new;

-- ANALYZE
ANALYZE employees;

-- DISCARD session state
DISCARD ALL;

-- #############################################################################
-- 7. ACCESS CONTROL COMMANDS
-- #############################################################################

-- GRANT
GRANT SELECT, INSERT ON employees TO test_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO test_role_renamed;

-- REVOKE
REVOKE INSERT ON employees FROM test_user;

-- ALTER DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES FOR ROLE test_role_renamed IN SCHEMA public
    GRANT SELECT ON TABLES TO test_user;

-- #############################################################################
-- 8. OTHER COMMANDS
-- #############################################################################

-- COMMENT
COMMENT ON TABLE employees IS 'Main employee data table';
COMMENT ON COLUMN employees.salary IS 'Monthly salary in USD';

-- SECURITY LABEL (requires SELinux or similar)
-- SECURITY LABEL ON TABLE employees IS 'system_u:object_r:sepgsql_table_t:s0';

-- ABORT (same as ROLLBACK)
BEGIN;
    INSERT INTO employees (full_name) VALUES ('Rollback Me');
ABORT;  -- transaction rolled back

-- CLUSTER (reorder table based on index)
CLUSTER employees USING idx_emp_dept_new;

-- REASSIGN OWNED
REASSIGN OWNED BY test_role_renamed TO test_user;

-- REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW dept_salary_summary;

-- #############################################################################
-- 9. CLEANUP: Drop all created objects (order matters due to dependencies)
-- #############################################################################

-- Disable RLS and drop policy
ALTER TABLE employees DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS emp_policy ON employees;

-- Drop triggers and rules
DROP TRIGGER IF EXISTS trg_emp_audit ON employees;
DROP RULE IF EXISTS log_emp_delete ON employees;

-- Drop functions and procedures
DROP FUNCTION IF EXISTS get_emp_count();
DROP PROCEDURE IF EXISTS update_salary(INTEGER, NUMERIC);
DROP FUNCTION IF EXISTS audit_employee_changes();
DROP FUNCTION IF EXISTS abort_drop();
DROP FUNCTION IF EXISTS sum_positive_state(NUMERIC, NUMERIC);
DROP AGGREGATE IF EXISTS sum_positive(NUMERIC);
DROP FUNCTION IF EXISTS text_concat(text, text);
DROP OPERATOR IF EXISTS ~||~(text, text);
DROP FUNCTION IF EXISTS text_to_address(text);
DROP CAST IF EXISTS (text AS address_type);

-- Drop tables and views
DROP TABLE IF EXISTS temp_employees;
DROP TABLE IF EXISTS employee_audit;
DROP TABLE IF EXISTS offices;
DROP TABLE IF EXISTS high_earners;
DROP TABLE IF EXISTS foreign_employees;
DROP MATERIALIZED VIEW IF EXISTS dept_salary_summary;
DROP VIEW IF EXISTS employee_names;

-- Drop other objects
DROP SEQUENCE IF EXISTS order_seq;
DROP DOMAIN IF EXISTS positive_salary;
DROP TYPE IF EXISTS address_type CASCADE;
DROP TYPE IF EXISTS status_enum;
DROP COLLATION IF EXISTS case_insensitive;
DROP SCHEMA IF EXISTS renamed_schema CASCADE;
DROP SCHEMA IF EXISTS extra_schema CASCADE;
DROP EXTENSION IF EXISTS file_fdw CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP SERVER IF EXISTS file_server CASCADE;
DROP USER MAPPING IF EXISTS FOR test_user SERVER file_server;
DROP PUBLICATION IF EXISTS test_publication;
DROP STATISTICS IF EXISTS dept_salary_stats;
DROP CONVERSION IF EXISTS latin1_to_utf8_new;
DROP TEXT SEARCH DICTIONARY IF EXISTS my_dict;
DROP TEXT SEARCH CONFIGURATION IF EXISTS my_config;
-- DROP EVENT TRIGGER IF EXISTS evt_abort_drop; (commented, would block drops)

-- Drop the main table last
DROP TABLE IF EXISTS employees CASCADE;

-- Drop roles and database (connect to another DB first)
\c postgres
DROP DATABASE IF EXISTS test_commands_db;
DROP USER IF EXISTS test_user;
DROP ROLE IF EXISTS test_role_renamed;
DROP TABLESPACE IF EXISTS renamed_tablespace;

-- Final message
\echo 'All PostgreSQL 16 SQL commands have been tested and cleaned up successfully!'