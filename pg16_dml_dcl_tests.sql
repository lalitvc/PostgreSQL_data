-- =============================================================================
-- PostgreSQL 16 -- DML (Data Manipulation Language) + DCL SELECT Verifications
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
--
-- DML covered : INSERT, UPDATE, DELETE, MERGE, TRUNCATE, COPY, VALUES,
--               SELECT (full feature tour), SELECT INTO,
--               Cursors (DECLARE/OPEN/FETCH/MOVE/CLOSE),
--               Prepared statements (PREPARE/EXECUTE/DEALLOCATE),
--               Transactions (BEGIN/COMMIT/ROLLBACK/SAVEPOINT/...),
--               Utility DML : DO, CALL, EXPLAIN, LISTEN/NOTIFY/UNLISTEN,
--               LOCK, SET/SHOW/RESET, DISCARD
--
-- DCL SELECT  : GRANT, REVOKE, SHOW GRANTS (via catalog queries)
--               Verification SELECTs after every major operation.
--
-- Run as a superuser on a test database:
--   psql -U postgres -d postgres -f pg16_dml_dcl_tests.sql
-- =============================================================================


-- =============================================================================
-- 0. SETUP – build schema & tables used across all tests
-- =============================================================================
SET client_min_messages = WARNING;
DROP SCHEMA IF EXISTS dml_test CASCADE;
DROP ROLE  IF EXISTS dml_reader;
DROP ROLE  IF EXISTS dml_writer;
SET client_min_messages = NOTICE;

CREATE SCHEMA dml_test;

-- Lookup / reference table
CREATE TABLE dml_test.categories (
    category_id   SERIAL        PRIMARY KEY,
    name          TEXT          NOT NULL UNIQUE,
    description   TEXT
);

-- Main product table
CREATE TABLE dml_test.products (
    product_id    SERIAL        PRIMARY KEY,
    category_id   INT           REFERENCES dml_test.categories(category_id),
    name          TEXT          NOT NULL,
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock         INT           NOT NULL DEFAULT 0,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ
);

