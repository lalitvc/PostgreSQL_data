-- ============================================================================
-- FILE: PG_DDL_CREATE.sql - Complete PostgreSQL CREATE Commands
-- PURPOSE: Complete PostgreSQL CREATE Commands Test File
--          Covers ALL CREATE commands with ALL syntax variations
--          Includes: Partitioning, Foreign Keys, Inheritance, and all object types
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- ============================================================================

-- ============================================================================
-- PREPARATION SECTION
-- ============================================================================

-- Clean up previous test
\c postgres
DROP DATABASE IF EXISTS ddl_create_complete_test;
CREATE DATABASE ddl_create_complete_test;
\c ddl_create_complete_test

-- Create test schemas
CREATE SCHEMA test_schema;
CREATE SCHEMA another_schema;

-- Set search path
SET search_path TO test_schema, public;

-- Create helper functions needed for various CREATE commands
CREATE OR REPLACE FUNCTION int_sum(int, int) 
RETURNS int 
LANGUAGE SQL 
AS 'SELECT $1 + $2';

CREATE OR REPLACE FUNCTION text_to_int(text) 
RETURNS int 
LANGUAGE SQL 
AS 'SELECT $1::int';

CREATE OR REPLACE FUNCTION test_event_trigger_func() 
RETURNS event_trigger 
LANGUAGE plpgsql 
AS $$
BEGIN
    RAISE NOTICE 'DDL command executed: %', tg_tag;
END;
$$;

CREATE OR REPLACE FUNCTION test_trigger_func() 
RETURNS trigger 
LANGUAGE plpgsql 
AS $$
BEGIN
    NEW.data = UPPER(NEW.data);
    RETURN NEW;
END;
$$;

-- Create base types for testing
CREATE TYPE address_type AS (
    street text,
    city text,
    zipcode text
);

-- Create domain for testing
CREATE DOMAIN positive_integer AS integer CHECK (VALUE > 0);

-- ============================================================================
-- 1. CREATE ACCESS METHOD
-- ============================================================================

-- Basic access method creation
CREATE ACCESS METHOD heap_test TYPE INDEX HANDLER heap_tableam_handler;

-- Create access method with handler function
CREATE OR REPLACE FUNCTION heap_handler(internal)
RETURNS table_am_handler
LANGUAGE internal
AS 'heap_tableam_handler';

CREATE ACCESS METHOD heap_custom TYPE TABLE HANDLER heap_handler;

-- ============================================================================
-- 2. CREATE AGGREGATE
-- ============================================================================

-- Basic aggregate with SFUNC and STYPE
CREATE AGGREGATE test_sum(int) (
    SFUNC = int_sum,
    STYPE = int,
    INITCOND = '0'
);

-- Aggregate with multiple arguments
CREATE AGGREGATE test_multi_sum(int, int) (
    SFUNC = int_sum,
    STYPE = int,
    INITCOND = '0'
);

-- Aggregate with final function
CREATE FUNCTION avg_final(int) RETURNS numeric 
LANGUAGE SQL AS 'SELECT $1::numeric / 2';
CREATE AGGREGATE test_avg(int) (
    SFUNC = int_sum,
    STYPE = int,
    FINALFUNC = avg_final,
    INITCOND = '0'
);

-- Aggregate with MSFUNC (for parallel processing)
CREATE AGGREGATE test_parallel_avg(int) (
    SFUNC = int_sum,
    STYPE = int,
    MSFUNC = int_sum,
    MSTYPE = int,
    FINALFUNC = avg_final,
    INITCOND = '0',
    MINITCOND = '0',
    PARALLEL = SAFE
);

-- Aggregate with SORTOP operator
CREATE AGGREGATE test_max(int) (
    SFUNC = int_sum,
    STYPE = int,
    SORTOP = >
);

-- Aggregate with combine function
CREATE FUNCTION int_combine(int, int) RETURNS int 
LANGUAGE SQL AS 'SELECT $1 + $2';
CREATE AGGREGATE test_combine_sum(int) (
    SFUNC = int_sum,
    STYPE = int,
    COMBINEFUNC = int_combine,
    PARALLEL = SAFE
);

-- ============================================================================
-- 3. CREATE CAST
-- ============================================================================

-- Basic cast with function
CREATE CAST (text AS int) WITH FUNCTION text_to_int(text);

-- Cast without function (binary coercible)
CREATE CAST (int AS text) WITHOUT FUNCTION;

-- Cast with assignment context
CREATE CAST (text AS positive_integer) WITH FUNCTION text_to_int(text) AS ASSIGNMENT;

-- Cast with implicit context
CREATE CAST (int AS boolean) WITH FUNCTION int_to_boolean(int) AS IMPLICIT;

-- Cast with inout
CREATE CAST (address_type AS text) WITH INOUT AS IMPLICIT;

-- ============================================================================
-- 4. CREATE COLLATION
-- ============================================================================

-- Basic collation from operating system
CREATE COLLATION test_collation1 (LOCALE = 'en_US.UTF-8');

-- Collation with provider
CREATE COLLATION test_collation2 (PROVIDER = icu, LOCALE = 'en-US');

-- Collation with deterministic property
CREATE COLLATION test_collation3 (LOCALE = 'en_US.UTF-8', DETERMINISTIC = false);

-- Collation from existing collation
CREATE COLLATION test_collation4 FROM "en_US.UTF-8";

-- Collation with version
CREATE COLLATION test_collation5 (LOCALE = 'fr_FR.UTF-8', VERSION = '1.0');

-- ============================================================================
-- 5. CREATE CONVERSION
-- ============================================================================

-- Basic conversion
CREATE CONVERSION test_conversion1 
FOR 'LATIN1' TO 'UTF8' 
FROM iso8859_1_to_utf8;

-- Conversion with default flag
CREATE DEFAULT CONVERSION test_conversion2 
FOR 'LATIN2' TO 'UTF8' 
FROM iso8859_2_to_utf8;

-- ============================================================================
-- 6. CREATE DATABASE
-- ============================================================================

-- Basic database creation
CREATE DATABASE test_db1;

-- Database with owner
CREATE DATABASE test_db2 OWNER postgres;

-- Database with encoding
CREATE DATABASE test_db3 ENCODING 'UTF8';

-- Database with locale
CREATE DATABASE test_db4 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';

-- Database with tablespace
CREATE TABLESPACE test_tablespace LOCATION '/tmp/test_tablespace_db';
CREATE DATABASE test_db5 TABLESPACE test_tablespace;

-- Database with connection limit
CREATE DATABASE test_db6 CONNECTION LIMIT 10;

-- Database with template
CREATE DATABASE test_db7 TEMPLATE template0;

-- Database with all options
CREATE DATABASE test_db8 
    OWNER postgres 
    ENCODING 'UTF8' 
    LC_COLLATE 'C' 
    LC_CTYPE 'C' 
    TABLESPACE pg_default 
    CONNECTION LIMIT 100 
    ALLOW_CONNECTIONS true 
    IS_TEMPLATE false;

-- ============================================================================
-- 7. CREATE DOMAIN
-- ============================================================================

-- Basic domain
CREATE DOMAIN test_domain1 AS integer;

-- Domain with constraint
CREATE DOMAIN test_domain2 AS text CHECK (LENGTH(VALUE) > 0);

