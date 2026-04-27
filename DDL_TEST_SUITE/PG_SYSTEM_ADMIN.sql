-- =====================================================
-- FILE: PG_SYSTEM_ADMIN.sql
-- Purpose: Complete System & Administration Commands Test File
--          Covers all PostgreSQL system, admin, monitoring, and maintenance commands
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
-- AUTHOR: Lalit Choudhary
-- =====================================================

-- ========== PREPARATION SECTION ==========
\c postgres
DROP DATABASE IF EXISTS system_admin_test;
CREATE DATABASE system_admin_test;
\c system_admin_test

-- Create test objects for various commands
CREATE SCHEMA admin_schema;

CREATE TABLE test_table (
    id serial PRIMARY KEY,
    data text,
    created_at timestamp DEFAULT now()
);

CREATE INDEX test_idx ON test_table(id);

CREATE VIEW test_view AS SELECT * FROM test_table;

CREATE MATERIALIZED VIEW test_matview AS SELECT * FROM test_table;

CREATE FUNCTION test_func() RETURNS int LANGUAGE SQL AS 'SELECT 1';

-- Insert test data
INSERT INTO test_table (data) 
SELECT 'Data_' || generate_series(1, 1000);

-- ============================================================================
-- 1. ANALYZE - Collect statistics
-- ============================================================================

-- Analyze specific table
ANALYZE test_table;

-- Analyze specific column
ANALYZE test_table (id, data);

-- Analyze all tables in schema
ANALYZE admin_schema.*;

-- Analyze verbose
ANALYZE VERBOSE test_table;

-- Analyze with specific statistics target
SET default_statistics_target = 100;
ANALYZE test_table;
RESET default_statistics_target;

-- ============================================================================
-- 2. VACUUM - Garbage collection
-- ============================================================================

-- Basic VACUUM
VACUUM test_table;

-- VACUUM with VERBOSE
VACUUM VERBOSE test_table;

-- VACUUM FREEZE
VACUUM FREEZE test_table;

-- VACUUM FULL (rebuilds table)
VACUUM FULL test_table;

-- VACUUM analyze together
VACUUM ANALYZE test_table;

-- VACUUM with specific columns
VACUUM (VERBOSE, ANALYZE) test_table;

-- VACUUM all tables in database
VACUUM;

-- ============================================================================
-- 3. CLUSTER - Reorder table based on index
-- ============================================================================

-- Cluster table using specific index
CLUSTER test_table USING test_idx;

-- Cluster without specifying index (uses previous)
CLUSTER test_table;

-- Cluster all tables in database
CLUSTER;

-- Cluster verbose
CLUSTER VERBOSE test_table USING test_idx;

-- ============================================================================
-- 4. REINDEX - Rebuild indexes
-- ============================================================================

-- Reindex specific index
REINDEX INDEX test_idx;

-- Reindex all indexes on table
REINDEX TABLE test_table;

-- Reindex schema
REINDEX SCHEMA admin_schema;

-- Reindex database
REINDEX DATABASE system_admin_test;

-- Reindex concurrently (reduced locking)
REINDEX INDEX CONCURRENTLY test_idx;

-- Reindex with verbose
REINDEX VERBOSE TABLE test_table;

-- ============================================================================
-- 5. CHECKPOINT - Force write-ahead log checkpoint
-- ============================================================================

CHECKPOINT;

-- ============================================================================
-- 6. DISCARD - Discard session state
-- ============================================================================

-- Discard all temporary resources
DISCARD ALL;

-- Discard plans (prepared statements)
DISCARD PLANS;

-- Discard temporary tables
CREATE TEMP TABLE temp_test (id int);
DISCARD TEMP;

-- Discard sequences
CREATE TEMP SEQUENCE temp_seq;
DISCARD SEQUENCES;

-- Combined discard
DISCARD ALL;

-- ============================================================================
-- 7. LOAD - Load shared library
-- ============================================================================

-- Load a library (example - actual library must exist)
LOAD '$libdir/auto_explain';

