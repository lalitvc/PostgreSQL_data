-- =====================================================
-- FILE: PG_DCL_COMPLETE.sql
-- Purpose: Complete DCL (Data Control Language) Commands Test File
--          Covers GRANT, REVOKE, and all privilege scenarios
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- =====================================================

-- ========== PREPARATION SECTION ==========
\c postgres
DROP DATABASE IF EXISTS dcl_complete_test;
CREATE DATABASE dcl_complete_test;
\c dcl_complete_test

-- Create test schemas
CREATE SCHEMA dcl_schema1;
CREATE SCHEMA dcl_schema2;

-- Create test roles/users
CREATE ROLE admin_role WITH CREATEDB CREATEROLE LOGIN PASSWORD 'admin123';
CREATE ROLE read_role LOGIN PASSWORD 'read123';
CREATE ROLE write_role LOGIN PASSWORD 'write123';
CREATE ROLE delete_role LOGIN PASSWORD 'delete123';
CREATE ROLE app_user LOGIN PASSWORD 'app123';
CREATE ROLE report_user LOGIN PASSWORD 'report123';
CREATE ROLE manager_role;
CREATE ROLE employee_role;
CREATE ROLE public_role;

-- ========== CREATE TEST OBJECTS ==========

-- Tables
CREATE TABLE employees (
    id serial PRIMARY KEY,
    emp_name text NOT NULL,
    salary numeric(10,2),
    department text,
    ssn text,
    created_at timestamp DEFAULT now()
);

CREATE TABLE departments (
    id serial PRIMARY KEY,
    dept_name text,
    budget numeric(12,2)
);

CREATE TABLE salary_history (
    id serial,
    emp_id integer,
    old_salary numeric(10,2),
    new_salary numeric(10,2),
    changed_at timestamp
);

-- Sequences
CREATE SEQUENCE emp_id_seq START 1000;
CREATE SEQUENCE dept_id_seq START 500;

-- Functions
CREATE FUNCTION get_employee_count() RETURNS integer
LANGUAGE SQL AS 'SELECT COUNT(*) FROM employees';

CREATE FUNCTION update_timestamp() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.created_at = now();
    RETURN NEW;
END;
$$;

-- Procedures
CREATE PROCEDURE update_salary(emp_id integer, new_salary numeric)
LANGUAGE SQL AS $$
    UPDATE employees SET salary = new_salary WHERE id = emp_id;
$$;

-- Views
CREATE VIEW employee_view AS 
SELECT id, emp_name, department FROM employees;

CREATE VIEW salary_view AS 
SELECT emp_name, salary FROM employees WHERE department = 'IT';

-- Materialized View
CREATE MATERIALIZED VIEW dept_summary AS
SELECT department, COUNT(*) as emp_count, AVG(salary) as avg_salary
FROM employees GROUP BY department;

-- Schema
CREATE SCHEMA restricted_schema;

-- Foreign objects
CREATE FOREIGN DATA WRAPPER test_fdw VALIDATOR postgresql_fdw_validator;
CREATE SERVER test_server FOREIGN DATA WRAPPER test_fdw;
CREATE FOREIGN TABLE foreign_employees (
    id int,
    name text
) SERVER test_server;

-- Types
CREATE TYPE employee_type AS (id int, name text, dept text);

-- ========== GRANT COMMANDS - ALL VARIATIONS ==========

-- 1. GRANT ON TABLES
GRANT SELECT ON employees TO read_role;
GRANT INSERT, UPDATE ON employees TO write_role;
GRANT DELETE ON employees TO delete_role;
GRANT ALL PRIVILEGES ON employees TO admin_role;

-- 2. GRANT ON SPECIFIC COLUMNS
GRANT SELECT (id, emp_name) ON employees TO app_user;
GRANT UPDATE (salary) ON employees TO manager_role;
GRANT SELECT (ssn) ON employees TO admin_role WITH GRANT OPTION;
GRANT REFERENCES (id) ON employees TO report_user;

-- 3. GRANT WITH GRANT OPTION
GRANT SELECT ON departments TO manager_role WITH GRANT OPTION;
GRANT INSERT ON salary_history TO admin_role WITH GRANT OPTION;

-- 4. GRANT WITH HIERARCHY OPTION
GRANT SELECT ON employees TO employee_role WITH HIERARCHY OPTION;