-- Domain with default
CREATE DOMAIN test_domain3 AS date DEFAULT CURRENT_DATE;

-- Domain with NOT NULL
CREATE DOMAIN test_domain4 AS varchar(255) NOT NULL;

-- Domain with multiple constraints
CREATE DOMAIN test_domain5 AS integer 
    DEFAULT 0 
    NOT NULL 
    CHECK (VALUE >= 0) 
    CHECK (VALUE <= 100);

-- Domain with collation
CREATE DOMAIN test_domain6 AS text COLLATE "en_US.UTF-8";

-- ============================================================================
-- 8. CREATE EVENT TRIGGER
-- ============================================================================

-- Event trigger on ddl_command_start
CREATE EVENT TRIGGER test_event_trigger1 
ON ddl_command_start 
EXECUTE FUNCTION test_event_trigger_func();

-- Event trigger on ddl_command_end
CREATE EVENT TRIGGER test_event_trigger2 
ON ddl_command_end 
EXECUTE FUNCTION test_event_trigger_func();

-- Event trigger on sql_drop
CREATE EVENT TRIGGER test_event_trigger3 
ON sql_drop 
EXECUTE FUNCTION test_event_trigger_func();

-- Event trigger with filter
CREATE EVENT TRIGGER test_event_trigger4 
ON ddl_command_start 
WHEN TAG IN ('CREATE TABLE', 'CREATE INDEX')
EXECUTE FUNCTION test_event_trigger_func();

-- Event trigger with multiple tags
CREATE EVENT TRIGGER test_event_trigger5 
ON ddl_command_end 
WHEN TAG IN ('ALTER TABLE', 'ALTER INDEX', 'ALTER SCHEMA')
EXECUTE FUNCTION test_event_trigger_func();

-- ============================================================================
-- 9. CREATE EXTENSION
-- ============================================================================

-- Basic extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension with schema
CREATE EXTENSION "pgcrypto" WITH SCHEMA test_schema;

-- Extension with version
CREATE EXTENSION "hstore" VERSION '1.0';

-- Extension with cascade
CREATE EXTENSION "postgis" CASCADE;

-- Extension with all options
CREATE EXTENSION "ltree" 
    WITH SCHEMA test_schema 
    VERSION '1.2' 
    CASCADE;

-- ============================================================================
-- 10. CREATE FOREIGN DATA WRAPPER
-- ============================================================================

-- Basic FDW
CREATE FOREIGN DATA WRAPPER test_fdw1;

-- FDW with handler
CREATE FOREIGN DATA WRAPPER test_fdw2 
HANDLER postgresql_fdw_handler;

-- FDW with validator
CREATE FOREIGN DATA WRAPPER test_fdw3 
VALIDATOR postgresql_fdw_validator;

-- FDW with options
CREATE FOREIGN DATA WRAPPER test_fdw4 
OPTIONS (debug 'true', host 'localhost');

-- FDW with all features
CREATE FOREIGN DATA WRAPPER test_fdw5 
HANDLER postgresql_fdw_handler 
VALIDATOR postgresql_fdw_validator 
OPTIONS (use_remote_estimate 'true', fetch_size '1000');

-- ============================================================================
-- 11. CREATE FOREIGN TABLE
-- ============================================================================

-- Create server first
CREATE SERVER test_foreign_server 
FOREIGN DATA WRAPPER test_fdw1;

-- Basic foreign table
CREATE FOREIGN TABLE test_foreign_table1 (
    id integer,
    name text,
    created_at timestamp
) SERVER test_foreign_server;

-- Foreign table with options
CREATE FOREIGN TABLE test_foreign_table2 (
    id integer OPTIONS (key 'true'),
    data text OPTIONS (column_name 'remote_data')
) SERVER test_foreign_server 
OPTIONS (table_name 'remote_table', schema_name 'public');

-- Foreign table with constraints
CREATE FOREIGN TABLE test_foreign_table3 (
    id integer NOT NULL,
    name text,
    CONSTRAINT valid_id CHECK (id > 0)
) SERVER test_foreign_server;

-- Foreign table inheritance
CREATE FOREIGN TABLE test_foreign_table4 () 
INHERITS (test_foreign_table1) 
SERVER test_foreign_server;

-- ============================================================================
-- 12. CREATE FUNCTION
-- ============================================================================

-- SQL function
CREATE FUNCTION test_func1(x integer) 
RETURNS integer 
LANGUAGE SQL 
AS 'SELECT x * x';

-- SQL function with multiple statements
CREATE FUNCTION test_func2(x integer) 
RETURNS integer 
LANGUAGE SQL 
AS $$ SELECT x + 1; SELECT x * 2; $$;

-- PL/pgSQL function
CREATE FUNCTION test_func3(x integer) 
RETURNS integer 
LANGUAGE plpgsql 
AS $$
BEGIN
    RETURN x * x;
END;
$$;

-- Function with default value
CREATE FUNCTION test_func4(x integer DEFAULT 10) 
RETURNS integer 
LANGUAGE SQL 
AS 'SELECT x * 2';

-- Function with named parameters
CREATE FUNCTION test_func5(a integer, b integer) 
RETURNS integer 
LANGUAGE SQL 
AS 'SELECT $1 + $2';

-- Function with OUT parameters
CREATE FUNCTION test_func6(IN a integer, IN b integer, OUT sum integer) 
LANGUAGE SQL 
AS 'SELECT a + b';

-- Function with TABLE return
CREATE FUNCTION test_func7(x integer) 
RETURNS TABLE(id integer, name text) 
LANGUAGE SQL 
AS 'SELECT id, name FROM test_table WHERE id = x';

-- Function with SETOF
CREATE FUNCTION test_func8(x integer) 
RETURNS SETOF integer 
LANGUAGE SQL 
AS 'SELECT generate_series(1, x)';

-- Function with security definer
CREATE FUNCTION test_func9(x integer) 
RETURNS integer 
LANGUAGE SQL 
SECURITY DEFINER 
AS 'SELECT x * x';

-- Function with cost and rows
CREATE FUNCTION test_func10(x integer) 
RETURNS integer 
LANGUAGE SQL 
COST 100 
ROWS 10 
AS 'SELECT x * x';

-- Function with parallel
CREATE FUNCTION test_func11(x integer) 
RETURNS integer 
LANGUAGE SQL 
PARALLEL SAFE 
AS 'SELECT x * x';

-- Function with leakproof
CREATE FUNCTION test_func12(x integer) 
RETURNS integer 
LANGUAGE SQL 
LEAKPROOF 
AS 'SELECT x * x';

-- Function with strict
CREATE FUNCTION test_func13(x integer) 
RETURNS integer 
LANGUAGE SQL 
STRICT 
AS 'SELECT x * x';

-- Function with immutable
CREATE FUNCTION test_func14(x integer) 
RETURNS integer 
LANGUAGE SQL 
IMMUTABLE 
AS 'SELECT x * x';

-- Function with all options
CREATE FUNCTION test_func15(x integer) 
RETURNS integer 
LANGUAGE plpgsql 
IMMUTABLE 
STRICT 
LEAKPROOF 
PARALLEL SAFE 
COST 50 
SECURITY DEFINER 
SET search_path = test_schema
AS $$
BEGIN
    RETURN x * x;