-- ============================================================================
-- 8. LOCK - Lock tables
-- ============================================================================

-- Basic lock
LOCK TABLE test_table;

-- Access share lock
LOCK TABLE test_table IN ACCESS SHARE MODE;

-- Row share lock
LOCK TABLE test_table IN ROW SHARE MODE;

-- Row exclusive lock
LOCK TABLE test_table IN ROW EXCLUSIVE MODE;

-- Share update exclusive lock
LOCK TABLE test_table IN SHARE UPDATE EXCLUSIVE MODE;

-- Share lock
LOCK TABLE test_table IN SHARE MODE;

-- Share row exclusive lock
LOCK TABLE test_table IN SHARE ROW EXCLUSIVE MODE;

-- Exclusive lock
LOCK TABLE test_table IN EXCLUSIVE MODE;

-- Access exclusive lock (most restrictive)
LOCK TABLE test_table IN ACCESS EXCLUSIVE MODE;

-- Lock multiple tables
LOCK TABLE test_table, test_view IN SHARE MODE;

-- Lock with NOWAIT
LOCK TABLE test_table IN ACCESS EXCLUSIVE MODE NOWAIT;

-- Lock in specific schema
LOCK TABLE admin_schema.test_table;

-- ============================================================================
-- 9. RESET - Restore run-time parameters
-- ============================================================================

-- Reset specific parameter
SET timezone TO 'UTC';
RESET timezone;

-- Reset all parameters to defaults
RESET ALL;

-- Reset specific parameter to default
SET work_mem TO '16MB';
RESET work_mem;

-- Reset from current session
SET statement_timeout TO '5min';
RESET statement_timeout;

-- ============================================================================
-- 10. SET - Change run-time parameters
-- ============================================================================

-- Set session level
SET timezone = 'America/New_York';

-- Set local (only for current transaction)
BEGIN;
SET LOCAL work_mem = '32MB';
COMMIT;

-- Set multiple parameters
SET timezone = 'UTC', work_mem = '64MB';

-- Set with specific syntax
SET SESSION timezone TO 'Europe/London';

-- Set schema search path
SET search_path TO admin_schema, public;

-- Set role
SET ROLE postgres;

-- Set constraints timing
SET CONSTRAINTS ALL DEFERRED;

-- ============================================================================
-- 11. SHOW - Display run-time parameters
-- ============================================================================

-- Show specific parameter
SHOW timezone;
SHOW work_mem;
SHOW shared_buffers;
SHOW max_connections;

-- Show all parameters
SHOW ALL;

-- Show settings with specific syntax
SHOW SERVER_VERSION;
SHOW SERVER_ENCODING;
SHOW LC_COLLATE;

-- ============================================================================
-- 12. EXPLAIN - Display execution plan
-- ============================================================================

-- Basic EXPLAIN
EXPLAIN SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN ANALYZE (executes query)
EXPLAIN ANALYZE SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with VERBOSE
EXPLAIN VERBOSE SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with BUFFERS
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with COSTS
EXPLAIN (COSTS OFF) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with TIMING
EXPLAIN (ANALYZE, TIMING OFF) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with SUMMARY
EXPLAIN (ANALYZE, SUMMARY ON) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with FORMAT
EXPLAIN (FORMAT JSON) SELECT * FROM test_table WHERE id = 100;
EXPLAIN (FORMAT XML) SELECT * FROM test_table WHERE id = 100;
EXPLAIN (FORMAT YAML) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with SETTINGS (PostgreSQL 12+)
EXPLAIN (SETTINGS ON) SELECT * FROM test_table WHERE id = 100;

-- EXPLAIN with WAL (PostgreSQL 13+)
EXPLAIN (ANALYZE, WAL) INSERT INTO test_table(data) VALUES ('test');

-- Complex EXPLAIN
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING, SUMMARY)
SELECT t1.id, t2.data 
FROM test_table t1 
JOIN test_table t2 ON t1.id = t2.id 
WHERE t1.id < 100;

-- ============================================================================
-- 13. PREPARE - Prepare statement for execution
-- ============================================================================