-- 5. GRANT ON SEQUENCES
GRANT USAGE ON emp_id_seq TO write_role;
GRANT SELECT ON emp_id_seq TO read_role;
GRANT UPDATE ON dept_id_seq TO admin_role;
GRANT ALL ON emp_id_seq TO manager_role;

-- 6. GRANT ON DATABASE
GRANT CONNECT ON DATABASE dcl_complete_test TO app_user;
GRANT CREATE ON DATABASE dcl_complete_test TO admin_role;
GRANT TEMP ON DATABASE dcl_complete_test TO write_role;
GRANT ALL PRIVILEGES ON DATABASE dcl_complete_test TO admin_role;

-- 7. GRANT ON SCHEMAS
GRANT USAGE ON SCHEMA dcl_schema1 TO read_role;
GRANT CREATE ON SCHEMA dcl_schema1 TO write_role;
GRANT ALL PRIVILEGES ON SCHEMA dcl_schema2 TO admin_role;
GRANT USAGE ON SCHEMA public TO PUBLIC;

-- 8. GRANT ON FUNCTIONS
GRANT EXECUTE ON FUNCTION get_employee_count() TO read_role;
GRANT EXECUTE ON FUNCTION update_timestamp() TO write_role;
GRANT ALL ON FUNCTION get_employee_count() TO admin_role;

-- 9. GRANT ON PROCEDURES
GRANT EXECUTE ON PROCEDURE update_salary(integer, numeric) TO manager_role;
GRANT EXECUTE ON PROCEDURE update_salary(integer, numeric) TO admin_role WITH GRANT OPTION;

-- 10. GRANT ON VIEWS
GRANT SELECT ON employee_view TO read_role;
GRANT INSERT, UPDATE ON employee_view TO write_role;
GRANT ALL ON salary_view TO admin_role;

-- 11. GRANT ON MATERIALIZED VIEWS
GRANT SELECT ON dept_summary TO report_user;
GRANT SELECT ON dept_summary TO admin_role WITH GRANT OPTION;

-- 12. GRANT ON FOREIGN DATA WRAPPER
GRANT USAGE ON FOREIGN DATA WRAPPER test_fdw TO app_user;
GRANT USAGE ON FOREIGN DATA WRAPPER test_fdw TO admin_role WITH GRANT OPTION;

-- 13. GRANT ON FOREIGN SERVER
GRANT USAGE ON FOREIGN SERVER test_server TO app_user;
GRANT USAGE ON FOREIGN SERVER test_server TO admin_role;

-- 14. GRANT ON FOREIGN TABLE
GRANT SELECT ON foreign_employees TO read_role;
GRANT INSERT ON foreign_employees TO write_role;

-- 15. GRANT ON TYPES
GRANT USAGE ON TYPE employee_type TO app_user;
GRANT USAGE ON TYPE employee_type TO admin_role;

-- 16. GRANT TO MULTIPLE ROLES
GRANT SELECT ON departments TO read_role, report_user, app_user;
GRANT INSERT, UPDATE ON salary_history TO write_role, manager_role;

-- 17. GRANT TO PUBLIC
GRANT SELECT ON employee_view TO PUBLIC;
GRANT USAGE ON SCHEMA public TO PUBLIC;

-- 18. GRANT WITH ADMIN OPTION (for roles)
GRANT read_role TO app_user WITH ADMIN OPTION;
GRANT write_role TO manager_role;
GRANT manager_role TO admin_role WITH ADMIN OPTION;

-- 19. GRANT ALL IN SCHEMA
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dcl_schema1 TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dcl_schema1 TO admin_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA dcl_schema1 TO admin_role;

-- 20. GRANT ON ALL TABLES
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_role;
GRANT INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO write_role;

-- 21. GRANT ON ALL SEQUENCES
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO write_role;

-- 22. GRANT ON ALL FUNCTIONS
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- 23. GRANT FOR FUTURE OBJECTS (Default Privileges)
ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
GRANT SELECT ON TABLES TO read_role;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
GRANT INSERT, UPDATE, DELETE ON TABLES TO write_role;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
GRANT USAGE ON SEQUENCES TO write_role;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
GRANT EXECUTE ON FUNCTIONS TO app_user;

ALTER DEFAULT PRIVILEGES FOR USER admin_role
GRANT SELECT ON TABLES TO PUBLIC;

