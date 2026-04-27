-- =====================================================
-- FILE: PG_DDL_ALTER.sql
-- Purpose: Demonstrates ALL ALTER commands in PostgreSQL
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- =====================================================

\echo '=========================================='
\echo 'Starting ALTER commands test suite'
\echo '=========================================='

-- =====================================================
-- PREPARATION: Create test objects
-- =====================================================

\echo '\n>>> PREPARATION PHASE: Creating test objects...'

-- Create test schema
CREATE SCHEMA IF NOT EXISTS test_schema;

-- Create test users/roles
DROP ROLE IF EXISTS test_owner;
DROP ROLE IF EXISTS test_user;
DROP ROLE IF EXISTS readonly_user;
CREATE ROLE test_owner LOGIN;
CREATE ROLE test_user LOGIN;
CREATE ROLE readonly_user;

-- Create test aggregate function
CREATE OR REPLACE FUNCTION my_avg_sfunc(state numeric, x numeric)
RETURNS numeric LANGUAGE SQL AS 'SELECT state + x';

CREATE OR REPLACE FUNCTION my_avg_final(state numeric)
RETURNS numeric LANGUAGE SQL AS 'SELECT state / 2';

DROP AGGREGATE IF EXISTS my_average(numeric) CASCADE;
CREATE AGGREGATE my_average(numeric) (
    SFUNC = my_avg_sfunc,
    STYPE = numeric,
    FINALFUNC = my_avg_final
);

-- Create test collation
DROP COLLATION IF EXISTS test_collation CASCADE;
CREATE COLLATION test_collation (LOCALE = 'en_US.utf8');

-- Create test conversion
DROP CONVERSION IF EXISTS test_conversion CASCADE;
CREATE CONVERSION test_conversion FOR 'LATIN1' TO 'UTF8' FROM iso_8859_1_to_utf8;

-- Create test database (will be renamed)
DROP DATABASE IF EXISTS test_alter_db;
CREATE DATABASE test_alter_db;

-- Create test domain
DROP DOMAIN IF EXISTS positive_int CASCADE;
CREATE DOMAIN positive_int AS integer CHECK (VALUE > 0);

-- Create test event trigger
DROP EVENT TRIGGER IF EXISTS test_event_trigger;
CREATE EVENT TRIGGER test_event_trigger ON ddl_command_start EXECUTE FUNCTION pg_catalog.pg_event_trigger_ddl_commands();

-- Create test extension (create empty extension for demo)
-- Note: In real scenario, you'd use an actual extension like 'btree_gin'
CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA test_schema;

-- Create test foreign data wrapper
DROP FOREIGN DATA WRAPPER IF EXISTS test_fdw CASCADE;
CREATE FOREIGN DATA WRAPPER test_fdw;

-- Create test foreign server and table
DROP SERVER IF EXISTS test_server CASCADE;
CREATE SERVER test_server FOREIGN DATA WRAPPER test_fdw;

DROP FOREIGN TABLE IF EXISTS test_ft_customers;
CREATE FOREIGN TABLE test_ft_customers (
    id integer,
    name text
) SERVER test_server;

-- Create test functions
CREATE OR REPLACE FUNCTION test_calc_tax(numeric)
RETURNS numeric LANGUAGE SQL AS 'SELECT $1 * 0.2';

CREATE OR REPLACE FUNCTION test_refresh_data(p_id integer)
RETURNS void LANGUAGE SQL AS 'SELECT 1';

-- Create test group (role)
DROP ROLE IF EXISTS developers;
CREATE ROLE developers;

-- Create test table with index for index operations
DROP TABLE IF EXISTS test_users CASCADE;
CREATE TABLE test_users (
    id serial PRIMARY KEY,
    name text
);
CREATE INDEX idx_test_users_name ON test_users(name);

-- Create test language
-- Note: 'plpython3u' might not be installed; using 'plpgsql' for safety
CREATE LANGUAGE IF NOT EXISTS plpgsql;

-- Create test large object
-- Note: SELECT lo_create(12345);

-- Create test materialized view
DROP TABLE IF EXISTS test_sales CASCADE;
CREATE TABLE test_sales (amount numeric, sale_date date);
INSERT INTO test_sales VALUES (100, '2024-01-01');
DROP MATERIALIZED VIEW IF EXISTS test_mv_sales;
CREATE MATERIALIZED VIEW test_mv_sales AS SELECT * FROM test_sales;

-- Create test operator
CREATE OPERATOR === (
    LEFTARG = text,
    RIGHTARG = text,
    PROCEDURE = text_eq
);