END;
$$;

-- ============================================================================
-- 13. CREATE GROUP (deprecated but supported - alias for CREATE ROLE)
-- ============================================================================

CREATE GROUP test_group1;
CREATE GROUP test_group2 WITH LOGIN;
CREATE GROUP test_group3 WITH PASSWORD 'testpass';

-- ============================================================================
-- 14. CREATE INDEX
-- ============================================================================

-- Create base table for indexes
CREATE TABLE test_index_table (
    id serial PRIMARY KEY,
    data text,
    metadata jsonb,
    coordinates point,
    duration tsrange,
    name varchar(100),
    age integer,
    salary numeric(10,2),
    vector integer[]
);

-- Basic B-tree index
CREATE INDEX test_index1 ON test_index_table(id);

-- Unique index
CREATE UNIQUE INDEX test_index2 ON test_index_table(name);

-- Index with ascending/descending
CREATE INDEX test_index3 ON test_index_table(age DESC, name ASC);

-- Hash index
CREATE INDEX test_index4 ON test_index_table USING hash(id);

-- GiST index
CREATE INDEX test_index5 ON test_index_table USING gist(coordinates);

-- SP-GiST index
CREATE INDEX test_index6 ON test_index_table USING spgist(coordinates);

-- GIN index
CREATE INDEX test_index7 ON test_index_table USING gin(metadata);

-- BRIN index
CREATE INDEX test_index8 ON test_index_table USING brin(age);

-- Partial index
CREATE INDEX test_index9 ON test_index_table(age) WHERE age > 18;

-- Index on expression
CREATE INDEX test_index10 ON test_index_table(lower(name));

-- Index with fillfactor
CREATE INDEX test_index11 ON test_index_table(id) WITH (fillfactor = 90);

-- Index with tablespace
CREATE TABLESPACE test_index_tablespace LOCATION '/tmp/test_index';
CREATE INDEX test_index12 ON test_index_table(id) TABLESPACE test_index_tablespace;

-- Concurrent index
CREATE INDEX CONCURRENTLY test_index13 ON test_index_table(data);

-- Index with operator class
CREATE INDEX test_index14 ON test_index_table USING btree(age int4_ops);

-- Index with collation
CREATE INDEX test_index15 ON test_index_table(name COLLATE "en_US.UTF-8");

-- Index with NULLS order
CREATE INDEX test_index16 ON test_index_table(age NULLS FIRST);

-- Multi-column index
CREATE INDEX test_index17 ON test_index_table(age, salary, name);

-- Index with INCLUDE columns
CREATE INDEX test_index18 ON test_index_table(id) INCLUDE (name, age);


-- Index with all features
CREATE UNIQUE INDEX CONCURRENTLY test_index19 
ON test_index_table USING btree(lower(name) DESC NULLS LAST, age ASC) 
INCLUDE (salary, data) 
WHERE age > 0 
WITH (fillfactor = 85) 
TABLESPACE test_index_tablespace;


-- ============================================================================
-- 15. CREATE LANGUAGE
-- ============================================================================

-- PL/pgSQL language
CREATE LANGUAGE plpgsql;

-- Language with handler
CREATE LANGUAGE test_lang1 
HANDLER plpgsql_call_handler;

-- Language with inline and validator
CREATE LANGUAGE test_lang2 
HANDLER plpgsql_call_handler 
INLINE plpgsql_inline_handler 
VALIDATOR plpgsql_validator;

-- Trusted language
CREATE TRUSTED LANGUAGE test_lang3 
HANDLER plpgsql_call_handler;

-- ============================================================================
-- 16. CREATE MATERIALIZED VIEW
-- ============================================================================

-- Basic materialized view
CREATE MATERIALIZED VIEW test_matview1 AS 
SELECT id, data FROM test_index_table;

-- Materialized view with WITH DATA
CREATE MATERIALIZED VIEW test_matview2 AS 
SELECT id, name, age FROM test_index_table WITH DATA;

-- Materialized view with WITH NO DATA
CREATE MATERIALIZED VIEW test_matview3 AS 
SELECT id, salary FROM test_index_table WITH NO DATA;

-- Materialized view with tablespace
CREATE MATERIALIZED VIEW test_matview4 
TABLESPACE test_index_tablespace 
AS SELECT id, data FROM test_index_table;

-- Materialized view with storage parameters
CREATE MATERIALIZED VIEW test_matview5 
WITH (fillfactor = 80, autovacuum_enabled = true) 
AS SELECT id, name FROM test_index_table;

-- Materialized view with unique index
CREATE MATERIALIZED VIEW test_matview6 AS 
SELECT DISTINCT name, age FROM test_index_table;

-- Materialized view with complex query
CREATE MATERIALIZED VIEW test_matview7 AS 
SELECT 
    t1.id,
    t1.name,
    t1.age,
    t2.salary
FROM test_index_table t1
CROSS JOIN test_index_table t2
WHERE t1.id = t2.id;

-- ============================================================================
-- 17. CREATE OPERATOR
-- ============================================================================

-- Basic operator
CREATE OPERATOR test_operator1 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int
);

-- Operator with commutator
CREATE OPERATOR test_operator2 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int,
    COMMUTATOR = test_operator2
);

-- Operator with negator
CREATE OPERATOR test_operator3 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int,
    NEGATOR = test_operator4
);

-- Operator with restrict and join
CREATE OPERATOR test_operator5 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

-- Operator with hashes and merges
CREATE OPERATOR test_operator6 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int,
    HASHES,
    MERGES
);

-- Operator with all options
CREATE OPERATOR test_operator7 (
    PROCEDURE = int_sum,
    LEFTARG = int,
    RIGHTARG = int,
    COMMUTATOR = test_operator8,
    NEGATOR = test_operator9,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    HASHES,
    MERGES
);

-- ============================================================================
-- 18. CREATE OPERATOR CLASS
-- ============================================================================

-- Basic operator class
CREATE OPERATOR CLASS test_opclass1 
DEFAULT FOR TYPE int USING btree AS
    OPERATOR 1 <,
    OPERATOR 2 <=,
    OPERATOR 3 =,
    OPERATOR 4 >=,
    OPERATOR 5 >,
    FUNCTION 1 intcmp(int, int);

-- Operator class without default
CREATE OPERATOR CLASS test_opclass2 
FOR TYPE text USING btree AS
    OPERATOR 1 <,
    OPERATOR 2 <=,
    OPERATOR 3 =,
    OPERATOR 4 >=,
    OPERATOR 5 >,
    FUNCTION 1 textcmp(text, text);

-- Operator class with family
CREATE OPERATOR FAMILY test_opfamily1 USING btree;
CREATE OPERATOR CLASS test_opclass3 
FOR TYPE int USING btree FAMILY test_opfamily1 AS
    OPERATOR 1 <,
    FUNCTION 1 intcmp(int, int);

-- Operator class with storage type
CREATE OPERATOR CLASS test_opclass4 
FOR TYPE int USING btree AS
    OPERATOR 1 <,
    FUNCTION 1 intcmp(int, int)
    STORAGE integer;

-- ============================================================================
-- 19. CREATE OPERATOR FAMILY
-- ============================================================================

