-- =============================================================================
-- PostgreSQL 16 -- DDL (Data Definition Language) Test File
-- Reference: https://www.postgresql.org/docs/16/sql-commands.html
--
-- Covers: CREATE, ALTER, DROP, TRUNCATE, REINDEX, CLUSTER, COMMENT,
--         SECURITY LABEL, ANALYZE, VACUUM, CHECKPOINT, and related objects:
--         TABLE, VIEW, MATERIALIZED VIEW, INDEX, SEQUENCE, SCHEMA, TYPE,
--         DOMAIN, FUNCTION, PROCEDURE, TRIGGER, RULE, POLICY, ROLE/USER,
--         EXTENSION, COLLATION, TABLESPACE (noted), STATISTICS, and more.
--
-- Run as a superuser (e.g. postgres) on a test database.
-- Usage:  psql -U postgres -d postgres -f pg16_ddl_tests.sql
-- =============================================================================


-- =============================================================================
-- 0. SETUP: clean slate for idempotent re-runs
-- =============================================================================
SET client_min_messages = WARNING;  -- suppress NOTICE spam during drops

DROP SCHEMA IF EXISTS ddl_test CASCADE;
DROP ROLE  IF EXISTS ddl_test_role;
DROP ROLE  IF EXISTS ddl_test_user;

SET client_min_messages = NOTICE;

-- =============================================================================
-- 1. SCHEMA
-- =============================================================================
-- CREATE SCHEMA
CREATE SCHEMA ddl_test;
COMMENT ON SCHEMA ddl_test IS 'Sandbox schema for DDL tests';

-- ALTER SCHEMA
ALTER SCHEMA ddl_test RENAME TO ddl_test_renamed;
ALTER SCHEMA ddl_test_renamed RENAME TO ddl_test;  -- rename back

-- (DROP SCHEMA is deferred to the very end so all objects live inside it)


-- =============================================================================
-- 2. CUSTOM TYPE
-- =============================================================================
-- CREATE TYPE (composite)
CREATE TYPE ddl_test.address_type AS (
    street  TEXT,
    city    TEXT,
    zip     VARCHAR(10)
);

-- CREATE TYPE (enum)
CREATE TYPE ddl_test.order_status AS ENUM (
    'pending', 'processing', 'shipped', 'delivered', 'cancelled'
);

-- ALTER TYPE – add a new enum value
ALTER TYPE ddl_test.order_status ADD VALUE 'returned' AFTER 'delivered';

-- ALTER TYPE – rename a value
ALTER TYPE ddl_test.order_status RENAME VALUE 'returned' TO 'refunded';

-- CREATE TYPE (range)
CREATE TYPE ddl_test.float_range AS RANGE (subtype = float8);


-- =============================================================================
-- 3. DOMAIN
-- =============================================================================
-- CREATE DOMAIN
CREATE DOMAIN ddl_test.positive_int AS INTEGER
    CONSTRAINT positive_check CHECK (VALUE > 0);

-- ALTER DOMAIN – add constraint
ALTER DOMAIN ddl_test.positive_int
    ADD CONSTRAINT not_too_large CHECK (VALUE < 1000000);

-- ALTER DOMAIN – drop constraint
ALTER DOMAIN ddl_test.positive_int DROP CONSTRAINT not_too_large;

-- ALTER DOMAIN – set default
ALTER DOMAIN ddl_test.positive_int SET DEFAULT 1;

-- ALTER DOMAIN – drop default
ALTER DOMAIN ddl_test.positive_int DROP DEFAULT;


-- =============================================================================
-- 4. SEQUENCE
-- =============================================================================
-- CREATE SEQUENCE
CREATE SEQUENCE ddl_test.order_seq
    START WITH 1000
    INCREMENT BY 1
    MINVALUE 1000
    MAXVALUE 9999999
    CACHE 10;

-- ALTER SEQUENCE
ALTER SEQUENCE ddl_test.order_seq
    INCREMENT BY 5
    RESTART WITH 2000;

-- COMMENT ON SEQUENCE
COMMENT ON SEQUENCE ddl_test.order_seq IS 'Order number generator';


-- =============================================================================
-- 5. TABLES
-- =============================================================================
-- CREATE TABLE
CREATE TABLE ddl_test.customers (
    customer_id   SERIAL          PRIMARY KEY,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    email         TEXT            UNIQUE NOT NULL,
    birth_date    DATE,
    address       ddl_test.address_type,
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT now(),
    is_active     BOOLEAN         NOT NULL DEFAULT TRUE
);