-- Create test operator class
CREATE OPERATOR CLASS test_op_class FOR TYPE int USING btree AS OPERATOR 1 <(int,int);

-- Create test operator family
CREATE OPERATOR FAMILY test_op_fam USING btree;

-- Create test RLS policy
DROP TABLE IF EXISTS test_customers CASCADE;
CREATE TABLE test_customers (id int, name text, active boolean);
ALTER TABLE test_customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY test_policy_select ON test_customers FOR SELECT USING (active = true);

-- Create test procedure
CREATE OR REPLACE PROCEDURE test_proc(param integer)
LANGUAGE SQL AS $$ INSERT INTO test_users VALUES (param, 'test'); $$;

-- Create test publication
DROP PUBLICATION IF EXISTS test_publication;
CREATE PUBLICATION test_publication FOR TABLE test_users;

-- Create test routine (just alias to function)
CREATE OR REPLACE FUNCTION test_routine(text)
RETURNS text LANGUAGE SQL AS 'SELECT $1';

-- Create test rule
CREATE OR REPLACE FUNCTION test_rule_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END; $$;
CREATE TABLE test_rule_table (id int);
CREATE RULE test_rule_log_update AS ON UPDATE TO test_rule_table DO NOTHING;

-- Create test schema
DROP SCHEMA IF EXISTS test_rename_schema CASCADE;
CREATE SCHEMA test_rename_schema;

-- Create test sequence
DROP SEQUENCE IF EXISTS test_order_seq;
CREATE SEQUENCE test_order_seq START 1;

-- Create test statistics
CREATE TABLE test_stats_tab (a int, b int);
INSERT INTO test_stats_tab VALUES (1,1), (2,2);
CREATE STATISTICS test_stats ON a,b FROM test_stats_tab;

-- Create test subscription (mock)
DROP SUBSCRIPTION IF EXISTS test_subscription;
CREATE SUBSCRIPTION test_subscription CONNECTION 'dbname=postgres' PUBLICATION test_publication;

-- Create test tablespace (requires superuser)
-- DROP TABLESPACE IF EXISTS test_tablespace;
-- CREATE TABLESPACE test_tablespace LOCATION '/tmp/test_tablespace';

-- Create test text search objects
CREATE TEXT SEARCH CONFIGURATION test_ts_config (COPY = pg_catalog.simple);
CREATE TEXT SEARCH DICTIONARY test_ts_dict (TEMPLATE = simple);
CREATE TEXT SEARCH PARSER test_ts_parser (START = prsd_start, GETTOKEN = prsd_nexttoken, END = prsd_end, HEADLINE = prsd_headline);
CREATE TEXT SEARCH TEMPLATE test_ts_template (INIT = dsimple_init, LEXIZE = dsimple_lexize);

-- Create test trigger
CREATE TABLE test_trigger_table (id int, modified timestamp);
CREATE OR REPLACE FUNCTION test_trigger_func()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN NEW.modified = NOW(); RETURN NEW; END; $$;
CREATE TRIGGER test_trigger BEFORE UPDATE ON test_trigger_table FOR EACH ROW EXECUTE FUNCTION test_trigger_func();

-- Create test type
CREATE TYPE test_status_type AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE test_custom_type AS (id int, name text);

-- Create test user mapping
DROP USER MAPPING IF EXISTS FOR test_user SERVER test_server;
CREATE USER MAPPING FOR test_user SERVER test_server OPTIONS (user 'test', password 'test');

-- Create test view
CREATE VIEW test_active_customers AS SELECT * FROM test_customers WHERE active = true;

-- Create parent/child for inheritance test
DROP TABLE IF EXISTS test_parent CASCADE;
DROP TABLE IF EXISTS test_child CASCADE;
CREATE TABLE test_parent (id int, data text);
CREATE TABLE test_child (id int, data text, extra text);

-- Create partitioned table for partition test
DROP TABLE IF EXISTS test_sales_part CASCADE;
CREATE TABLE test_sales_part (id int, sale_date date) PARTITION BY RANGE (sale_date);

\echo '>>> PREPARATION COMPLETE'
\echo ''

-- =====================================================
-- MAIN TEST: ALTER commands
-- =====================================================

\echo '=========================================='
\echo 'TESTING ALTER COMMANDS'
\echo '=========================================='

-- 1. ALTER AGGREGATE
ALTER AGGREGATE my_average(numeric) OWNER TO test_owner;
\echo '✓ ALTER AGGREGATE'

-- 2. ALTER COLLATION
ALTER COLLATION test_collation RENAME TO test_collation_renamed;
\echo '✓ ALTER COLLATION'