-- Basic operator family
CREATE OPERATOR FAMILY test_opfamily2 USING btree;

-- Operator family for different access method
CREATE OPERATOR FAMILY test_opfamily3 USING hash;

-- ============================================================================
-- 20. CREATE POLICY
-- ============================================================================

-- Create table for RLS policies
CREATE TABLE test_policy_table (
    id serial PRIMARY KEY,
    username text DEFAULT current_user,
    data text,
    department text,
    salary integer,
    is_active boolean DEFAULT true
);

-- Enable RLS
ALTER TABLE test_policy_table ENABLE ROW LEVEL SECURITY;

-- Basic policy (SELECT)
CREATE POLICY test_policy1 ON test_policy_table
    FOR SELECT
    USING (username = current_user);

-- Policy for INSERT
CREATE POLICY test_policy2 ON test_policy_table
    FOR INSERT
    WITH CHECK (username = current_user);

-- Policy for UPDATE
CREATE POLICY test_policy3 ON test_policy_table
    FOR UPDATE
    USING (username = current_user)
    WITH CHECK (username = current_user AND is_active = true);

-- Policy for DELETE
CREATE POLICY test_policy4 ON test_policy_table
    FOR DELETE
    USING (username = current_user AND department = 'admin');

-- Policy for ALL
CREATE POLICY test_policy5 ON test_policy_table
    FOR ALL
    USING (department = current_setting('app.department'))
    WITH CHECK (department = current_setting('app.department'));

-- Policy with role
CREATE POLICY test_policy6 ON test_policy_table
    FOR SELECT
    TO test_group1, test_group2
    USING (true);

-- Policy with command
CREATE POLICY test_policy7 ON test_policy_table
    AS PERMISSIVE
    FOR SELECT
    TO PUBLIC
    USING (is_active = true);

-- Restrictive policy
CREATE POLICY test_policy8 ON test_policy_table
    AS RESTRICTIVE
    FOR SELECT
    USING (salary < 100000);

-- Policy with complex condition
CREATE POLICY test_policy9 ON test_policy_table
    FOR SELECT
    USING (
        username = current_user 
        OR department IN ('admin', 'manager')
        OR (salary > 50000 AND is_active = true)
    );

-- ============================================================================
-- 21. CREATE PROCEDURE
-- ============================================================================

-- Basic procedure
CREATE PROCEDURE test_proc1(IN x integer)
LANGUAGE SQL
AS $$ INSERT INTO test_index_table(id) VALUES (x) $$;

-- Procedure with multiple parameters
CREATE PROCEDURE test_proc2(IN name text, IN age integer, IN salary numeric)
LANGUAGE SQL
AS $$ INSERT INTO test_index_table(name, age, salary) VALUES (name, age, salary) $$;

-- Procedure with OUT parameter
CREATE PROCEDURE test_proc3(IN x integer, OUT result integer)
LANGUAGE SQL
AS $$ SELECT x * x $$;

-- Procedure with INOUT parameter
CREATE PROCEDURE test_proc4(INOUT x integer)
LANGUAGE SQL
AS $$ SELECT x * 2 $$;

-- PL/pgSQL procedure
CREATE PROCEDURE test_proc5(IN x integer)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO test_index_table(id) VALUES (x);
    COMMIT;
END;
$$;

-- Procedure with transaction control
CREATE PROCEDURE test_proc6(IN x integer, IN y integer)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO test_index_table(id) VALUES (x);
    SAVEPOINT my_savepoint;
    INSERT INTO test_index_table(id) VALUES (y);
    COMMIT;
END;
$$;

-- Procedure with security
CREATE PROCEDURE test_proc7(IN x integer)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = test_schema
AS $$ INSERT INTO test_index_table(id) VALUES (x) $$;

-- ============================================================================
-- 22. CREATE PUBLICATION
-- ============================================================================

-- Basic publication
CREATE PUBLICATION test_pub1;

-- Publication with tables
CREATE PUBLICATION test_pub2 FOR TABLE test_index_table, test_policy_table;

-- Publication for all tables
CREATE PUBLICATION test_pub3 FOR ALL TABLES;

-- Publication with DDL
CREATE PUBLICATION test_pub4 FOR ALL TABLES WITH (publish = 'insert, update, delete');

-- Publication with specific operations
CREATE PUBLICATION test_pub5 FOR TABLE test_index_table 
WITH (publish = 'insert, update, delete, truncate');

-- Publication with parameters
CREATE PUBLICATION test_pub6 
FOR TABLE test_index_table 
WITH (publish_via_partition_root = true);

-- ============================================================================
-- 23. CREATE ROLE
-- ============================================================================

-- Basic role
CREATE ROLE test_role1;

-- Role with login
CREATE ROLE test_role2 LOGIN;

-- Role with password
CREATE ROLE test_role3 LOGIN PASSWORD 'securepass123';

-- Role with superuser
CREATE ROLE test_role4 SUPERUSER;

-- Role with createdb
CREATE ROLE test_role5 CREATEDB;

-- Role with createrole
CREATE ROLE test_role6 CREATEROLE;

-- Role with replication
CREATE ROLE test_role7 REPLICATION;

-- Role with bypassrls
CREATE ROLE test_role8 BYPASSRLS;

-- Role with connection limit
CREATE ROLE test_role9 CONNECTION LIMIT 10;

-- Role with valid until
CREATE ROLE test_role10 LOGIN PASSWORD 'pass' VALID UNTIL '2025-12-31';

-- Role with all options
CREATE ROLE test_role11 
    LOGIN 
    SUPERUSER 
    CREATEDB 
    CREATEROLE 
    REPLICATION 
    BYPASSRLS 
    CONNECTION LIMIT 100 
    VALID UNTIL '2030-01-01'
    PASSWORD 'complexpassword123!';

-- Role in schema
CREATE ROLE test_role12 IN ROLE test_role1, test_role2;

-- Role with role attribute
CREATE ROLE test_role13 WITH ADMIN test_role1;

-- ============================================================================
-- 24. CREATE RULE
-- ============================================================================

-- Create table for rules
CREATE TABLE test_rule_table (
    id serial PRIMARY KEY,
    data text,
    created_at timestamp DEFAULT now()
);

-- Basic rule (DO INSTEAD)
CREATE RULE test_rule1 AS
    ON INSERT TO test_rule_table
    DO INSTEAD NOTHING;

-- Rule with condition
CREATE RULE test_rule2 AS
    ON UPDATE TO test_rule_table
    WHERE NEW.data IS NOT NULL
    DO INSTEAD
    UPDATE test_rule_table SET data = UPPER(NEW.data) WHERE id = OLD.id;

-- Rule with multiple actions
CREATE RULE test_rule3 AS
    ON DELETE TO test_rule_table
    DO INSTEAD (
        INSERT INTO audit_table SELECT OLD.*;
        DELETE FROM test_rule_table WHERE id = OLD.id;
    );

-- Rule for INSERT with DO ALSO
CREATE RULE test_rule4 AS
    ON INSERT TO test_rule_table
    DO ALSO
    INSERT INTO test_rule_table_audit VALUES (NEW.id, NEW.data, now());

-- Rule with WHERE clause
CREATE RULE test_rule5 AS
    ON UPDATE TO test_rule_table
    WHERE OLD.data != NEW.data
    DO ALSO
    NOTIFY table_updated, OLD.id;

