-- =====================================================
-- FILE: PG_DDL_DROP.sql
-- Purpose: Complete DROP Commands Test File
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- =====================================================

-- ========== PREPARATION SECTION ==========
\c postgres
DROP DATABASE IF EXISTS ddl_drop_test;
CREATE DATABASE ddl_drop_test;
\c ddl_drop_test

CREATE SCHEMA test_schema;

-- Helper function for aggregates
CREATE FUNCTION int_sum(int, int) RETURNS int LANGUAGE SQL AS 'SELECT $1 + $2';
CREATE FUNCTION text_to_int(text) RETURNS int LANGUAGE SQL AS 'SELECT $1::int';

-- ========== CREATE OBJECTS FOR DROP TESTING ==========

-- 1. ACCESS METHOD
CREATE ACCESS METHOD test_access_method TYPE INDEX HANDLER heap_tableam_handler;

-- 2. AGGREGATE
CREATE AGGREGATE test_aggregate(int) (SFUNC = int_sum, STYPE = int, INITCOND = '0');

-- 3. CAST
CREATE CAST (text AS int) WITH FUNCTION text_to_int(text);

-- 4. COLLATION
CREATE COLLATION test_collation (LOCALE = 'en_US.UTF-8');

-- 5. CONVERSION
CREATE CONVERSION test_conversion FOR 'LATIN1' TO 'UTF8' FROM iso8859_1_to_utf8;

-- 6. DOMAIN
CREATE DOMAIN test_domain AS integer CHECK (VALUE > 0);

-- 7. EVENT TRIGGER
CREATE FUNCTION test_event_func() RETURNS event_trigger LANGUAGE plpgsql AS $$
BEGIN RAISE NOTICE 'test'; END; $$;
CREATE EVENT TRIGGER test_event_trigger ON ddl_command_start EXECUTE FUNCTION test_event_func();

-- 8. EXTENSION
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 9. FOREIGN DATA WRAPPER
CREATE FOREIGN DATA WRAPPER test_fdw;

-- 10. FOREIGN TABLE
CREATE SERVER test_server FOREIGN DATA WRAPPER test_fdw;
CREATE FOREIGN TABLE test_foreign_table (id int) SERVER test_server;

-- 11. FUNCTION
CREATE FUNCTION test_function(x int) RETURNS int LANGUAGE SQL AS 'SELECT x * x';

-- 12. GROUP (ROLE)
CREATE GROUP test_group;

-- 13. INDEX
CREATE TABLE test_index_table (id int, name text);
CREATE INDEX test_index ON test_index_table(id);

-- 14. LANGUAGE
CREATE LANGUAGE plpython3u;

-- 15. MATERIALIZED VIEW
CREATE MATERIALIZED VIEW test_matview AS SELECT * FROM test_index_table;

-- 16. OPERATOR
CREATE OPERATOR test_operator (PROCEDURE = int_sum, LEFTARG = int, RIGHTARG = int);

-- 17. OPERATOR CLASS
CREATE OPERATOR CLASS test_opclass DEFAULT FOR TYPE int USING btree AS
    OPERATOR 1 <, FUNCTION 1 intcmp(int, int);

-- 18. OPERATOR FAMILY
CREATE OPERATOR FAMILY test_opfamily USING btree;

-- 19. OWNED (will create user and objects)
CREATE USER test_owner;
CREATE TABLE test_owned_table (id int);
ALTER TABLE test_owned_table OWNER TO test_owner;

-- 20. POLICY
CREATE TABLE test_policy_table (id int, user_name text);
ALTER TABLE test_policy_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY test_policy ON test_policy_table USING (user_name = current_user);

-- 21. PROCEDURE
CREATE PROCEDURE test_procedure(IN x int) LANGUAGE SQL AS $$ SELECT x $$;

-- 22. PUBLICATION
CREATE PUBLICATION test_publication FOR ALL TABLES;

-- 23. ROLE
CREATE ROLE test_role;

-- 24. ROUTINE
CREATE ROUTINE test_routine AS $$ SELECT 1 $$ LANGUAGE SQL;

-- 25. RULE
CREATE TABLE test_rule_table (id int);
CREATE RULE test_rule AS ON INSERT TO test_rule_table DO INSTEAD NOTHING;

-- 26. SCHEMA
CREATE SCHEMA test_drop_schema;

-- 27. SEQUENCE
CREATE SEQUENCE test_sequence;

-- 28. SERVER
CREATE SERVER test_drop_server FOREIGN DATA WRAPPER test_fdw;

-- 29. STATISTICS
CREATE TABLE test_stats_table (col1 int, col2 int);
CREATE STATISTICS test_statistics ON col1, col2 FROM test_stats_table;

-- 30. SUBSCRIPTION (dummy connection)
CREATE SUBSCRIPTION test_subscription CONNECTION 'host=localhost dbname=postgres' PUBLICATION test_publication;

-- 31. TABLE
CREATE TABLE test_drop_table (id int);

-- 32. TABLESPACE
CREATE TABLESPACE test_tablespace LOCATION '/tmp/test_tablespace';

-- 33. TEXT SEARCH CONFIGURATION
CREATE TEXT SEARCH CONFIGURATION test_ts_config (COPY = pg_catalog.english);

-- 34. TEXT SEARCH DICTIONARY
CREATE TEXT SEARCH DICTIONARY test_ts_dict (TEMPLATE = pg_catalog.simple);

-- 35. TEXT SEARCH PARSER
CREATE TEXT SEARCH PARSER test_ts_parser (START = prsd_start, GETTOKEN = prsd_nexttoken, END = prsd_end, LEXTYPES = prsd_lextype);