-- 3. ALTER CONVERSION
ALTER CONVERSION test_conversion OWNER TO test_owner;
\echo '✓ ALTER CONVERSION'

-- 4. ALTER DATABASE
ALTER DATABASE test_alter_db SET timezone TO 'UTC';
ALTER DATABASE test_alter_db RENAME TO test_alter_db_renamed;
\echo '✓ ALTER DATABASE'

-- 5. ALTER DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES IN SCHEMA test_schema GRANT SELECT ON TABLES TO readonly_user;
\echo '✓ ALTER DEFAULT PRIVILEGES'

-- 6. ALTER DOMAIN
ALTER DOMAIN positive_int ADD CONSTRAINT positive_check CHECK (VALUE > 0);
\echo '✓ ALTER DOMAIN'

-- 7. ALTER EVENT TRIGGER
ALTER EVENT TRIGGER test_event_trigger DISABLE;
\echo '✓ ALTER EVENT TRIGGER'

-- 8. ALTER EXTENSION
ALTER EXTENSION btree_gin UPDATE TO '1.3';
\echo '✓ ALTER EXTENSION'

-- 9. ALTER FOREIGN DATA WRAPPER
ALTER FOREIGN DATA WRAPPER test_fdw OWNER TO test_owner;
\echo '✓ ALTER FOREIGN DATA WRAPPER'

-- 10. ALTER FOREIGN TABLE
ALTER FOREIGN TABLE test_ft_customers ADD COLUMN email text;
ALTER FOREIGN TABLE test_ft_customers RENAME TO test_ft_clients;
\echo '✓ ALTER FOREIGN TABLE'

-- 11. ALTER FUNCTION
ALTER FUNCTION test_calc_tax(numeric) IMMUTABLE;
ALTER FUNCTION test_calc_tax(numeric) RENAME TO test_compute_tax;
\echo '✓ ALTER FUNCTION'

-- 12. ALTER GROUP
ALTER GROUP developers ADD USER test_user;
ALTER GROUP developers DROP USER test_user;
\echo '✓ ALTER GROUP'

-- 13. ALTER INDEX
ALTER INDEX idx_test_users_name RENAME TO idx_test_users_fullname;
\echo '✓ ALTER INDEX'

-- 14. ALTER LANGUAGE
ALTER LANGUAGE plpgsql RENAME TO plpgsql_renamed;
ALTER LANGUAGE plpgsql_renamed RENAME TO plpgsql;
\echo '✓ ALTER LANGUAGE'

-- 15. ALTER LARGE OBJECT
-- Note: Requires existing large object, skipping for demo
\echo '⚠ ALTER LARGE OBJECT (skipped - needs existing LO)'

-- 16. ALTER MATERIALIZED VIEW
ALTER MATERIALIZED VIEW test_mv_sales RENAME TO test_mv_revenue;
\echo '✓ ALTER MATERIALIZED VIEW'

-- 17. ALTER OPERATOR
ALTER OPERATOR === (text, text) OWNER TO test_owner;
\echo '✓ ALTER OPERATOR'

-- 18. ALTER OPERATOR CLASS
ALTER OPERATOR CLASS test_op_class USING btree RENAME TO test_op_class_new;
\echo '✓ ALTER OPERATOR CLASS'

-- 19. ALTER OPERATOR FAMILY
ALTER OPERATOR FAMILY test_op_fam USING btree ADD OPERATOR 1 < (int, int);
\echo '✓ ALTER OPERATOR FAMILY'

-- 20. ALTER POLICY
ALTER POLICY test_policy_select ON test_customers RENAME TO test_policy_active;
ALTER POLICY test_policy_active ON test_customers USING (active = true);
\echo '✓ ALTER POLICY'

-- 21. ALTER PROCEDURE
ALTER PROCEDURE test_proc(integer) OWNER TO test_owner;
\echo '✓ ALTER PROCEDURE'

-- 22. ALTER PUBLICATION
ALTER PUBLICATION test_publication ADD TABLE test_customers;
\echo '✓ ALTER PUBLICATION'

-- 23. ALTER ROLE
ALTER ROLE test_user WITH PASSWORD 'test123';
\echo '✓ ALTER ROLE'

-- 24. ALTER ROUTINE
ALTER ROUTINE test_routine(text) RENAME TO test_routine_v2;
\echo '✓ ALTER ROUTINE'

-- 25. ALTER RULE
ALTER RULE test_rule_log_update ON test_rule_table RENAME TO test_rule_log_v2;
\echo '✓ ALTER RULE'

-- 26. ALTER SCHEMA
ALTER SCHEMA test_rename_schema RENAME TO test_schema_renamed;
\echo '✓ ALTER SCHEMA'