-- 24. GRANT WITH SPECIFIC PRIVILEGES COMBINATIONS
GRANT SELECT, INSERT, UPDATE ON employees TO manager_role;
GRANT SELECT, UPDATE (salary, department) ON employees TO hr_role;
GRANT TRUNCATE, REFERENCES, TRIGGER ON employees TO admin_role;

-- 25. GRANT FOR ROLE HIERARCHY
CREATE ROLE super_role;
CREATE ROLE sub_role;
GRANT super_role TO sub_role WITH ADMIN OPTION;

-- ========== REVOKE COMMANDS - ALL VARIATIONS ==========

-- 1. REVOKE BASIC
REVOKE SELECT ON employees FROM read_role;

-- 2. REVOKE SPECIFIC COLUMNS
REVOKE SELECT (id, emp_name) ON employees FROM app_user;
REVOKE UPDATE (salary) ON employees FROM manager_role;

-- 3. REVOKE WITH GRANT OPTION FOR
REVOKE GRANT OPTION FOR SELECT ON departments FROM manager_role CASCADE;
REVOKE GRANT OPTION FOR SELECT (ssn) ON employees FROM admin_role CASCADE;

-- 4. REVOKE ADMIN OPTION FOR
REVOKE ADMIN OPTION FOR read_role FROM app_user CASCADE;

-- 5. REVOKE ALL PRIVILEGES
REVOKE ALL PRIVILEGES ON departments FROM manager_role;
REVOKE ALL PRIVILEGES ON SCHEMA dcl_schema2 FROM admin_role CASCADE;

-- 6. REVOKE ON SPECIFIC OBJECTS
REVOKE INSERT, UPDATE ON employees FROM write_role;
REVOKE DELETE ON employees FROM delete_role;

-- 7. REVOKE ON DATABASE
REVOKE CREATE ON DATABASE dcl_complete_test FROM admin_role;
REVOKE TEMP ON DATABASE dcl_complete_test FROM write_role;

-- 8. REVOKE ON SCHEMA
REVOKE CREATE ON SCHEMA dcl_schema1 FROM write_role;
REVOKE USAGE ON SCHEMA dcl_schema1 FROM read_role;

-- 9. REVOKE ON SEQUENCES
REVOKE USAGE ON emp_id_seq FROM write_role;
REVOKE SELECT ON emp_id_seq FROM read_role;

-- 10. REVOKE ON FUNCTIONS
REVOKE EXECUTE ON FUNCTION get_employee_count() FROM read_role;

-- 11. REVOKE ON PROCEDURES
REVOKE EXECUTE ON PROCEDURE update_salary(integer, numeric) FROM manager_role;

-- 12. REVOKE ON VIEWS
REVOKE SELECT ON employee_view FROM read_role;
REVOKE INSERT, UPDATE ON employee_view FROM write_role;

-- 13. REVOKE ON MATERIALIZED VIEWS
REVOKE SELECT ON dept_summary FROM report_user;

-- 14. REVOKE ON FOREIGN OBJECTS
REVOKE USAGE ON FOREIGN DATA WRAPPER test_fdw FROM app_user;
REVOKE USAGE ON FOREIGN SERVER test_server FROM app_user;
REVOKE SELECT ON foreign_employees FROM read_role;

-- 15. REVOKE ON TYPES
REVOKE USAGE ON TYPE employee_type FROM app_user;

-- 16. REVOKE FROM PUBLIC
REVOKE SELECT ON employee_view FROM PUBLIC;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;

-- 17. REVOKE WITH CASCADE
REVOKE SELECT ON employees FROM manager_role CASCADE;
REVOKE ALL ON salary_history FROM admin_role CASCADE;

-- 18. REVOKE WITH RESTRICT
REVOKE INSERT ON departments FROM manager_role RESTRICT;

-- 19. REVOKE ON ALL TABLES
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM read_role CASCADE;

-- 20. REVOKE ON ALL SEQUENCES
REVOKE USAGE ON ALL SEQUENCES IN SCHEMA public FROM write_role;

-- 21. REVOKE ON ALL FUNCTIONS
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM app_user;

-- 22. REVOKE DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
REVOKE SELECT ON TABLES FROM read_role;

ALTER DEFAULT PRIVILEGES FOR ROLE admin_role IN SCHEMA dcl_schema1
REVOKE INSERT, UPDATE ON TABLES FROM write_role CASCADE;