CREATE TABLE ddl_test.products (
    product_id    ddl_test.positive_int PRIMARY KEY,
    name          VARCHAR(200)    NOT NULL,
    price         NUMERIC(12,2)   NOT NULL CHECK (price >= 0),
    stock         INTEGER         NOT NULL DEFAULT 0,
    status        ddl_test.order_status NOT NULL DEFAULT 'pending',
    tags          TEXT[],
    metadata      JSONB,
    search_vector TSVECTOR
);

CREATE TABLE ddl_test.orders (
    order_id      BIGINT          DEFAULT nextval('ddl_test.order_seq') PRIMARY KEY,
    customer_id   INTEGER         NOT NULL REFERENCES ddl_test.customers(customer_id)
                                      ON DELETE CASCADE ON UPDATE CASCADE,
    order_date    TIMESTAMPTZ     NOT NULL DEFAULT now(),
    total_amount  NUMERIC(14,2)   NOT NULL DEFAULT 0,
    status        ddl_test.order_status NOT NULL DEFAULT 'pending',
    notes         TEXT
);

CREATE TABLE ddl_test.order_items (
    item_id       SERIAL          PRIMARY KEY,
    order_id      BIGINT          NOT NULL REFERENCES ddl_test.orders(order_id),
    product_id    INTEGER         NOT NULL REFERENCES ddl_test.products(product_id),
    quantity      INTEGER         NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(12,2)   NOT NULL,
    UNIQUE (order_id, product_id)
);

-- COMMENT ON TABLE / COLUMN
COMMENT ON TABLE  ddl_test.customers              IS 'Customer master data';
COMMENT ON COLUMN ddl_test.customers.email        IS 'Unique contact email';
COMMENT ON TABLE  ddl_test.orders                 IS 'Sales orders header';

-- ALTER TABLE – add column
ALTER TABLE ddl_test.customers ADD COLUMN phone VARCHAR(30);

-- ALTER TABLE – set default
ALTER TABLE ddl_test.customers ALTER COLUMN phone SET DEFAULT 'N/A';

-- ALTER TABLE – drop default
ALTER TABLE ddl_test.customers ALTER COLUMN phone DROP DEFAULT;

-- ALTER TABLE – set NOT NULL
ALTER TABLE ddl_test.customers ALTER COLUMN last_name SET NOT NULL;

-- ALTER TABLE – add constraint
ALTER TABLE ddl_test.products ADD CONSTRAINT chk_stock_nonneg CHECK (stock >= 0);

-- ALTER TABLE – rename column
ALTER TABLE ddl_test.customers RENAME COLUMN phone TO phone_number;

-- ALTER TABLE – rename table
ALTER TABLE ddl_test.customers RENAME TO customers_v1;
ALTER TABLE ddl_test.customers_v1 RENAME TO customers;  -- rename back

-- ALTER TABLE – set column type
ALTER TABLE ddl_test.products ALTER COLUMN name TYPE TEXT;

-- CREATE TABLE AS (CTAS)
CREATE TABLE ddl_test.active_customers AS
    SELECT customer_id, first_name, last_name, email
    FROM   ddl_test.customers
    WHERE  is_active = TRUE;

-- SELECT INTO  (creates table in search_path; we set it explicitly)
SET search_path TO ddl_test, public;
SELECT customer_id, email
INTO   ddl_test.customer_emails_copy
FROM   ddl_test.customers;
RESET search_path;


-- =============================================================================
-- 6. INDEXES
-- =============================================================================
-- CREATE INDEX
CREATE INDEX idx_customers_email
    ON ddl_test.customers (email);

CREATE INDEX idx_customers_lastname
    ON ddl_test.customers (last_name, first_name);

-- CREATE UNIQUE INDEX
CREATE UNIQUE INDEX idx_products_name_unique
    ON ddl_test.products (name);

-- CREATE INDEX – partial
CREATE INDEX idx_orders_pending
    ON ddl_test.orders (order_date)
    WHERE status = 'pending';

-- CREATE INDEX – GIN for JSONB
CREATE INDEX idx_products_metadata_gin
    ON ddl_test.products USING GIN (metadata);

-- CREATE INDEX – TSVECTOR full-text search
CREATE INDEX idx_products_fts
    ON ddl_test.products USING GIN (search_vector);

-- CREATE INDEX – CONCURRENTLY (non-blocking)
CREATE INDEX CONCURRENTLY idx_orders_customer
    ON ddl_test.orders (customer_id);