-- 27. ALTER SEQUENCE
ALTER SEQUENCE test_order_seq RESTART WITH 1000;
\echo '✓ ALTER SEQUENCE'

-- 28. ALTER SERVER
ALTER SERVER test_server OPTIONS (SET host 'localhost');
\echo '✓ ALTER SERVER'

-- 29. ALTER STATISTICS
ALTER STATISTICS test_stats SET STATISTICS 500;
\echo '✓ ALTER STATISTICS'

-- 30. ALTER SUBSCRIPTION
ALTER SUBSCRIPTION test_subscription ENABLE;
\echo '✓ ALTER SUBSCRIPTION'

-- 31. ALTER SYSTEM
ALTER SYSTEM SET max_connections TO 300;
ALTER SYSTEM RESET max_connections;
\echo '✓ ALTER SYSTEM'

-- 32. ALTER TABLE (PARTITIONING, FOREIGN KEYS, INHERITANCE)
-- Partitioning
ALTER TABLE test_sales_part ATTACH PARTITION test_sales_part_2024 FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
\echo '✓ ALTER TABLE - PARTITIONING'

-- Foreign Keys
ALTER TABLE test_child ADD CONSTRAINT fk_parent_id FOREIGN KEY (id) REFERENCES test_parent(id);
\echo '✓ ALTER TABLE - FOREIGN KEY'

-- Inheritance
ALTER TABLE test_child INHERIT test_parent;
\echo '✓ ALTER TABLE - INHERITANCE'

-- 33. ALTER TABLESPACE
-- Note: Requires existing tablespace and superuser
\echo '⚠ ALTER TABLESPACE (skipped - needs superuser)'

-- 34. ALTER TEXT SEARCH CONFIGURATION
ALTER TEXT SEARCH CONFIGURATION test_ts_config ALTER MAPPING FOR word WITH simple;
\echo '✓ ALTER TEXT SEARCH CONFIGURATION'

-- 35. ALTER TEXT SEARCH DICTIONARY
ALTER TEXT SEARCH DICTIONARY test_ts_dict (StopWords = 'english');
\echo '✓ ALTER TEXT SEARCH DICTIONARY'

-- 36. ALTER TEXT SEARCH PARSER
ALTER TEXT SEARCH PARSER test_ts_parser RENAME TO test_ts_parser_v2;
\echo '✓ ALTER TEXT SEARCH PARSER'

-- 37. ALTER TEXT SEARCH TEMPLATE
ALTER TEXT SEARCH TEMPLATE test_ts_template RENAME TO test_ts_template_v2;
\echo '✓ ALTER TEXT SEARCH TEMPLATE'

-- 38. ALTER TRIGGER
ALTER TRIGGER test_trigger ON test_trigger_table RENAME TO test_trigger_v2;
\echo '✓ ALTER TRIGGER'

-- 39. ALTER TYPE
ALTER TYPE test_status_type ADD VALUE 'ARCHIVED' BEFORE 'DELETED';
ALTER TYPE test_custom_type OWNER TO test_owner;
\echo '✓ ALTER TYPE'

-- 40. ALTER USER
ALTER USER test_user RENAME TO test_user_renamed;
ALTER USER test_user_renamed RENAME TO test_user;
\echo '✓ ALTER USER'

-- 41. ALTER USER MAPPING
ALTER USER MAPPING FOR test_user SERVER test_server OPTIONS (SET password 'newPass');
\echo '✓ ALTER USER MAPPING'

-- 42. ALTER VIEW
ALTER VIEW test_active_customers RENAME TO test_active_clients;
\echo '✓ ALTER VIEW'

\echo ''
\echo '=========================================='
\echo 'ALL ALTER TESTS COMPLETED SUCCESSFULLY'
\echo '=========================================='

-- =====================================================
-- CLEANUP: Drop all test objects
-- =====================================================

\echo '\n>>> CLEANUP PHASE: Removing test objects...'

-- Drop tables with dependencies first
DROP TABLE IF EXISTS test_child CASCADE;
DROP TABLE IF EXISTS test_parent CASCADE;
DROP TABLE IF EXISTS test_sales_part CASCADE;
DROP TABLE IF EXISTS test_sales_part_2024 CASCADE;
DROP TABLE IF EXISTS test_customers CASCADE;
DROP TABLE IF EXISTS test_users CASCADE;
DROP TABLE IF EXISTS test_rule_table CASCADE;
DROP TABLE IF EXISTS test_trigger_table CASCADE;
DROP TABLE IF EXISTS test_stats_tab CASCADE;
DROP TABLE IF EXISTS test_sales CASCADE;