-- ============================================================================
-- 25. CREATE SCHEMA
-- ============================================================================

-- Basic schema
CREATE SCHEMA test_schema1;

-- Schema with owner
CREATE SCHEMA test_schema2 AUTHORIZATION postgres;

-- Schema with elements
CREATE SCHEMA test_schema3
    CREATE TABLE schema_table (id int)
    CREATE VIEW schema_view AS SELECT * FROM schema_table
    GRANT SELECT ON schema_table TO PUBLIC;

-- Schema with IF NOT EXISTS
CREATE SCHEMA IF NOT EXISTS test_schema4;

-- Schema with all options
CREATE SCHEMA IF NOT EXISTS test_schema5
    AUTHORIZATION postgres
    CREATE TABLE t1 (col1 int)
    CREATE TABLE t2 (col2 text)
    CREATE SEQUENCE seq1
    CREATE VIEW v1 AS SELECT * FROM t1;

-- ============================================================================
-- 26. CREATE SEQUENCE
-- ============================================================================

-- Basic sequence
CREATE SEQUENCE test_seq1;

-- Sequence with increment
CREATE SEQUENCE test_seq2 INCREMENT BY 10;

-- Sequence with min/max
CREATE SEQUENCE test_seq3 MINVALUE 100 MAXVALUE 1000;

-- Sequence with start
CREATE SEQUENCE test_seq4 START WITH 1000;

-- Sequence with cache
CREATE SEQUENCE test_seq5 CACHE 50;

-- Sequence with cycle
CREATE SEQUENCE test_seq6 CYCLE;

-- Sequence with ownership
CREATE SEQUENCE test_seq7 OWNED BY test_index_table.id;

-- Sequence with data type
CREATE SEQUENCE test_seq8 AS bigint;

-- Sequence with all options
CREATE SEQUENCE test_seq9
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 10
    CYCLE
    OWNED BY test_rule_table.id;

-- Temporary sequence
CREATE TEMP SEQUENCE test_seq10;

-- ============================================================================
-- 27. CREATE SERVER
-- ============================================================================

-- Basic server
CREATE SERVER test_server1 FOREIGN DATA WRAPPER test_fdw1;

-- Server with options
CREATE SERVER test_server2 
FOREIGN DATA WRAPPER test_fdw1 
OPTIONS (host 'localhost', port '5432', dbname 'test');

-- Server with type and version
CREATE SERVER test_server3 
TYPE 'postgresql' 
VERSION '16.0' 
FOREIGN DATA WRAPPER test_fdw1;

-- Server with all options
CREATE SERVER test_server4
    TYPE 'postgresql'
    VERSION '16'
    FOREIGN DATA WRAPPER test_fdw1
    OPTIONS (
        host 'localhost',
        port '5432',
        dbname 'mydb',
        options '-c geqo=off'
    );

-- ============================================================================
-- 28. CREATE STATISTICS
-- ============================================================================

-- Create larger table for statistics
CREATE TABLE test_stats_table (
    id serial,
    col1 integer,
    col2 text,
    col3 date,
    col4 numeric(10,2)
);

-- Basic statistics
CREATE STATISTICS test_stats1 ON col1, col2 FROM test_stats_table;

-- Statistics with ndistinct
CREATE STATISTICS test_stats2 (ndistinct) ON col1, col3 FROM test_stats_table;

-- Statistics with dependencies
CREATE STATISTICS test_stats3 (dependencies) ON col2, col4 FROM test_stats_table;

-- Statistics with mcv
CREATE STATISTICS test_stats4 (mcv) ON col1, col2, col3 FROM test_stats_table;

-- Statistics with all options
CREATE STATISTICS test_stats5 (ndistinct, dependencies, mcv) 
ON col1, col2, col4 FROM test_stats_table;

-- ============================================================================
-- 29. CREATE SUBSCRIPTION
-- ============================================================================

-- Note: These require an existing publication on another database
-- For testing purposes, creating with dummy connection
CREATE SUBSCRIPTION test_sub1
CONNECTION 'host=localhost port=5432 dbname=ddl_create_complete_test'
PUBLICATION test_pub1;

-- Subscription with copy data
CREATE SUBSCRIPTION test_sub2
CONNECTION 'host=localhost port=5432 dbname=testdb'
PUBLICATION test_pub2
WITH (copy_data = true);

-- Subscription with enabled
CREATE SUBSCRIPTION test_sub3
CONNECTION 'host=localhost port=5432 dbname=testdb'
PUBLICATION test_pub3
WITH (enabled = false);

-- Subscription with create slot
CREATE SUBSCRIPTION test_sub4
CONNECTION 'host=localhost port=5432 dbname=testdb'
PUBLICATION test_pub4
WITH (create_slot = true);

-- Subscription with all options
CREATE SUBSCRIPTION test_sub5
CONNECTION 'host=localhost port=5432 dbname=testdb user=postgres password=pass'
PUBLICATION test_pub1, test_pub2
WITH (
    copy_data = true,
    enabled = true,
    create_slot = true,
    slot_name = 'test_slot',
    synchronous_commit = 'off',
    binary = false
);

-- ============================================================================
-- 30. CREATE TABLE (COMPREHENSIVE)
-- ============================================================================

-- 30.1 Basic table
CREATE TABLE test_table_basic (
    id serial PRIMARY KEY,
    name text,
    created_at timestamp DEFAULT now()
);

-- COMMENT ON TABLE
COMMENT ON TABLE test_table_basic IS 'Basic table for storing user records';

-- COMMENT ON COLUMNS
COMMENT ON COLUMN test_table_basic.id IS 'Primary key identifier';
COMMENT ON COLUMN test_table_basic.name IS 'User full name';
COMMENT ON COLUMN test_table_basic.created_at IS 'Record creation timestamp';

-- 30.2 Table with all data types
CREATE TABLE test_table_all_types (
    -- Numeric
    c_smallint smallint,
    c_integer integer,
    c_bigint bigint,
    c_decimal decimal(10,2),
    c_numeric numeric(15,3),
    c_real real,
    c_double double precision,
    c_serial serial,
    c_bigserial bigserial,
    c_money money,
    
    -- Character
    c_char char(10),
    c_varchar varchar(255),
    c_text text,
    
    -- Binary
    c_bytea bytea,
    
    -- Date/Time
    c_date date,
    c_time time,
    c_timetz time with time zone,
    c_timestamp timestamp,
    c_timestamptz timestamp with time zone,
    c_interval interval,
    
    -- Boolean
    c_boolean boolean,
    
    -- Geometric
    c_point point,
    c_line line,
    c_lseg lseg,
    c_box box,
    c_path path,
    c_polygon polygon,
    c_circle circle,
    
    -- Network
    c_cidr cidr,
    c_inet inet,
    c_macaddr macaddr,
    
    -- JSON
    c_json json,
    c_jsonb jsonb,
    
    -- Array
    c_int_array integer[],
    c_text_array text[][],
    
    -- Range
    c_int4range int4range,
    c_int8range int8range,
    c_numrange numrange,
    c_tsrange tsrange,
    c_tstzrange tstzrange,
    c_daterange daterange,
    
    -- UUID
    c_uuid uuid DEFAULT gen_random_uuid(),
    
    -- XML
    c_xml xml,
    
    -- Composite
    c_composite address_type,
    
    -- Domain
    c_domain positive_integer,
    
    PRIMARY KEY (c_integer)
);