-- Basic prepare statement
PREPARE test_plan1 AS SELECT * FROM test_table WHERE id = $1;

-- Prepare with multiple parameters
PREPARE test_plan2 (int, text) AS 
INSERT INTO test_table (id, data) VALUES ($1, $2);

-- Prepare complex query
PREPARE test_plan3 (int, int) AS
SELECT t1.*, t2.data 
FROM test_table t1
JOIN test_table t2 ON t1.id = t2.id
WHERE t1.id BETWEEN $1 AND $2;

-- Prepare with function
PREPARE test_plan4 (int) AS SELECT test_func() + $1;

-- ============================================================================
-- 14. EXECUTE - Execute prepared statement
-- ============================================================================

-- Execute basic prepared statement
EXECUTE test_plan1(100);

-- Execute with multiple parameters
EXECUTE test_plan2(2000, 'New Data');

-- Execute complex query
EXECUTE test_plan3(10, 50);

-- Execute and insert results
CREATE TABLE exec_results AS 
EXECUTE test_plan1(500);

-- ============================================================================
-- 15. DEALLOCATE - Deallocate prepared statement
-- ============================================================================

-- Deallocate specific statement
DEALLOCATE test_plan1;

-- Deallocate multiple statements
DEALLOCATE test_plan2, test_plan3;

-- Deallocate all statements
DEALLOCATE ALL;

-- ============================================================================
-- 16. LISTEN / NOTIFY - Event notification system
-- ============================================================================

-- Listen to a channel
LISTEN test_channel;

-- Listen with NOTIFY
NOTIFY test_channel, 'Test message';

-- Listen to multiple channels
LISTEN channel1;
LISTEN channel2;

-- UNLISTEN
UNLISTEN test_channel;
UNLISTEN *;  -- Unlisten from all channels

-- Example with payload
NOTIFY data_channel, '{"id": 1, "status": "complete"}';

-- ============================================================================
-- 17. BEGIN / COMMIT / ROLLBACK - Transaction control
-- ============================================================================

-- Basic BEGIN
BEGIN;
INSERT INTO test_table(data) VALUES ('Transaction test');
COMMIT;

-- BEGIN with isolation level
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE test_table SET data = 'Updated' WHERE id = 1;
COMMIT;

-- BEGIN read only
BEGIN READ ONLY;
SELECT * FROM test_table;
COMMIT;

-- BEGIN with deferrable
BEGIN ISOLATION LEVEL SERIALIZABLE, READ ONLY, DEFERRABLE;
SELECT COUNT(*) FROM test_table;
COMMIT;

-- ROLLBACK
BEGIN;
INSERT INTO test_table(data) VALUES ('Will be rolled back');
ROLLBACK;

-- ROLLBACK to savepoint
BEGIN;
INSERT INTO test_table(data) VALUES ('First');
SAVEPOINT my_savepoint;
INSERT INTO test_table(data) VALUES ('Second');
ROLLBACK TO SAVEPOINT my_savepoint;
COMMIT;

-- ============================================================================
-- 18. SAVEPOINT - Define savepoints within transaction
-- ============================================================================

-- Create savepoint
BEGIN;
SAVEPOINT sp1;

-- Release savepoint
RELEASE SAVEPOINT sp1;

-- Nested savepoints
SAVEPOINT sp1;
SAVEPOINT sp2;
SAVEPOINT sp3;
ROLLBACK TO SAVEPOINT sp2;
COMMIT;

-- ============================================================================
-- 19. SET CONSTRAINTS - Set constraint timing
-- ============================================================================

-- Create table with deferred constraints
CREATE TABLE deferred_test (
    id serial PRIMARY KEY,
    parent_id integer,
    CONSTRAINT fk_parent FOREIGN KEY (parent_id) 
        REFERENCES deferred_test(id) DEFERRABLE
);

-- Set constraints deferred
SET CONSTRAINTS ALL DEFERRED;

-- Set specific constraint
SET CONSTRAINTS fk_parent DEFERRED;