-- ALTER INDEX – rename
ALTER INDEX ddl_test.idx_customers_email RENAME TO idx_customers_email_v2;

-- CLUSTER – physically sort table by index
CLUSTER ddl_test.orders USING idx_orders_customer;

-- REINDEX – rebuild a single index
REINDEX INDEX ddl_test.idx_customers_email_v2;

-- REINDEX – rebuild all indexes on a table
REINDEX TABLE ddl_test.products;


-- =============================================================================
-- 7. VIEWS
-- =============================================================================
-- CREATE VIEW
CREATE VIEW ddl_test.v_active_customers AS
    SELECT customer_id, first_name, last_name, email, created_at
    FROM   ddl_test.customers
    WHERE  is_active = TRUE;

-- CREATE OR REPLACE VIEW
CREATE OR REPLACE VIEW ddl_test.v_active_customers AS
    SELECT customer_id,
           first_name || ' ' || last_name AS full_name,
           email,
           created_at
    FROM   ddl_test.customers
    WHERE  is_active = TRUE;

-- ALTER VIEW – rename
ALTER VIEW ddl_test.v_active_customers RENAME TO v_active_customers_v2;
ALTER VIEW ddl_test.v_active_customers_v2 RENAME TO v_active_customers;

-- COMMENT ON VIEW
COMMENT ON VIEW ddl_test.v_active_customers IS 'Active customers with full name';


-- =============================================================================
-- 8. MATERIALIZED VIEW
-- =============================================================================
-- CREATE MATERIALIZED VIEW
CREATE MATERIALIZED VIEW ddl_test.mv_order_summary AS
    SELECT  c.customer_id,
            c.first_name || ' ' || c.last_name AS customer_name,
            COUNT(o.order_id)    AS total_orders,
            SUM(o.total_amount)  AS lifetime_value
    FROM    ddl_test.customers c
    LEFT JOIN ddl_test.orders o USING (customer_id)
    GROUP BY c.customer_id, c.first_name, c.last_name
    WITH DATA;

-- CREATE INDEX on materialized view
CREATE INDEX idx_mv_order_summary_customer
    ON ddl_test.mv_order_summary (customer_id);

-- ALTER MATERIALIZED VIEW
ALTER MATERIALIZED VIEW ddl_test.mv_order_summary
    RENAME TO mv_order_summary_v2;
ALTER MATERIALIZED VIEW ddl_test.mv_order_summary_v2
    RENAME TO mv_order_summary;

-- REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW ddl_test.mv_order_summary;

-- REFRESH MATERIALIZED VIEW CONCURRENTLY (requires unique index)
REFRESH MATERIALIZED VIEW CONCURRENTLY ddl_test.mv_order_summary;


-- =============================================================================
-- 9. FUNCTIONS & PROCEDURES
-- =============================================================================
-- CREATE FUNCTION (SQL)
CREATE OR REPLACE FUNCTION ddl_test.fn_full_name(
    p_first TEXT,
    p_last  TEXT
)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE STRICT
AS $$
    SELECT p_first || ' ' || p_last;
$$;