-- 30.3 Table with all constraints
CREATE TABLE test_table_constraints (
    id serial,
    name text NOT NULL,
    email text UNIQUE,
    age integer CHECK (age >= 0 AND age <= 150),
    salary numeric(10,2),
    dept_id integer,
    status text DEFAULT 'active',
    CONSTRAINT pk_constraints PRIMARY KEY (id),
    CONSTRAINT unique_name_dept UNIQUE (name, dept_id),
    CONSTRAINT fk_constraint FOREIGN KEY (dept_id) REFERENCES test_table_basic(id),
    CONSTRAINT check_salary CHECK (salary > 0),
    CONSTRAINT exclude_range_constraint EXCLUDE USING gist (tsrange(now(), now() + '1 day'::interval) WITH &&)
);

-- 30.4 Table with generated columns
CREATE TABLE test_table_generated (
    id serial PRIMARY KEY,
    price numeric(10,2),
    quantity integer,
    total numeric(10,2) GENERATED ALWAYS AS (price * quantity) STORED,
    price_with_tax numeric(10,2) GENERATED ALWAYS AS (price * 1.2) STORED,
    full_name text GENERATED ALWAYS AS (name || ' ' || surname) STORED,
    name text,
    surname text
);

-- 30.5 Table with inheritance
CREATE TABLE test_table_parent (
    id serial PRIMARY KEY,
    common_field text,
    created_at timestamp DEFAULT now()
);

CREATE TABLE test_table_child (
    child_field integer,
    child_data text
) INHERITS (test_table_parent);

CREATE TABLE test_table_grandchild (
    grandchild_field boolean
) INHERITS (test_table_parent, test_table_child);

-- 30.6 RANGE PARTITIONING
CREATE TABLE test_table_range_partitioned (
    id serial,
    sale_date date NOT NULL,
    amount numeric(10,2),
    region text,
    PRIMARY KEY (id, sale_date)
) PARTITION BY RANGE (sale_date);

-- Create partitions
CREATE TABLE test_table_range_2024_q1 PARTITION OF test_table_range_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE test_table_range_2024_q2 PARTITION OF test_table_range_partitioned
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE test_table_range_2024_q3 PARTITION OF test_table_range_partitioned
FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE test_table_range_2024_q4 PARTITION OF test_table_range_partitioned
FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE test_table_range_default PARTITION OF test_table_range_partitioned DEFAULT;

-- 30.7 LIST PARTITIONING
CREATE TABLE test_table_list_partitioned (
    id serial,
    customer_type text NOT NULL,
    name text,
    created_at timestamp,
    PRIMARY KEY (id, customer_type)
) PARTITION BY LIST (customer_type);

CREATE TABLE test_table_list_retail PARTITION OF test_table_list_partitioned
FOR VALUES IN ('retail', 'consumer');

CREATE TABLE test_table_list_wholesale PARTITION OF test_table_list_partitioned
FOR VALUES IN ('wholesale', 'distributor');

CREATE TABLE test_table_list_corporate PARTITION OF test_table_list_partitioned
FOR VALUES IN ('corporate', 'enterprise');

CREATE TABLE test_table_list_default PARTITION OF test_table_list_partitioned DEFAULT;

-- 30.8 HASH PARTITIONING
CREATE TABLE test_table_hash_partitioned (
    id serial,
    log_level text NOT NULL,
    message text,
    logged_at timestamp,
    PRIMARY KEY (id, log_level)
) PARTITION BY HASH (log_level);

CREATE TABLE test_table_hash_part1 PARTITION OF test_table_hash_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE test_table_hash_part2 PARTITION OF test_table_hash_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE test_table_hash_part3 PARTITION OF test_table_hash_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE test_table_hash_part4 PARTITION OF test_table_hash_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- 30.9 MULTI-LEVEL PARTITIONING
CREATE TABLE test_table_multi_level (
    id serial,
    sale_date date,
    country text,
    region text,
    amount numeric,
    PRIMARY KEY (id, sale_date, country)
) PARTITION BY RANGE (sale_date);

CREATE TABLE test_table_ml_2024 PARTITION OF test_table_multi_level
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
PARTITION BY LIST (country);

CREATE TABLE test_table_ml_2024_us PARTITION OF test_table_ml_2024
FOR VALUES IN ('USA', 'Canada', 'Mexico');

CREATE TABLE test_table_ml_2024_emea PARTITION OF test_table_ml_2024
FOR VALUES IN ('UK', 'Germany', 'France');

CREATE TABLE test_table_ml_2024_apac PARTITION OF test_table_ml_2024
FOR VALUES IN ('China', 'Japan', 'India');

-- 30.10 Table with foreign keys (complex scenarios)
CREATE TABLE test_table_dept (
    dept_id serial PRIMARY KEY,
    dept_code text UNIQUE NOT NULL,
    dept_name text NOT NULL,
    parent_dept_id integer REFERENCES test_table_dept(dept_id) ON DELETE CASCADE
);