ALTER DEFAULT PRIVILEGES FOR USER admin_role
REVOKE SELECT ON TABLES FROM PUBLIC;

-- 23. REVOKE MULTIPLE PRIVILEGES
REVOKE SELECT, INSERT, UPDATE ON employees FROM manager_role;

-- 24. REVOKE ROLE MEMBERSHIP
REVOKE read_role FROM app_user;
REVOKE write_role FROM manager_role;
REVOKE manager_role FROM admin_role;

-- ========== ADVANCED DCL SCENARIOS ==========

-- 1. Row Level Security with GRANT
CREATE TABLE rls_employees (
    id serial,
    emp_name text,
    department text,
    salary numeric
);

ALTER TABLE rls_employees ENABLE ROW LEVEL SECURITY;

CREATE POLICY dept_policy ON rls_employees
    USING (department = current_setting('app.current_dept'));

GRANT SELECT, INSERT, UPDATE ON rls_employees TO manager_role;
GRANT SELECT ON rls_employees TO read_role;

-- 2. Column Level Security with GRANT
CREATE TABLE sensitive_data (
    id serial,
    public_data text,
    confidential_data text,
    restricted_data text
);

GRANT SELECT (id, public_data) ON sensitive_data TO read_role;
GRANT SELECT (confidential_data) ON sensitive_data TO manager_role;
GRANT SELECT (restricted_data) ON sensitive_data TO admin_role;

-- 3. Security Definer Functions
CREATE FUNCTION get_sensitive_info(emp_id integer)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS 'SELECT ssn FROM employees WHERE id = emp_id';

GRANT EXECUTE ON FUNCTION get_sensitive_info(integer) TO manager_role;

-- 4. Complex Role Hierarchy
CREATE ROLE ceo_role;
CREATE ROLE cto_role;
CREATE ROLE dev_role;
CREATE ROLE qa_role;

GRANT ceo_role TO cto_role;
GRANT cto_role TO dev_role, qa_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO ceo_role WITH GRANT OPTION;
GRANT INSERT, UPDATE ON employees TO dev_role;

-- 5. Audit User with Specific Privileges
CREATE ROLE audit_user LOGIN PASSWORD 'audit123';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO audit_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO audit_user;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM audit_user;

-- 6. Application Role Pattern
CREATE ROLE app_owner;
CREATE ROLE app_user_role;
CREATE ROLE app_readonly;

GRANT app_owner TO app_user_role;
GRANT app_readonly TO app_user_role;

GRANT ALL ON employees TO app_owner;
GRANT SELECT ON employees TO app_readonly;

-- 7. Temporary Privileges (using role valid until)
CREATE ROLE temp_consultant LOGIN PASSWORD 'temp123' VALID UNTIL '2025-12-31';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO temp_consultant;
GRANT INSERT ON employees TO temp_consultant;

-- 8. Grant with Different Privilege Levels
GRANT SELECT ON departments TO PUBLIC;
GRANT INSERT ON departments TO write_role;
GRANT UPDATE, DELETE ON departments TO admin_role;

-- 9. Revoke with Different Cascade Levels
GRANT SELECT ON employees TO manager_role WITH GRANT OPTION;
GRANT SELECT ON employees TO employee_role;
REVOKE SELECT ON employees FROM manager_role CASCADE;

-- 10. Schema Object Privileges
CREATE TABLE schema_test.table1 (id int);
CREATE TABLE schema_test.table2 (id int);

GRANT ALL ON schema_test TO admin_role;
GRANT USAGE ON SCHEMA schema_test TO read_role;
GRANT SELECT ON schema_test.table1 TO read_role;

-- ========== VERIFICATION QUERIES ==========

-- Check table privileges
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_name IN ('employees', 'departments')
ORDER BY grantee, table_name;

-- Check column privileges
SELECT 
    grantee,
    table_schema,
    table_name,
    column_name,
    privilege_type
FROM information_schema.column_privileges
WHERE table_name = 'employees'
ORDER BY grantee, column_name;

-- Check role memberships
SELECT 
    r.rolname as role_name,
    m.rolname as member_name,
    am.admin_option
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.roleid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname IN ('admin_role', 'manager_role', 'app_user');

-- Check default privileges
SELECT 
    defaclobjtype,
    defacluser::regrole,
    defaclnamespace::regnamespace,
    defaclacl
FROM pg_default_acl;