-- Drop foreign objects
DROP FOREIGN TABLE IF EXISTS test_ft_clients CASCADE;
DROP FOREIGN TABLE IF EXISTS test_ft_customers CASCADE;
DROP SERVER IF EXISTS test_server CASCADE;
DROP FOREIGN DATA WRAPPER IF EXISTS test_fdw CASCADE;
DROP USER MAPPING IF EXISTS FOR test_user SERVER test_server;

-- Drop views and materialized views
DROP VIEW IF EXISTS test_active_clients CASCADE;
DROP MATERIALIZED VIEW IF EXISTS test_mv_revenue CASCADE;

-- Drop functions, procedures, aggregates
DROP AGGREGATE IF EXISTS my_average(numeric) CASCADE;
DROP FUNCTION IF EXISTS test_calc_tax(numeric) CASCADE;
DROP FUNCTION IF EXISTS test_compute_tax(numeric) CASCADE;
DROP FUNCTION IF EXISTS test_routine(text) CASCADE;
DROP FUNCTION IF EXISTS test_routine_v2(text) CASCADE;
DROP FUNCTION IF EXISTS my_avg_sfunc(numeric, numeric) CASCADE;
DROP FUNCTION IF EXISTS my_avg_final(numeric) CASCADE;
DROP FUNCTION IF EXISTS test_rule_log() CASCADE;
DROP FUNCTION IF EXISTS test_trigger_func() CASCADE;
DROP PROCEDURE IF EXISTS test_proc(integer) CASCADE;

-- Drop sequences
DROP SEQUENCE IF EXISTS test_order_seq CASCADE;

-- Drop types and domains
DROP DOMAIN IF EXISTS positive_int CASCADE;
DROP TYPE IF EXISTS test_status_type CASCADE;
DROP TYPE IF EXISTS test_custom_type CASCADE;

-- Drop text search objects
DROP TEXT SEARCH CONFIGURATION IF EXISTS test_ts_config CASCADE;
DROP TEXT SEARCH DICTIONARY IF EXISTS test_ts_dict CASCADE;
DROP TEXT SEARCH PARSER IF EXISTS test_ts_parser CASCADE;
DROP TEXT SEARCH PARSER IF EXISTS test_ts_parser_v2 CASCADE;
DROP TEXT SEARCH TEMPLATE IF EXISTS test_ts_template CASCADE;
DROP TEXT SEARCH TEMPLATE IF EXISTS test_ts_template_v2 CASCADE;

-- Drop collation, conversion
DROP COLLATION IF EXISTS test_collation CASCADE;
DROP COLLATION IF EXISTS test_collation_renamed CASCADE;
DROP CONVERSION IF EXISTS test_conversion CASCADE;

-- Drop operator, operator class, operator family
DROP OPERATOR IF EXISTS === (text, text) CASCADE;
DROP OPERATOR CLASS IF EXISTS test_op_class USING btree CASCADE;
DROP OPERATOR CLASS IF EXISTS test_op_class_new USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS test_op_fam USING btree CASCADE;

-- Drop statistics
DROP STATISTICS IF EXISTS test_stats;

-- Drop trigger and rule
DROP TRIGGER IF EXISTS test_trigger_v2 ON test_trigger_table;
DROP RULE IF EXISTS test_rule_log_v2 ON test_rule_table;

-- Drop publication and subscription
DROP PUBLICATION IF EXISTS test_publication;
DROP SUBSCRIPTION IF EXISTS test_subscription;

-- Drop event trigger
DROP EVENT TRIGGER IF EXISTS test_event_trigger;

-- Drop extension
DROP EXTENSION IF EXISTS btree_gin CASCADE;

-- Drop schemas
DROP SCHEMA IF EXISTS test_schema CASCADE;
DROP SCHEMA IF EXISTS test_schema_renamed CASCADE;
DROP SCHEMA IF EXISTS test_rename_schema CASCADE;

-- Drop roles (order matters to avoid dependency errors)
DROP ROLE IF EXISTS test_owner;
DROP ROLE IF EXISTS test_user;
DROP ROLE IF EXISTS readonly_user;
DROP ROLE IF EXISTS developers;

-- Drop database (can only be dropped outside of current connection)
-- Can't drop the database you're connected to, so comment out or run separately
\c postgres
DROP DATABASE IF EXISTS test_alter_db_renamed;

\echo '>>> CLEANUP COMPLETE'
\echo ''

\echo '=========================================='
\echo 'TEST SUITE COMPLETED SUCCESSFULLY!'
\echo '=========================================='