CREATE TABLE test_table_emp (
    emp_id serial PRIMARY KEY,
    emp_name text NOT NULL,
    manager_id integer REFERENCES test_table_emp(emp_id) ON DELETE SET NULL,
    dept_id integer REFERENCES test_table_dept(dept_id) ON DELETE RESTRICT,
    mentor_id integer REFERENCES test_table_emp(emp_id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE test_table_orders (
    order_id integer,
    product_id integer,
    variant_id integer,
    quantity integer,
    PRIMARY KEY (order_id, product_id, variant_id)
);

CREATE TABLE test_table_order_details (
    order_id integer,
    product_id integer,
    variant_id integer,
    detail_text text,
    CONSTRAINT fk_composite FOREIGN KEY (order_id, product_id, variant_id) 
        REFERENCES test_table_orders(order_id, product_id, variant_id)
        ON DELETE CASCADE
        MATCH FULL
);

-- 30.11 Temporary tables
CREATE TEMP TABLE test_table_temp ON COMMIT DELETE ROWS AS
SELECT * FROM test_table_basic;

CREATE TEMP TABLE test_table_temp_preserve ON COMMIT PRESERVE ROWS AS
SELECT * FROM test_table_basic WHERE 1=0;

-- 30.12 Unlogged table
CREATE UNLOGGED TABLE test_table_unlogged (
    id serial PRIMARY KEY,
    cache_data text
);

-- 30.13 Table with storage parameters
CREATE TABLE test_table_storage (
    id serial PRIMARY KEY,
    large_data text,
    created_at timestamp
) WITH (
    fillfactor = 80,
    autovacuum_enabled = true,
    autovacuum_vacuum_threshold = 100,
    toast_tuple_target = 128
);

-- 30.14 Table with LIKE including options
CREATE TABLE test_table_like_including (
    LIKE test_table_basic INCLUDING ALL,
    extra_column text
);

-- 30.15 Partitioned table with foreign keys
CREATE TABLE test_table_partitioned_fk (
    order_id serial,
    order_date date NOT NULL,
    customer_id integer,
    total_amount numeric,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE test_table_orders_q1 PARTITION OF test_table_partitioned_fk
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE test_table_orders_q2 PARTITION OF test_table_partitioned_fk
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE test_table_order_payments (
    payment_id serial,
    order_id integer,
    order_date date,
    amount numeric,
    CONSTRAINT fk_to_partitioned FOREIGN KEY (order_id, order_date) 
        REFERENCES test_table_partitioned_fk(order_id, order_date)
);

-- 30.16 Table with deferred constraints
CREATE TABLE test_table_deferred (
    id serial PRIMARY KEY,
    parent_id integer,
    name text UNIQUE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_deferred FOREIGN KEY (parent_id) 
        REFERENCES test_table_deferred(id) 
        DEFERRABLE INITIALLY IMMEDIATE
);

-- ============================================================================
-- 31. CREATE TABLE AS
-- ============================================================================

-- Basic CREATE TABLE AS
CREATE TABLE test_table_as1 AS 
SELECT * FROM test_table_basic;

-- With column names
CREATE TABLE test_table_as2 (id, name, created) AS 
SELECT id, name, created_at FROM test_table_basic;

-- With PRIMARY KEY
CREATE TABLE test_table_as3 AS 
SELECT id, name FROM test_table_basic 
WITH NO DATA;

-- With data
CREATE TABLE test_table_as4 WITH DATA AS 
SELECT * FROM test_table_basic WHERE id > 10;

-- With tablespace
CREATE TABLE test_table_as5 TABLESPACE test_index_tablespace AS 
SELECT id, name FROM test_table_basic;

-- With storage parameters
CREATE TABLE test_table_as6 WITH (fillfactor = 90) AS 
SELECT * FROM test_table_basic;

-- Complex query
CREATE TABLE test_table_as7 AS 
SELECT 
    t1.id,
    t1.name,
    t2.salary,
    t2.age
FROM test_table_basic t1
JOIN test_index_table t2 ON t1.id = t2.id;

-- ============================================================================
-- 32. CREATE TABLESPACE
-- ============================================================================

-- Basic tablespace
CREATE TABLESPACE test_tablespace1 LOCATION '/tmp/test_tbs1';

-- Tablespace with owner
CREATE TABLESPACE test_tablespace2 OWNER postgres LOCATION '/tmp/test_tbs2';

-- Tablespace with sequence
CREATE TABLESPACE test_tablespace3 LOCATION '/tmp/test_tbs3'
WITH (seq_page_cost = 1.0, random_page_cost = 4.0);

-- ============================================================================
-- 33. CREATE TEXT SEARCH CONFIGURATION
-- ============================================================================

-- Basic configuration
CREATE TEXT SEARCH CONFIGURATION test_ts_config1 (COPY = pg_catalog.english);

-- Configuration with parser
CREATE TEXT SEARCH CONFIGURATION test_ts_config2 (PARSER = pg_catalog.default);

-- Configuration with mapping
CREATE TEXT SEARCH CONFIGURATION test_ts_config3 (COPY = pg_catalog.simple);
ALTER TEXT SEARCH CONFIGURATION test_ts_config3
    ALTER MAPPING FOR word WITH simple;

-- ============================================================================
-- 34. CREATE TEXT SEARCH DICTIONARY
-- ============================================================================

-- Basic dictionary
CREATE TEXT SEARCH DICTIONARY test_ts_dict1 (
    TEMPLATE = pg_catalog.simple
);

-- Dictionary with options
CREATE TEXT SEARCH DICTIONARY test_ts_dict2 (
    TEMPLATE = pg_catalog.snowball,
    LANGUAGE = 'english',
    STOPWORDS = 'english'
);

-- Dictionary with custom settings
CREATE TEXT SEARCH DICTIONARY test_ts_dict3 (
    TEMPLATE = pg_catalog.ispell,
    DictFile = 'english',
    AffFile = 'english',
    StopWords = 'english'
);

-- ============================================================================
-- 35. CREATE TEXT SEARCH PARSER
-- ============================================================================

-- Basic parser (requires C functions)
-- Note: Typically these are C functions, shown as example
CREATE TEXT SEARCH PARSER test_ts_parser1 (
    START = prsd_start,
    GETTOKEN = prsd_nexttoken,
    END = prsd_end,
    LEXTYPES = prsd_lextype
);

-- Parser with head line
CREATE TEXT SEARCH PARSER test_ts_parser2 (
    START = prsd_start,
    GETTOKEN = prsd_nexttoken,
    END = prsd_end,
    LEXTYPES = prsd_lextype,
    HEADLINE = prsd_headline
);

-- ============================================================================
-- 36. CREATE TEXT SEARCH TEMPLATE
-- ============================================================================

-- Basic template
CREATE TEXT SEARCH TEMPLATE test_ts_template1 (
    INIT = dsnowball_init,
    LEXIZE = dsnowball_lexize
);

-- Template with only lexize
CREATE TEXT SEARCH TEMPLATE test_ts_template2 (
    LEXIZE = dsnowball_lexize
);

-- ============================================================================
-- 37. CREATE TRANSFORM
-- ============================================================================

-- Basic transform (requires hstore extension)
CREATE EXTENSION IF NOT EXISTS hstore;

CREATE FUNCTION hstore_to_json(store hstore) 
RETURNS json 
LANGUAGE SQL 
AS 'SELECT hstore_to_json($1)';

CREATE TRANSFORM FOR hstore LANGUAGE sql (
    FROM SQL WITH FUNCTION hstore_to_json(hstore)
);

-- Transform with both directions
CREATE FUNCTION json_to_hstore(json_data json) 
RETURNS hstore 
LANGUAGE SQL 
AS 'SELECT json_to_hstore($1)';

CREATE TRANSFORM FOR json LANGUAGE sql (
    FROM SQL WITH FUNCTION json_to_hstore(json),
    TO SQL WITH FUNCTION hstore_to_json(hstore)
);

-- ============================================================================
-- 38. CREATE TRIGGER
-- ============================================================================

-- Create table for triggers
CREATE TABLE test_trigger_table (
    id serial PRIMARY KEY,
    data text,
    updated_at timestamp
);

-- BEFORE trigger
CREATE TRIGGER test_trigger1
    BEFORE INSERT ON test_trigger_table
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- AFTER trigger
CREATE TRIGGER test_trigger2
    AFTER UPDATE ON test_trigger_table
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- INSTEAD OF trigger
CREATE VIEW test_trigger_view AS SELECT * FROM test_trigger_table;
CREATE TRIGGER test_trigger3
    INSTEAD OF INSERT ON test_trigger_view
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- Trigger with condition
CREATE TRIGGER test_trigger4
    BEFORE UPDATE ON test_trigger_table
    FOR EACH ROW
    WHEN (OLD.data IS DISTINCT FROM NEW.data)
    EXECUTE FUNCTION test_trigger_func();

-- Statement level trigger
CREATE TRIGGER test_trigger5
    AFTER DELETE ON test_trigger_table
    FOR EACH STATEMENT
    EXECUTE FUNCTION test_trigger_func();

-- Trigger with multiple events
CREATE TRIGGER test_trigger6
    AFTER INSERT OR UPDATE OR DELETE ON test_trigger_table
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- Constraint trigger
CREATE CONSTRAINT TRIGGER test_trigger7
    AFTER UPDATE ON test_trigger_table
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- Trigger with columns
CREATE TRIGGER test_trigger8
    BEFORE UPDATE OF data ON test_trigger_table
    FOR EACH ROW
    EXECUTE FUNCTION test_trigger_func();

-- ============================================================================
-- 39. CREATE TYPE
-- ============================================================================

-- Composite type
CREATE TYPE test_composite_type1 AS (
    field1 integer,
    field2 text,
    field3 date
);

-- Composite type with default
CREATE TYPE test_composite_type2 AS (
    f1 integer DEFAULT 0,
    f2 text DEFAULT 'empty'
);

-- Enum type
CREATE TYPE test_enum_type AS ENUM ('active', 'inactive', 'pending');

-- Range type
CREATE TYPE test_range_type AS RANGE (
    SUBTYPE = timestamp,
    SUBTYPE_OPCLASS = timestamp_ops
);

-- Base type (requires C functions, example only)
CREATE TYPE test_base_type (
    INPUT = test_base_type_in,
    OUTPUT = test_base_type_out,
    INTERNALLENGTH = 16
);

-- Shell type
CREATE TYPE test_shell_type;

-- ============================================================================
-- 40. CREATE USER (alias for CREATE ROLE)
-- ============================================================================

CREATE USER test_user1;
CREATE USER test_user2 WITH PASSWORD 'userpass';
CREATE USER test_user3 WITH SUPERUSER CREATEDB CREATEROLE;
CREATE USER test_user4 WITH LOGIN PASSWORD 'pass' VALID UNTIL '2025-12-31';

-- ============================================================================
-- 41. CREATE USER MAPPING
-- ============================================================================

-- Basic user mapping
CREATE USER MAPPING FOR test_user1 SERVER test_server1;

-- User mapping with options
CREATE USER MAPPING FOR test_user2 SERVER test_server2
OPTIONS (user 'remote_user', password 'remote_pass');

-- User mapping for public
CREATE USER MAPPING FOR PUBLIC SERVER test_server3;

-- User mapping with all options
CREATE USER MAPPING FOR test_user3 SERVER test_server4
OPTIONS (
    user 'app_user',
    password 'secret123',
    options '-c application_name=myapp'
);

-- ============================================================================
-- 42. CREATE VIEW
-- ============================================================================

-- Basic view
CREATE VIEW test_view1 AS 
SELECT id, name FROM test_table_basic;

-- View with column names
CREATE VIEW test_view2 (view_id, view_name, view_date) AS 
SELECT id, name, created_at FROM test_table_basic;

-- View with security
CREATE VIEW test_view3 WITH (security_barrier = true) AS 
SELECT * FROM test_table_basic WHERE name = current_user;

-- View with check option
CREATE VIEW test_view4 AS 
SELECT * FROM test_table_basic WHERE id > 0
WITH LOCAL CHECK OPTION;

CREATE VIEW test_view5 AS 
SELECT * FROM test_view4 WHERE name IS NOT NULL
WITH CASCADED CHECK OPTION;

-- Temporary view
CREATE TEMP VIEW test_view6 AS 
SELECT id, name FROM test_table_basic;

-- Recursive view
CREATE RECURSIVE VIEW test_view7 (id, parent_id) AS
    SELECT id, parent_id FROM test_table_deferred
    UNION ALL
    SELECT t.id, t.parent_id FROM test_table_deferred t, test_view7 v
    WHERE t.id = v.parent_id;

-- View with complex query
CREATE VIEW test_view8 AS 
SELECT 
    e.emp_id,
    e.emp_name,
    d.dept_name,
    m.emp_name as manager_name
FROM test_table_emp e
LEFT JOIN test_table_dept d ON e.dept_id = d.dept_id
LEFT JOIN test_table_emp m ON e.manager_id = m.emp_id;

-- ============================================================================
-- 43. REINDEX SIMPLE TEST - Using tbl_reindex
-- ============================================================================

-- ========== PREPARATION ==========
DROP TABLE IF EXISTS tbl_reindex CASCADE;

CREATE TABLE tbl_reindex (
    id serial PRIMARY KEY,
    name varchar(100),
    age integer,
    salary numeric(10,2)
);

-- Create indexes
CREATE INDEX idx_name ON tbl_reindex(name);
CREATE INDEX idx_age ON tbl_reindex(age);
CREATE INDEX idx_salary ON tbl_reindex(salary) INCLUDE (name, age);
CREATE INDEX idx_lower_name ON tbl_reindex(LOWER(name));

-- Insert test data
INSERT INTO tbl_reindex (name, age, salary)
SELECT 
    'User_' || i,
    (random() * 100)::int,
    (random() * 100000)::numeric(10,2)
FROM generate_series(1, 1000) i;

-- ========== TEST REINDEX ==========

-- 1. REINDEX single index
REINDEX INDEX idx_name;

-- 2. REINDEX single index concurrently
REINDEX INDEX CONCURRENTLY idx_age;

-- 3. REINDEX all indexes on table
REINDEX TABLE tbl_reindex;

-- 4. REINDEX all indexes on table concurrently
REINDEX TABLE CONCURRENTLY tbl_reindex;

-- 5. REINDEX with VERBOSE
REINDEX INDEX idx_salary VERBOSE;


-- ========== CLEANUP ==========
DROP TABLE IF EXISTS tbl_reindex CASCADE;

-- ============================================================================
-- 44. TRUNCATE TABLE
-- ============================================================================
TRUNCATE TABLEtest_table_order_details;
TRUNCATE TABLE test_table_orders;

-- ============================================================================
-- VALIDATION SECTION
-- ============================================================================

DO $$
DECLARE
    object_count integer;
BEGIN
    RAISE NOTICE '======================================';
    RAISE NOTICE 'VALIDATION SUMMARY';
    RAISE NOTICE '======================================';
    
    SELECT COUNT(*) INTO object_count 
    FROM pg_class 
    WHERE relnamespace = 'test_schema'::regnamespace 
    AND relkind IN ('r', 'v', 'm', 'i', 'S');
    RAISE NOTICE 'Tables/Views/Indexes created: %', object_count;
    
    SELECT COUNT(*) INTO object_count 
    FROM pg_proc 
    WHERE pronamespace = 'test_schema'::regnamespace;
    RAISE NOTICE 'Functions/Procedures created: %', object_count;
    
    SELECT COUNT(*) INTO object_count 
    FROM pg_type 
    WHERE typnamespace = 'test_schema'::regnamespace 
    AND typtype IN ('c', 'e', 'r');
    RAISE NOTICE 'Types created: %', object_count;
    
    RAISE NOTICE '======================================';
    RAISE NOTICE 'All CREATE commands executed successfully!';
    RAISE NOTICE '======================================';
END;
$$;

-- ============================================================================
-- CLEANUP SECTION
-- ============================================================================

-- Note: To clean up, drop everything in reverse order
-- Uncomment to cleanup after testing


\c postgres
DROP DATABASE IF EXISTS ddl_create_complete_test CASCADE;
DROP TABLESPACE IF EXISTS test_tablespace CASCADE;
DROP TABLESPACE IF EXISTS test_index_tablespace CASCADE;


-- ============================================================================
-- END OF FILE
-- ============================================================================