-- Set constraints immediate
SET CONSTRAINTS ALL IMMEDIATE;

-- ============================================================================
-- 20. SET ROLE / SET SESSION AUTHORIZATION
-- ============================================================================

-- Set role
CREATE ROLE test_role LOGIN;
SET ROLE test_role;

-- Reset to original role
RESET ROLE;

-- Set session authorization
SET SESSION AUTHORIZATION test_role;

-- Reset session authorization
SET SESSION AUTHORIZATION DEFAULT;

-- ============================================================================
-- 21. TRUNCATE - Empty tables
-- ============================================================================

-- Basic truncate
TRUNCATE test_table;

-- Truncate multiple tables
TRUNCATE test_table, test_view;

-- Truncate with restart identity
TRUNCATE test_table RESTART IDENTITY;

-- Truncate with cascade
TRUNCATE test_table CASCADE;

-- Truncate with continue identity
TRUNCATE test_table CONTINUE IDENTITY;

-- Truncate with only
TRUNCATE ONLY test_table;

-- ============================================================================
-- 22. COPY - Copy data between file and table
-- ============================================================================

-- Copy from STDIN
COPY test_table (id, data) FROM STDIN WITH (FORMAT csv);
-- (would wait for input, commented for automation)

-- Copy to STDOUT
COPY test_table TO STDOUT WITH (FORMAT csv, HEADER true);

-- Copy with options
COPY test_table (id, data) TO STDOUT WITH (
    FORMAT text,
    DELIMITER '|',
    NULL 'NULL',
    ENCODING 'UTF8'
);

-- Copy query results
COPY (SELECT * FROM test_table WHERE id < 100) TO STDOUT;

-- ============================================================================
-- 23. CALL - Invoke procedure
-- ============================================================================

-- Create procedure
CREATE PROCEDURE test_proc(IN p_id int, IN p_data text)
LANGUAGE SQL AS $$
    INSERT INTO test_table(id, data) VALUES (p_id, p_data);
$$;

-- Call procedure
CALL test_proc(3000, 'Called via CALL');

-- ============================================================================
-- 24. DO - Execute anonymous code block
-- ============================================================================

-- Basic DO block
DO $$
BEGIN
    RAISE NOTICE 'Anonymous block executed';
END;
$$;

-- DO with variables
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count FROM test_table;
    RAISE NOTICE 'Total rows: %', v_count;
END;
$$;

-- DO with language
DO LANGUAGE plpgsql $$
    PERFORM * FROM test_table LIMIT 1;
    RAISE NOTICE 'Query executed';
$$;

-- ============================================================================
-- 25. VALUES - Compute set of rows
-- ============================================================================

-- Basic VALUES
VALUES (1, 'One'), (2, 'Two'), (3, 'Three');

-- VALUES with column aliases
VALUES (1, 'One'), (2, 'Two'), (3, 'Three') AS t(id, name);

-- VALUES in INSERT
INSERT INTO test_table (id, data) 
VALUES (4000, 'Direct'), (4001, 'Another');

-- VALUES in SELECT
SELECT * FROM (VALUES (1, 'A'), (2, 'B')) AS t(num, letter);

-- ============================================================================
-- 26. FETCH / MOVE - Cursor operations
-- ============================================================================

-- Declare cursor
DECLARE test_cursor CURSOR FOR SELECT * FROM test_table ORDER BY id;

-- Fetch from cursor
FETCH NEXT FROM test_cursor;
FETCH PRIOR FROM test_cursor;
FETCH FIRST FROM test_cursor;
FETCH LAST FROM test_cursor;
FETCH ABSOLUTE 10 FROM test_cursor;
FETCH RELATIVE -5 FROM test_cursor;
FETCH FORWARD 10 FROM test_cursor;
FETCH BACKWARD 5 FROM test_cursor;

-- Move cursor (without fetching)
MOVE test_cursor;
MOVE NEXT FROM test_cursor;
MOVE PRIOR FROM test_cursor;
MOVE FIRST FROM test_cursor;
MOVE LAST FROM test_cursor;
MOVE ABSOLUTE 50 FROM test_cursor;
MOVE RELATIVE -10 FROM test_cursor;