-- Check schema privileges
SELECT 
    grantee,
    schema_name,
    privilege_type
FROM information_schema.schema_privileges
WHERE schema_name IN ('dcl_schema1', 'dcl_schema2');

-- ========== TEST EXECUTION ==========

-- Insert test data
INSERT INTO employees (emp_name, salary, department, ssn) VALUES
('John Doe', 50000, 'IT', '123-45-6789'),
('Jane Smith', 60000, 'HR', '987-65-4321'),
('Bob Johnson', 55000, 'IT', '456-78-9123');

-- Test role permissions (simulated)
SET ROLE read_role;
SELECT * FROM employee_view; -- Should work
SELECT * FROM salary_view;   -- Should work
RESET ROLE;

SET ROLE write_role;
INSERT INTO employees (emp_name, salary, department, ssn) 
VALUES ('Test User', 45000, 'Sales', '111-22-3333');
UPDATE employees SET salary = 48000 WHERE emp_name = 'Test User';
RESET ROLE;

SET ROLE manager_role;
SELECT * FROM employees;      -- Should work
UPDATE employees SET salary = 52000 WHERE emp_name = 'John Doe';
RESET ROLE;

-- ========== CLEANUP SECTION ==========

-- Drop all roles in correct order
DROP ROLE IF EXISTS ceo_role CASCADE;
DROP ROLE IF EXISTS cto_role CASCADE;
DROP ROLE IF EXISTS dev_role CASCADE;
DROP ROLE IF EXISTS qa_role CASCADE;
DROP ROLE IF EXISTS temp_consultant CASCADE;
DROP ROLE IF EXISTS audit_user CASCADE;
DROP ROLE IF EXISTS app_owner CASCADE;
DROP ROLE IF EXISTS app_user_role CASCADE;
DROP ROLE IF EXISTS app_readonly CASCADE;
DROP ROLE IF EXISTS super_role CASCADE;
DROP ROLE IF EXISTS sub_role CASCADE;
DROP ROLE IF EXISTS hr_role CASCADE;

-- Drop main roles
DROP ROLE IF EXISTS admin_role CASCADE;
DROP ROLE IF EXISTS read_role CASCADE;
DROP ROLE IF EXISTS write_role CASCADE;
DROP ROLE IF EXISTS delete_role CASCADE;
DROP ROLE IF EXISTS app_user CASCADE;
DROP ROLE IF EXISTS report_user CASCADE;
DROP ROLE IF EXISTS manager_role CASCADE;
DROP ROLE IF EXISTS employee_role CASCADE;
DROP ROLE IF EXISTS public_role CASCADE;

-- Drop all objects
DROP FOREIGN TABLE IF EXISTS foreign_employees CASCADE;
DROP SERVER IF EXISTS test_server CASCADE;
DROP FOREIGN DATA WRAPPER IF EXISTS test_fdw CASCADE;
DROP MATERIALIZED VIEW IF EXISTS dept_summary CASCADE;
DROP VIEW IF EXISTS employee_view CASCADE;
DROP VIEW IF EXISTS salary_view CASCADE;
DROP PROCEDURE IF EXISTS update_salary(integer, numeric) CASCADE;
DROP FUNCTION IF EXISTS get_employee_count() CASCADE;
DROP FUNCTION IF EXISTS update_timestamp() CASCADE;
DROP FUNCTION IF EXISTS get_sensitive_info(integer) CASCADE;
DROP TABLE IF EXISTS rls_employees CASCADE;
DROP TABLE IF EXISTS sensitive_data CASCADE;
DROP TABLE IF EXISTS salary_history CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP SEQUENCE IF EXISTS emp_id_seq CASCADE;
DROP SEQUENCE IF EXISTS dept_id_seq CASCADE;
DROP SCHEMA IF EXISTS dcl_schema1 CASCADE;
DROP SCHEMA IF EXISTS dcl_schema2 CASCADE;
DROP SCHEMA IF EXISTS restricted_schema CASCADE;
DROP SCHEMA IF EXISTS schema_test CASCADE;
DROP TYPE IF EXISTS employee_type CASCADE;

-- ========== FINAL CLEANUP ==========
\c postgres
DROP DATABASE IF EXISTS dcl_complete_test CASCADE;

SELECT '========================================' AS status;
SELECT 'DCL Complete Test Suite Completed Successfully!' AS status;
SELECT '========================================' AS status;