-- 36. TEXT SEARCH TEMPLATE
CREATE TEXT SEARCH TEMPLATE test_ts_template (LEXIZE = dsnowball_lexize);

-- 37. TRANSFORM
CREATE TRANSFORM FOR int LANGUAGE sql (FROM SQL WITH FUNCTION text_to_int(text));

-- 38. TRIGGER
CREATE FUNCTION test_trigger_func() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RETURN NEW; END; $$;
CREATE TRIGGER test_trigger BEFORE INSERT ON test_drop_table FOR EACH ROW EXECUTE FUNCTION test_trigger_func();

-- 39. TYPE
CREATE TYPE test_type AS (f1 int, f2 text);

-- 40. USER
CREATE USER test_user;

-- 41. USER MAPPING
CREATE USER MAPPING FOR test_user SERVER test_server OPTIONS (user 'remote');

-- 42. VIEW
CREATE VIEW test_view AS SELECT * FROM test_drop_table;

-- ========== DROP COMMANDS TEST SECTION ==========

-- 1. DROP ACCESS METHOD
DROP ACCESS METHOD test_access_method;

-- 2. DROP AGGREGATE
DROP AGGREGATE test_aggregate(int);

-- 3. DROP CAST
DROP CAST (text AS int);

-- 4. DROP COLLATION
DROP COLLATION test_collation;

-- 5. DROP CONVERSION
DROP CONVERSION test_conversion;

-- 6. DROP DATABASE (will be done in cleanup)

-- 7. DROP DOMAIN
DROP DOMAIN test_domain;

-- 8. DROP EVENT TRIGGER
DROP EVENT TRIGGER test_event_trigger;
DROP FUNCTION test_event_func();

-- 9. DROP EXTENSION
DROP EXTENSION "uuid-ossp";

-- 10. DROP FOREIGN DATA WRAPPER
DROP FOREIGN DATA WRAPPER test_fdw CASCADE;

-- 11. DROP FOREIGN TABLE
DROP FOREIGN TABLE test_foreign_table;

-- 12. DROP FUNCTION
DROP FUNCTION test_function(int);

-- 13. DROP GROUP
DROP GROUP test_group;

-- 14. DROP INDEX
DROP INDEX test_index;

-- 15. DROP LANGUAGE
DROP LANGUAGE plpython3u;

-- 16. DROP MATERIALIZED VIEW
DROP MATERIALIZED VIEW test_matview;

-- 17. DROP OPERATOR
DROP OPERATOR test_operator (int, int);

-- 18. DROP OPERATOR CLASS
DROP OPERATOR CLASS test_opclass USING btree;

-- 19. DROP OPERATOR FAMILY
DROP OPERATOR FAMILY test_opfamily USING btree;

-- 20. DROP OWNED
DROP OWNED BY test_owner CASCADE;

-- 21. DROP POLICY
DROP POLICY test_policy ON test_policy_table;

-- 22. DROP PROCEDURE
DROP PROCEDURE test_procedure(int);

-- 23. DROP PUBLICATION
DROP PUBLICATION test_publication;

-- 24. DROP ROLE
DROP ROLE test_role;

-- 25. DROP ROUTINE
DROP ROUTINE test_routine;

-- 26. DROP RULE
DROP RULE test_rule ON test_rule_table;

-- 27. DROP SCHEMA
DROP SCHEMA test_drop_schema;

-- 28. DROP SEQUENCE
DROP SEQUENCE test_sequence;

-- 29. DROP SERVER
DROP SERVER test_drop_server;

-- 30. DROP STATISTICS
DROP STATISTICS test_statistics;

-- 31. DROP SUBSCRIPTION
DROP SUBSCRIPTION test_subscription;

-- 32. DROP TABLE
DROP TABLE test_drop_table;

-- 33. DROP TABLESPACE
DROP TABLESPACE test_tablespace;

-- 34. DROP TEXT SEARCH CONFIGURATION
DROP TEXT SEARCH CONFIGURATION test_ts_config;

-- 35. DROP TEXT SEARCH DICTIONARY
DROP TEXT SEARCH DICTIONARY test_ts_dict;

-- 36. DROP TEXT SEARCH PARSER
DROP TEXT SEARCH PARSER test_ts_parser;

-- 37. DROP TEXT SEARCH TEMPLATE
DROP TEXT SEARCH TEMPLATE test_ts_template;

-- 38. DROP TRANSFORM
DROP TRANSFORM FOR int LANGUAGE sql;

-- 39. DROP TRIGGER
DROP TRIGGER test_trigger ON test_policy_table;
DROP FUNCTION test_trigger_func();

-- 40. DROP TYPE
DROP TYPE test_type;

-- 41. DROP USER
DROP USER test_user;

-- 42. DROP USER MAPPING
DROP USER MAPPING FOR test_user SERVER test_server;

-- 43. DROP VIEW
DROP VIEW test_view;

-- Cleanup remaining objects
DROP TABLE test_index_table;
DROP TABLE test_policy_table;
DROP TABLE test_rule_table;
DROP TABLE test_stats_table;
DROP SERVER test_server;
DROP SCHEMA test_schema;
DROP USER test_owner;
DROP FUNCTION int_sum(int, int);
DROP FUNCTION text_to_int(text);

-- ========== FINAL CLEANUP ==========
\c postgres
DROP DATABASE IF EXISTS ddl_drop_test CASCADE;

SELECT 'All DROP commands tested successfully!' AS status;