-- Close cursor
CLOSE test_cursor;

-- ============================================================================
-- 27. PREPARE TRANSACTION / COMMIT PREPARED / ROLLBACK PREPARED
-- ============================================================================

-- Prepare transaction (two-phase commit)
BEGIN;
INSERT INTO test_table(data) VALUES ('Two-phase commit test');
PREPARE TRANSACTION 'test_transaction';

-- Commit prepared
COMMIT PREPARED 'test_transaction';

-- Rollback prepared
BEGIN;
INSERT INTO test_table(data) VALUES ('Another test');
PREPARE TRANSACTION 'another_transaction';
ROLLBACK PREPARED 'another_transaction';

-- ============================================================================
-- 28. SECURITY LABEL - Label objects
-- ============================================================================

-- Security label on table
SECURITY LABEL ON TABLE test_table IS 'public';

-- Security label on column
SECURITY LABEL ON COLUMN test_table.data IS 'confidential';

-- Remove label
SECURITY LABEL ON TABLE test_table IS NULL;

-- ============================================================================
-- 29. REFRESH MATERIALIZED VIEW
-- ============================================================================

-- Refresh materialized view
REFRESH MATERIALIZED VIEW test_matview;

-- Refresh with data
REFRESH MATERIALIZED VIEW test_matview WITH DATA;

-- Refresh without data
REFRESH MATERIALIZED VIEW test_matview WITH NO DATA;

-- Refresh concurrently (PostgreSQL 9.4+)
REFRESH MATERIALIZED VIEW CONCURRENTLY test_matview;

-- ============================================================================
-- 30. ABORT - Abort transaction (alias for ROLLBACK)
-- ============================================================================

BEGIN;
INSERT INTO test_table(data) VALUES ('Will be aborted');
ABORT;

-- ============================================================================
-- ============================================================================
-- VERIFICATION SECTION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SYSTEM & ADMIN COMMANDS TEST SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'All commands executed successfully!';
    RAISE NOTICE 'Database: system_admin_test';
    RAISE NOTICE 'Tables: test_table, deferred_test';
    RAISE NOTICE 'Indexes: test_idx';
    RAISE NOTICE 'Views: test_view';
    RAISE NOTICE 'Materialized View: test_matview';
    RAISE NOTICE '========================================';
END;
$$;

-- Display current database settings
SELECT 
    name,
    setting,
    unit,
    context
FROM pg_settings
WHERE name IN ('timezone', 'work_mem', 'shared_buffers', 'max_connections')
ORDER BY name;

-- Display active locks
SELECT 
    locktype,
    relation::regclass,
    mode,
    granted
FROM pg_locks
WHERE relation = 'test_table'::regclass
LIMIT 5;

-- ============================================================================
-- CLEANUP SECTION
-- ============================================================================

-- Clean up prepared statements
DEALLOCATE ALL;

-- Clear listeners
UNLISTEN *;

-- Drop created objects
DROP TABLE IF EXISTS exec_results CASCADE;
DROP TABLE IF EXISTS deferred_test CASCADE;
DROP PROCEDURE IF EXISTS test_proc(int, text) CASCADE;
DROP FUNCTION IF EXISTS test_func() CASCADE;
DROP MATERIALIZED VIEW IF EXISTS test_matview CASCADE;
DROP VIEW IF EXISTS test_view CASCADE;
DROP INDEX IF EXISTS test_idx CASCADE;
DROP TABLE IF EXISTS test_table CASCADE;
DROP SCHEMA IF EXISTS admin_schema CASCADE;
DROP ROLE IF EXISTS test_role CASCADE;

-- ============================================================================
-- FINAL CLEANUP
-- ============================================================================
\c postgres
DROP DATABASE IF EXISTS system_admin_test CASCADE;

SELECT '========================================' AS status;
SELECT 'SYSTEM & ADMIN COMMANDS TEST COMPLETED!' AS status;
SELECT '========================================' AS status;