-- CREATE FUNCTION (PL/pgSQL)
CREATE OR REPLACE FUNCTION ddl_test.fn_order_total(p_order_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT SUM(quantity * unit_price)
    INTO   v_total
    FROM   ddl_test.order_items
    WHERE  order_id = p_order_id;
    RETURN COALESCE(v_total, 0);
END;
$$;

-- CREATE PROCEDURE
CREATE OR REPLACE PROCEDURE ddl_test.proc_activate_customer(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ddl_test.customers
    SET    is_active = TRUE
    WHERE  customer_id = p_id;
    COMMIT;
END;
$$;

-- ALTER FUNCTION – change property
ALTER FUNCTION ddl_test.fn_full_name(TEXT, TEXT) SECURITY DEFINER;

-- ALTER PROCEDURE
ALTER PROCEDURE ddl_test.proc_activate_customer(INT)
    RENAME TO proc_activate_customer_v1;
ALTER PROCEDURE ddl_test.proc_activate_customer_v1(INT)
    RENAME TO proc_activate_customer;

-- COMMENT ON FUNCTION
COMMENT ON FUNCTION ddl_test.fn_full_name(TEXT, TEXT)
    IS 'Concatenates first and last name';


-- =============================================================================
-- 10. TRIGGERS
-- =============================================================================
-- Function used by trigger
CREATE OR REPLACE FUNCTION ddl_test.trg_fn_update_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.created_at := now();
    RETURN NEW;
END;
$$;

-- CREATE TRIGGER
CREATE TRIGGER trg_customers_updated
    BEFORE INSERT OR UPDATE ON ddl_test.customers
    FOR EACH ROW
    EXECUTE FUNCTION ddl_test.trg_fn_update_timestamp();

-- ALTER TRIGGER – rename
ALTER TRIGGER trg_customers_updated ON ddl_test.customers
    RENAME TO trg_customers_timestamp;

-- DISABLE / ENABLE TRIGGER via ALTER TABLE
ALTER TABLE ddl_test.customers DISABLE TRIGGER trg_customers_timestamp;
ALTER TABLE ddl_test.customers ENABLE  TRIGGER trg_customers_timestamp;


-- =============================================================================
-- 11. RULES
-- =============================================================================
-- CREATE RULE (redirect INSERT on view to base table)
CREATE RULE rule_insert_active_customer
    AS ON INSERT TO ddl_test.v_active_customers
    DO INSTEAD
        INSERT INTO ddl_test.customers (first_name, last_name, email)
        VALUES (NEW.full_name, '', NEW.email);

-- ALTER RULE – rename
ALTER RULE rule_insert_active_customer
    ON ddl_test.v_active_customers
    RENAME TO rule_insert_active_cust_v2;

-- DROP RULE (clean up — rules are rarely used in modern PG)
DROP RULE rule_insert_active_cust_v2 ON ddl_test.v_active_customers;


-- =============================================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICY
-- =============================================================================
-- Enable RLS on orders table
ALTER TABLE ddl_test.orders ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY
CREATE POLICY policy_orders_owner
    ON ddl_test.orders
    FOR ALL
    USING (customer_id = current_setting('app.current_customer_id', TRUE)::INT);

-- ALTER POLICY
ALTER POLICY policy_orders_owner
    ON ddl_test.orders
    RENAME TO policy_orders_by_customer;

-- DROP POLICY (will re-create for demo completeness)
DROP POLICY policy_orders_by_customer ON ddl_test.orders;
ALTER TABLE ddl_test.orders DISABLE ROW LEVEL SECURITY;


-- =============================================================================
-- 13. COLLATION
-- =============================================================================
-- CREATE COLLATION (based on an existing locale)
CREATE COLLATION IF NOT EXISTS ddl_test.case_insensitive (
    PROVIDER = icu,
    LOCALE   = 'und-u-ks-level2',
    DETERMINISTIC = FALSE
);

-- ALTER COLLATION – rename
ALTER COLLATION ddl_test.case_insensitive
    RENAME TO ci_collation;


-- =============================================================================
-- 14. STATISTICS (extended)
-- =============================================================================
-- CREATE STATISTICS
CREATE STATISTICS ddl_test.stat_order_items_corr
    (dependencies)
    ON order_id, product_id
    FROM ddl_test.order_items;

-- ALTER STATISTICS
ALTER STATISTICS ddl_test.stat_order_items_corr
    RENAME TO stat_order_items_deps;


-- =============================================================================
-- 15. ROLES & USERS
-- =============================================================================
-- CREATE ROLE
CREATE ROLE ddl_test_role
    NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOLOGIN;

-- CREATE USER (alias for CREATE ROLE ... LOGIN)
CREATE USER ddl_test_user
    WITH PASSWORD 'Test@1234'
    NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- ALTER ROLE
ALTER ROLE ddl_test_role CONNECTION LIMIT 5;
ALTER ROLE ddl_test_user VALID UNTIL '2027-12-31';

-- ALTER GROUP (legacy alias; adds member to role)
ALTER GROUP ddl_test_role ADD USER ddl_test_user;

-- ALTER USER (alias for ALTER ROLE)
ALTER USER ddl_test_user RENAME TO ddl_test_user_v1;
ALTER USER ddl_test_user_v1 RENAME TO ddl_test_user;  -- rename back

-- COMMENT ON ROLE
COMMENT ON ROLE ddl_test_role IS 'Read-only role for DDL test schema';


-- =============================================================================
-- 16. EXTENSION
-- =============================================================================
-- CREATE EXTENSION (pg_trgm is bundled with most PG installs)
CREATE EXTENSION IF NOT EXISTS pg_trgm
    WITH SCHEMA ddl_test;

-- CREATE EXTENSION (uuid-ossp)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"
    WITH SCHEMA ddl_test;

-- ALTER EXTENSION – update (only meaningful if a newer version is available)
-- ALTER EXTENSION pg_trgm UPDATE;   -- uncomment if upgrade available

-- DROP EXTENSION
DROP EXTENSION IF EXISTS "uuid-ossp";


-- =============================================================================
-- 17. ANALYZE & VACUUM (maintenance)
-- =============================================================================
-- ANALYZE – collect statistics for the query planner
ANALYZE ddl_test.customers;
ANALYZE ddl_test.orders;
ANALYZE ddl_test.order_items;

-- VACUUM – reclaim storage
VACUUM ddl_test.customers;

-- VACUUM ANALYZE – combined
VACUUM ANALYZE ddl_test.orders;

-- VACUUM FULL – full rewrite (locks table)
VACUUM FULL ddl_test.order_items;

-- CHECKPOINT – flush WAL buffers (requires superuser)
CHECKPOINT;


-- =============================================================================
-- 18. COMMENT (miscellaneous objects)
-- =============================================================================
COMMENT ON TYPE   ddl_test.order_status         IS 'Enum for order lifecycle states';
COMMENT ON DOMAIN ddl_test.positive_int         IS 'Integer domain enforcing positive values';
COMMENT ON INDEX  ddl_test.idx_customers_email_v2 IS 'Index on customer email';
COMMENT ON TRIGGER trg_customers_timestamp
    ON ddl_test.customers IS 'Keeps created_at current on insert/update';


-- =============================================================================
-- 19. TRUNCATE
-- =============================================================================
-- TRUNCATE (no data yet, but tests the command parses & executes)
TRUNCATE TABLE ddl_test.active_customers;
TRUNCATE TABLE ddl_test.customer_emails_copy RESTART IDENTITY;

-- TRUNCATE multiple tables (CASCADE follows FKs)
TRUNCATE TABLE ddl_test.order_items, ddl_test.orders CASCADE;


-- =============================================================================
-- 20. ALTER DEFAULT PRIVILEGES
-- =============================================================================
ALTER DEFAULT PRIVILEGES IN SCHEMA ddl_test
    GRANT SELECT ON TABLES TO ddl_test_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA ddl_test
    GRANT USAGE ON SEQUENCES TO ddl_test_role;


-- =============================================================================
-- 21. DROP STATEMENTS (reverse order of creation)
-- =============================================================================
-- Drop statistics
DROP STATISTICS IF EXISTS ddl_test.stat_order_items_deps;

-- Drop collation
DROP COLLATION IF EXISTS ddl_test.ci_collation;

-- Drop materialized view
DROP MATERIALIZED VIEW IF EXISTS ddl_test.mv_order_summary;

-- Drop views
DROP VIEW IF EXISTS ddl_test.v_active_customers;

-- Drop triggers
DROP TRIGGER IF EXISTS trg_customers_timestamp ON ddl_test.customers;

-- Drop functions / procedures
DROP FUNCTION  IF EXISTS ddl_test.trg_fn_update_timestamp();
DROP FUNCTION  IF EXISTS ddl_test.fn_full_name(TEXT, TEXT);
DROP FUNCTION  IF EXISTS ddl_test.fn_order_total(BIGINT);
DROP PROCEDURE IF EXISTS ddl_test.proc_activate_customer(INT);

-- Drop tables (CASCADE handles FK deps)
DROP TABLE IF EXISTS ddl_test.customer_emails_copy CASCADE;
DROP TABLE IF EXISTS ddl_test.active_customers      CASCADE;
DROP TABLE IF EXISTS ddl_test.order_items           CASCADE;
DROP TABLE IF EXISTS ddl_test.orders                CASCADE;
DROP TABLE IF EXISTS ddl_test.products              CASCADE;
DROP TABLE IF EXISTS ddl_test.customers             CASCADE;

-- Drop sequence
DROP SEQUENCE IF EXISTS ddl_test.order_seq;

-- Drop domain
DROP DOMAIN IF EXISTS ddl_test.positive_int;

-- Drop types
DROP TYPE IF EXISTS ddl_test.float_range;
DROP TYPE IF EXISTS ddl_test.order_status;
DROP TYPE IF EXISTS ddl_test.address_type;

-- Drop extension
DROP EXTENSION IF EXISTS pg_trgm;

-- Drop schema (CASCADE for anything remaining)
DROP SCHEMA IF EXISTS ddl_test CASCADE;

-- Drop roles/users
DROP USER IF EXISTS ddl_test_user;
DROP ROLE IF EXISTS ddl_test_role;

-- =============================================================================
-- END OF DDL TEST FILE
-- =============================================================================