-- Order header
CREATE TABLE dml_test.orders (
    order_id      SERIAL        PRIMARY KEY,
    customer_name TEXT          NOT NULL,
    status        TEXT          NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending','confirmed','shipped','cancelled')),
    total         NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Order lines
CREATE TABLE dml_test.order_items (
    item_id       SERIAL        PRIMARY KEY,
    order_id      INT           NOT NULL REFERENCES dml_test.orders(order_id) ON DELETE CASCADE,
    product_id    INT           NOT NULL REFERENCES dml_test.products(product_id),
    qty           INT           NOT NULL CHECK (qty > 0),
    unit_price    NUMERIC(10,2) NOT NULL
);

-- Audit log (append-only)
CREATE TABLE dml_test.audit_log (
    log_id        BIGSERIAL     PRIMARY KEY,
    event_time    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    table_name    TEXT          NOT NULL,
    operation     TEXT          NOT NULL,
    detail        TEXT
);

-- Staging table for MERGE / COPY tests
CREATE TABLE dml_test.products_staging (
    product_id    INT,
    name          TEXT,
    price         NUMERIC(10,2),
    stock         INT,
    category_id   INT
);


-- =============================================================================
-- 1. INSERT
-- =============================================================================
\echo '--- INSERT ---'

-- 1a. Simple INSERT with VALUES
INSERT INTO dml_test.categories (name, description) VALUES
    ('Electronics', 'Gadgets and devices'),
    ('Books',       'Printed and digital books'),
    ('Clothing',    'Apparel for all ages'),
    ('Food',        'Edible goods');

-- 1b. INSERT … RETURNING
INSERT INTO dml_test.products (category_id, name, price, stock)
VALUES (1, 'Wireless Mouse',   29.99,  150),
       (1, 'Mechanical Keyboard', 89.99, 75),
       (1, 'USB-C Hub',        45.00,  200),
       (2, 'PostgreSQL Manual',18.50,  500),
       (2, 'Clean Code',       34.99,  300),
       (3, 'Cotton T-Shirt',   12.99, 1000),
       (3, 'Denim Jeans',      49.99,  400),
       (4, 'Organic Coffee',    9.99,  250)
RETURNING product_id, name;

-- 1c. INSERT … ON CONFLICT DO NOTHING
INSERT INTO dml_test.categories (name, description)
VALUES ('Electronics', 'Duplicate category – ignore')
ON CONFLICT (name) DO NOTHING;

-- 1d. INSERT … ON CONFLICT DO UPDATE (UPSERT)
INSERT INTO dml_test.categories (name, description)
VALUES ('Food', 'Updated food description')
ON CONFLICT (name)
DO UPDATE SET description = EXCLUDED.description;

-- 1e. INSERT … SELECT
INSERT INTO dml_test.audit_log (table_name, operation, detail)
SELECT 'products', 'SEED', 'Initial product load: ' || COUNT(*)::TEXT
FROM   dml_test.products;

-- DCL SELECT: verify categories after INSERT
SELECT '=== DCL SELECT: categories after INSERT ===' AS section;
SELECT category_id, name, description
FROM   dml_test.categories
ORDER  BY category_id;


-- =============================================================================
-- 2. VALUES (standalone row-set constructor)
-- =============================================================================
\echo '--- VALUES ---'

-- VALUES as a standalone query
VALUES (1, 'alpha'), (2, 'beta'), (3, 'gamma');

-- VALUES used as a derived table
SELECT v.code, v.label
FROM (VALUES ('A', 'Active'), ('I', 'Inactive'), ('D', 'Deleted')) AS v(code, label);


-- =============================================================================
-- 3. SELECT – comprehensive feature tour
-- =============================================================================
\echo '--- SELECT ---'

-- 3a. Basic projection & filter
SELECT product_id, name, price
FROM   dml_test.products
WHERE  price < 50
ORDER  BY price DESC;

-- 3b. DISTINCT
SELECT DISTINCT category_id
FROM   dml_test.products;

-- 3c. Aggregate functions + GROUP BY + HAVING
SELECT   c.name   AS category,
         COUNT(*) AS product_count,
         AVG(p.price)::NUMERIC(8,2) AS avg_price,
         MAX(p.price)  AS max_price
FROM     dml_test.products p
JOIN     dml_test.categories c USING (category_id)
GROUP BY c.name
HAVING   COUNT(*) > 1
ORDER BY avg_price DESC;

-- 3d. Window functions
SELECT product_id,
       name,
       price,
       RANK()    OVER (PARTITION BY category_id ORDER BY price DESC) AS price_rank,
       SUM(price) OVER (PARTITION BY category_id)                   AS category_total
FROM   dml_test.products;

-- 3e. CTE (WITH)
WITH expensive AS (
    SELECT * FROM dml_test.products WHERE price > 40
),
cheap AS (
    SELECT * FROM dml_test.products WHERE price <= 40
)
SELECT 'expensive' AS bucket, COUNT(*) FROM expensive
UNION ALL
SELECT 'cheap',               COUNT(*) FROM cheap;

-- 3f. Recursive CTE
WITH RECURSIVE counter(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM counter WHERE n < 5
)
SELECT n FROM counter;

-- 3g. Subquery in WHERE
SELECT name, price
FROM   dml_test.products
WHERE  price > (SELECT AVG(price) FROM dml_test.products);

-- 3h. EXISTS
SELECT c.name
FROM   dml_test.categories c
WHERE  EXISTS (
    SELECT 1 FROM dml_test.products p
    WHERE  p.category_id = c.category_id
    AND    p.price > 30
);

-- 3i. LATERAL join
SELECT p.name, latest.updated_at
FROM   dml_test.products p
CROSS JOIN LATERAL (
    SELECT p.updated_at
) AS latest(updated_at);

-- 3j. CASE expression
SELECT name,
       price,
       CASE
           WHEN price < 20  THEN 'budget'
           WHEN price < 50  THEN 'mid-range'
           ELSE                  'premium'
       END AS price_tier
FROM   dml_test.products
ORDER BY price;

-- 3k. FILTER clause on aggregate
SELECT
    COUNT(*)                                           AS total_products,
    COUNT(*) FILTER (WHERE price < 20)                AS budget_count,
    COUNT(*) FILTER (WHERE is_active)                 AS active_count
FROM dml_test.products;

-- 3l. GROUPING SETS / ROLLUP / CUBE
SELECT   c.name  AS category,
         p.is_active,
         COUNT(*) AS cnt
FROM     dml_test.products p
JOIN     dml_test.categories c USING (category_id)
GROUP BY GROUPING SETS (
    (c.name, p.is_active),
    (c.name),
    ()
);

-- 3m. FETCH / LIMIT / OFFSET
SELECT product_id, name, price
FROM   dml_test.products
ORDER  BY price
OFFSET 2 ROWS
FETCH NEXT 3 ROWS ONLY;

-- 3n. UNION / INTERSECT / EXCEPT
SELECT name FROM dml_test.categories WHERE category_id <= 2
UNION
SELECT name FROM dml_test.categories WHERE category_id >= 3;

SELECT name FROM dml_test.categories WHERE category_id <= 3
INTERSECT
SELECT name FROM dml_test.categories WHERE category_id >= 2;

SELECT name FROM dml_test.categories
EXCEPT
SELECT name FROM dml_test.categories WHERE category_id = 1;

-- 3o. String / date / JSON functions
SELECT
    name,
    UPPER(name)                        AS upper_name,
    LENGTH(name)                       AS name_len,
    now()::DATE                        AS today,
    EXTRACT(YEAR FROM now())           AS this_year,
    '{"key":"value"}'::JSONB ->> 'key' AS json_val;

-- 3p. Full-text search
SELECT name
FROM   dml_test.products
WHERE  to_tsvector('english', name) @@ to_tsquery('english', 'mouse | keyboard');

-- 3q. SELECT with FOR UPDATE (row locking – wrapped in transaction)
BEGIN;
SELECT product_id, stock
FROM   dml_test.products
WHERE  product_id = 1
FOR UPDATE;
ROLLBACK;


-- =============================================================================
-- 4. SELECT INTO
-- =============================================================================
\echo '--- SELECT INTO ---'

SELECT product_id, name, price
INTO   dml_test.cheap_products_snapshot
FROM   dml_test.products
WHERE  price < 20;

-- DCL SELECT: verify
SELECT '=== DCL SELECT: cheap_products_snapshot ===' AS section;
SELECT * FROM dml_test.cheap_products_snapshot;


-- =============================================================================
-- 5. UPDATE
-- =============================================================================
\echo '--- UPDATE ---'

-- 5a. Simple UPDATE
UPDATE dml_test.products
SET    updated_at = now()
WHERE  category_id = 1;

-- 5b. UPDATE with expression
UPDATE dml_test.products
SET    price = price * 1.05   -- 5% price increase
WHERE  category_id = 2
RETURNING product_id, name, price;

-- 5c. UPDATE … FROM (join-style)
UPDATE dml_test.products p
SET    updated_at = now()
FROM   dml_test.categories c
WHERE  p.category_id = c.category_id
AND    c.name = 'Clothing';

-- DCL SELECT: verify pricing update
SELECT '=== DCL SELECT: products after price update ===' AS section;
SELECT product_id, name, price, updated_at
FROM   dml_test.products
WHERE  category_id = 2;


-- =============================================================================
-- 6. DELETE
-- =============================================================================
\echo '--- DELETE ---'

-- 6a. Conditional DELETE
DELETE FROM dml_test.products
WHERE  stock = 0
RETURNING product_id, name;

-- 6b. DELETE … USING (join-style)
-- (Soft delete all products in the 'Food' category with stock < 100)
DELETE FROM dml_test.products p
USING  dml_test.categories c
WHERE  p.category_id = c.category_id
AND    c.name = 'Food'
AND    p.stock < 100;

-- DCL SELECT: remaining products
SELECT '=== DCL SELECT: products after DELETE ===' AS section;
SELECT product_id, category_id, name, price, stock
FROM   dml_test.products
ORDER  BY product_id;


-- =============================================================================
-- 7. MERGE (PostgreSQL 15+ / included in PG 16)
-- =============================================================================
\echo '--- MERGE ---'

-- Populate staging with mix of existing and new products
INSERT INTO dml_test.products_staging VALUES
    (1,  'Wireless Mouse',       27.99, 180, 1),   -- lower price  → UPDATE
    (2,  'Mechanical Keyboard',  89.99,  80, 1),   -- same price   → UPDATE stock
    (99, 'Smart Speaker',        59.99,  60, 1);   -- new product  → INSERT

MERGE INTO dml_test.products AS tgt
USING dml_test.products_staging AS src
    ON tgt.product_id = src.product_id
WHEN MATCHED AND tgt.price <> src.price THEN
    UPDATE SET price      = src.price,
               updated_at = now()
WHEN MATCHED THEN
    UPDATE SET stock      = src.stock,
               updated_at = now()
WHEN NOT MATCHED THEN
    INSERT (category_id, name, price, stock)
    VALUES (src.category_id, src.name, src.price, src.stock);

-- DCL SELECT: verify MERGE
SELECT '=== DCL SELECT: products after MERGE ===' AS section;
SELECT product_id, name, price, stock
FROM   dml_test.products
ORDER  BY product_id;


-- =============================================================================
-- 8. COPY
-- =============================================================================
\echo '--- COPY ---'

-- COPY TO: export current products to stdout (CSV format)
COPY (
    SELECT product_id, name, price, stock
    FROM   dml_test.products
    ORDER  BY product_id
) TO STDOUT WITH (FORMAT CSV, HEADER);

-- COPY FROM: bulk load staging data from inline CSV via STDIN
COPY dml_test.products_staging (product_id, name, price, stock, category_id)
FROM STDIN WITH (FORMAT CSV);
101,Portable SSD,79.99,90,1
102,Noise Cancelling Headphones,129.99,45,1
103,Yoga Mat,24.99,300,3
\.

-- DCL SELECT: verify staging after COPY
SELECT '=== DCL SELECT: products_staging after COPY ===' AS section;
SELECT * FROM dml_test.products_staging ORDER BY product_id;


-- =============================================================================
-- 9. TRANSACTIONS: BEGIN / COMMIT / ROLLBACK / SAVEPOINT
-- =============================================================================
\echo '--- TRANSACTIONS ---'

-- 9a. Successful transaction (BEGIN … COMMIT)
BEGIN;
INSERT INTO dml_test.orders (customer_name, status, total)
VALUES ('Alice Johnson', 'confirmed', 119.98)
RETURNING order_id;

INSERT INTO dml_test.order_items (order_id, product_id, qty, unit_price)
VALUES (currval('dml_test.orders_order_id_seq'), 1, 2, 29.99),
       (currval('dml_test.orders_order_id_seq'), 2, 1, 89.99);

UPDATE dml_test.orders
SET    total = (SELECT SUM(qty * unit_price) FROM dml_test.order_items
                WHERE  order_id = currval('dml_test.orders_order_id_seq'))
WHERE  order_id = currval('dml_test.orders_order_id_seq');
COMMIT;

-- 9b. SAVEPOINT / ROLLBACK TO SAVEPOINT
BEGIN;
INSERT INTO dml_test.orders (customer_name, status)
VALUES ('Bob Smith', 'pending')
RETURNING order_id;

SAVEPOINT sp_after_order;

-- Intentional bad insert (product_id 999 does not exist)
INSERT INTO dml_test.order_items (order_id, product_id, qty, unit_price)
VALUES (currval('dml_test.orders_order_id_seq'), 999, 1, 10.00);

-- Oops — roll back to savepoint, then fix
ROLLBACK TO SAVEPOINT sp_after_order;

-- Correct insert
INSERT INTO dml_test.order_items (order_id, product_id, qty, unit_price)
VALUES (currval('dml_test.orders_order_id_seq'), 3, 1, 45.00);

RELEASE SAVEPOINT sp_after_order;
COMMIT;

-- 9c. ROLLBACK demo
BEGIN;
DELETE FROM dml_test.categories;   -- dangerous!
ROLLBACK;                           -- phew – nothing deleted

-- 9d. START TRANSACTION (alias for BEGIN)
START TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM dml_test.products;
COMMIT;

-- 9e. END (alias for COMMIT)
BEGIN;
UPDATE dml_test.products SET updated_at = now() WHERE product_id = 1;
END;

-- 9f. SET TRANSACTION characteristics
BEGIN;
SET TRANSACTION READ ONLY;
SELECT product_id, name FROM dml_test.products LIMIT 3;
COMMIT;

-- 9g. SET CONSTRAINTS
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
-- deferred FK checks allow inserting child before parent in same txn
COMMIT;

-- DCL SELECT: verify orders
SELECT '=== DCL SELECT: orders ===' AS section;
SELECT order_id, customer_name, status, total, created_at
FROM   dml_test.orders
ORDER  BY order_id;


-- =============================================================================
-- 10. CURSORS: DECLARE / FETCH / MOVE / CLOSE
-- =============================================================================
\echo '--- CURSORS ---'

BEGIN;

-- DECLARE cursor
DECLARE cur_products CURSOR FOR
    SELECT product_id, name, price
    FROM   dml_test.products
    ORDER  BY product_id;

-- FETCH rows
FETCH NEXT     FROM cur_products;
FETCH 2        FROM cur_products;
FETCH ABSOLUTE 1 FROM cur_products;   -- jump to row 1
FETCH RELATIVE 2 FROM cur_products;   -- move forward 2

-- MOVE (reposition without returning rows)
MOVE FIRST FROM cur_products;
MOVE FORWARD 3 IN cur_products;

-- FETCH remaining
FETCH ALL FROM cur_products;

-- CLOSE cursor
CLOSE cur_products;

COMMIT;


-- =============================================================================
-- 11. PREPARED STATEMENTS: PREPARE / EXECUTE / DEALLOCATE
-- =============================================================================
\echo '--- PREPARED STATEMENTS ---'

-- PREPARE a parameterised query
PREPARE get_products_by_category (INT) AS
    SELECT product_id, name, price
    FROM   dml_test.products
    WHERE  category_id = $1
    ORDER  BY price;

-- EXECUTE with different parameters
EXECUTE get_products_by_category(1);
EXECUTE get_products_by_category(2);

-- PREPARE an INSERT
PREPARE insert_audit_entry (TEXT, TEXT) AS
    INSERT INTO dml_test.audit_log (table_name, operation, detail)
    VALUES ($1, $2, 'via prepared statement');

EXECUTE insert_audit_entry('products', 'TEST');
EXECUTE insert_audit_entry('orders',   'TEST');

-- DEALLOCATE prepared statements
DEALLOCATE get_products_by_category;
DEALLOCATE insert_audit_entry;

-- DCL SELECT: confirm audit log entries
SELECT '=== DCL SELECT: audit_log entries ===' AS section;
SELECT * FROM dml_test.audit_log ORDER BY log_id;


-- =============================================================================
-- 12. DO (anonymous code block)
-- =============================================================================
\echo '--- DO ---'

DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dml_test.products WHERE is_active;
    RAISE NOTICE 'Active product count: %', v_count;

    -- bulk-deactivate cheap products (price < 15) as an example
    UPDATE dml_test.products
    SET    is_active = FALSE
    WHERE  price < 15;

    RAISE NOTICE 'Deactivated % cheap products', ROW_COUNT;
END;
$$;

-- DCL SELECT: verify deactivation
SELECT '=== DCL SELECT: is_active status after DO block ===' AS section;
SELECT product_id, name, price, is_active
FROM   dml_test.products
ORDER  BY price;


-- =============================================================================
-- 13. CALL (invoke a stored procedure)
-- =============================================================================
\echo '--- CALL ---'

-- Create a simple procedure to call
CREATE OR REPLACE PROCEDURE dml_test.log_event(p_table TEXT, p_op TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO dml_test.audit_log (table_name, operation, detail)
    VALUES (p_table, p_op, 'called via CALL at ' || now()::TEXT);
    COMMIT;
END;
$$;

CALL dml_test.log_event('orders', 'PROCEDURE_TEST');

-- DCL SELECT: confirm procedure call log
SELECT '=== DCL SELECT: audit after CALL ===' AS section;
SELECT * FROM dml_test.audit_log ORDER BY log_id;


-- =============================================================================
-- 14. EXPLAIN
-- =============================================================================
\echo '--- EXPLAIN ---'

-- Basic EXPLAIN
EXPLAIN
    SELECT p.name, c.name AS category
    FROM   dml_test.products p
    JOIN   dml_test.categories c USING (category_id)
    WHERE  p.price > 50;

-- EXPLAIN ANALYZE (actually executes)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
    SELECT * FROM dml_test.products WHERE is_active ORDER BY price;

-- EXPLAIN in JSON format
EXPLAIN (FORMAT JSON)
    SELECT COUNT(*) FROM dml_test.orders;


-- =============================================================================
-- 15. LOCK
-- =============================================================================
\echo '--- LOCK ---'

BEGIN;
-- LOCK TABLE in ACCESS SHARE mode (weakest – allows concurrent reads)
LOCK TABLE dml_test.products IN ACCESS SHARE MODE;
SELECT COUNT(*) FROM dml_test.products;
COMMIT;

BEGIN;
-- LOCK TABLE in ROW EXCLUSIVE mode (used by UPDATE/DELETE)
LOCK TABLE dml_test.orders IN ROW EXCLUSIVE MODE;
UPDATE dml_test.orders SET status = 'confirmed' WHERE status = 'pending';
COMMIT;


-- =============================================================================
-- 16. LISTEN / NOTIFY / UNLISTEN
-- =============================================================================
\echo '--- LISTEN / NOTIFY / UNLISTEN ---'

-- LISTEN for a channel
LISTEN dml_test_channel;

-- NOTIFY on that channel
NOTIFY dml_test_channel, 'payload: new order created';

-- UNLISTEN
UNLISTEN dml_test_channel;

-- UNLISTEN all channels
UNLISTEN *;


-- =============================================================================
-- 17. SET / SHOW / RESET
-- =============================================================================
\echo '--- SET / SHOW / RESET ---'

-- SET run-time parameter
SET work_mem = '16MB';
SET search_path TO dml_test, public;
SET datestyle  = 'ISO, DMY';

-- SHOW parameter value
SHOW work_mem;
SHOW search_path;
SHOW datestyle;

-- RESET to default
RESET work_mem;
RESET search_path;
RESET datestyle;

-- SET LOCAL (only for current transaction)
BEGIN;
SET LOCAL work_mem = '8MB';
SHOW work_mem;   -- 8MB inside transaction
COMMIT;
SHOW work_mem;   -- reverts after commit


-- =============================================================================
-- 18. DISCARD
-- =============================================================================
\echo '--- DISCARD ---'

-- DISCARD PLANS – clear cached query plans
DISCARD PLANS;

-- DISCARD SEQUENCES – reset sequence caches
DISCARD SEQUENCES;

-- DISCARD TEMP – drop temp tables and sequences
DISCARD TEMP;

-- DISCARD ALL – reset all session state
DISCARD ALL;


-- =============================================================================
-- 19. TRUNCATE
-- =============================================================================
\echo '--- TRUNCATE ---'

-- Truncate staging table (safe – used only in tests)
TRUNCATE TABLE dml_test.products_staging RESTART IDENTITY;

-- DCL SELECT: confirm empty
SELECT '=== DCL SELECT: products_staging after TRUNCATE ===' AS section;
SELECT COUNT(*) AS row_count FROM dml_test.products_staging;


-- =============================================================================
-- 20. DCL – GRANT, REVOKE, and verification SELECTs
-- =============================================================================
\echo '--- DCL: GRANT / REVOKE ---'

-- 20a. Create roles
CREATE ROLE dml_reader NOSUPERUSER NOLOGIN;
CREATE ROLE dml_writer NOSUPERUSER NOLOGIN;

-- 20b. GRANT schema usage
GRANT USAGE ON SCHEMA dml_test TO dml_reader, dml_writer;

-- 20c. GRANT object-level privileges
GRANT SELECT          ON ALL TABLES IN SCHEMA dml_test TO dml_reader;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dml_test TO dml_writer;
GRANT USAGE, SELECT   ON ALL SEQUENCES IN SCHEMA dml_test TO dml_writer;
GRANT EXECUTE         ON ALL FUNCTIONS  IN SCHEMA dml_test TO dml_writer;
GRANT EXECUTE         ON ALL PROCEDURES IN SCHEMA dml_test TO dml_writer;

-- 20d. GRANT table-level privilege with GRANT OPTION
GRANT SELECT ON dml_test.products TO dml_reader WITH GRANT OPTION;

-- 20e. GRANT column-level privilege
GRANT SELECT (product_id, name, price) ON dml_test.products TO dml_reader;

-- 20f. REVOKE column privilege
REVOKE SELECT (price) ON dml_test.products FROM dml_reader;

-- 20g. REVOKE schema privilege
REVOKE USAGE ON SCHEMA dml_test FROM dml_reader;

-- 20h. ALTER DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES IN SCHEMA dml_test
    GRANT SELECT ON TABLES TO dml_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA dml_test
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dml_writer;

-- ---------------------------------------------------------------------------
-- DCL SELECT: Verification queries against system catalogs
-- ---------------------------------------------------------------------------

SELECT '=== DCL SELECT: schema privileges ===' AS section;
SELECT nspname   AS schema_name,
       r.rolname AS grantee,
       privilege_type
FROM   information_schema.role_usage_grants u
JOIN   pg_namespace n ON n.nspname = u.object_schema
JOIN   pg_roles     r ON r.rolname = u.grantee
WHERE  n.nspname = 'dml_test'
ORDER  BY grantee, privilege_type;

SELECT '=== DCL SELECT: table privileges ===' AS section;
SELECT table_schema,
       table_name,
       grantee,
       privilege_type,
       is_grantable
FROM   information_schema.role_table_grants
WHERE  table_schema = 'dml_test'
ORDER  BY table_name, grantee, privilege_type;

SELECT '=== DCL SELECT: column privileges ===' AS section;
SELECT table_name,
       column_name,
       grantee,
       privilege_type
FROM   information_schema.column_privileges
WHERE  table_schema = 'dml_test'
ORDER  BY table_name, column_name, grantee;

SELECT '=== DCL SELECT: sequence privileges ===' AS section;
SELECT object_schema,
       object_name,
       grantee,
       privilege_type
FROM   information_schema.role_usage_grants
WHERE  object_schema = 'dml_test'
AND    object_type   = 'SEQUENCE'
ORDER  BY object_name, grantee;

SELECT '=== DCL SELECT: routine privileges ===' AS section;
SELECT routine_schema,
       routine_name,
       grantee,
       privilege_type
FROM   information_schema.role_routine_grants
WHERE  routine_schema = 'dml_test'
ORDER  BY routine_name, grantee;

SELECT '=== DCL SELECT: default privileges ===' AS section;
SELECT pg_get_userbyid(d.defaclrole) AS grantor,
       pg_get_userbyid(a.oid)        AS grantee,
       d.defaclobjtype               AS object_type,
       aclitem                       AS privilege
FROM   pg_default_acl d,
       LATERAL aclexplode(d.defaclacl) ae(grantor_oid, grantee_oid, priv, grant_opt),
       pg_roles a
WHERE  a.oid = ae.grantee_oid
AND    d.defaclnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'dml_test')
ORDER  BY grantee, object_type;

SELECT '=== DCL SELECT: pg_hba / session info ===' AS section;
SELECT current_user      AS session_user,
       current_database() AS current_db,
       version()          AS pg_version;


-- =============================================================================
-- 21. FINAL SUMMARY SELECTs
-- =============================================================================
\echo '--- FINAL SUMMARY ---'

SELECT '=== SUMMARY: row counts ===' AS section;
SELECT schemaname,
       relname   AS table_name,
       n_live_tup AS approx_rows
FROM   pg_stat_user_tables
WHERE  schemaname = 'dml_test'
ORDER  BY relname;

SELECT '=== SUMMARY: products ===' AS section;
SELECT p.product_id,
       c.name      AS category,
       p.name,
       p.price,
       p.stock,
       p.is_active
FROM   dml_test.products  p
JOIN   dml_test.categories c USING (category_id)
ORDER  BY p.product_id;

SELECT '=== SUMMARY: orders & items ===' AS section;
SELECT o.order_id,
       o.customer_name,
       o.status,
       o.total,
       COUNT(i.item_id) AS line_count
FROM   dml_test.orders     o
LEFT JOIN dml_test.order_items i USING (order_id)
GROUP  BY o.order_id, o.customer_name, o.status, o.total
ORDER  BY o.order_id;

SELECT '=== SUMMARY: audit log ===' AS section;
SELECT log_id, event_time, table_name, operation, detail
FROM   dml_test.audit_log
ORDER  BY log_id;


-- =============================================================================
-- 22. CLEANUP
-- =============================================================================
\echo '--- CLEANUP ---'

DROP PROCEDURE IF EXISTS dml_test.log_event(TEXT, TEXT);
DROP TABLE    IF EXISTS dml_test.cheap_products_snapshot;

-- Revoke remaining grants before dropping roles
REVOKE ALL ON ALL TABLES    IN SCHEMA dml_test FROM dml_reader, dml_writer;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA dml_test FROM dml_writer;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA dml_test FROM dml_writer;
REVOKE USAGE ON SCHEMA dml_test FROM dml_writer;

DROP SCHEMA IF EXISTS dml_test CASCADE;
DROP ROLE   IF EXISTS dml_reader;
DROP ROLE   IF EXISTS dml_writer;

\echo '=== DML / DCL test suite complete ==='

-- =============================================================================
-- END OF DML + DCL TEST FILE
-- =============================================================================
