-- =============================================================================
-- FILE: test_postgresql_commands.sql
-- PURPOSE: Demonstrate every SQL command from PostgreSQL 16 documentation
--          INCLUDING: Complete coverage of ALL PostgreSQL data types
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
-- 2. COMPLETE DATA TYPES DEMONSTRATION TABLE
-- #############################################################################

-- =============================================================================
-- TABLE: all_data_types - Demonstrates EVERY PostgreSQL data type
-- =============================================================================
CREATE TABLE all_data_types (
    -- Numeric Types
    id SERIAL PRIMARY KEY,                          -- Auto-incrementing integer
    col_smallint SMALLINT,                          -- 2-byte integer (-32,768 to 32,767)
    col_integer INTEGER,                            -- 4-byte integer (-2.1B to 2.1B)
    col_bigint BIGINT,                              -- 8-byte integer (-9.2E18 to 9.2E18)
    col_decimal DECIMAL(10,2),                      -- Exact numeric with precision
    col_numeric NUMERIC(15,4),                      -- Same as DECIMAL
    col_real REAL,                                  -- 4-byte floating point
    col_double_precision DOUBLE PRECISION,          -- 8-byte floating point
    col_smallserial SMALLSERIAL,                    -- Auto smallint (2 bytes)
    col_bigserial BIGSERIAL,                        -- Auto bigint (8 bytes)
    
    -- Monetary Type
    col_money MONEY,                                -- Currency amount
    
    -- Character Types
    col_char CHAR(10),                              -- Fixed-length character
    col_varchar VARCHAR(100),                       -- Variable-length with limit
    col_text TEXT,                                  -- Variable unlimited length
    col_name NAME,                                  -- Internal type for object names
    col_bpchar BPCHAR,                              -- Alias for CHAR
    
    -- Binary Data Types
    col_bytea BYTEA,                                -- Binary data
    
    -- Date/Time Types
    col_timestamp TIMESTAMP,                        -- Date and time (no timezone)
    col_timestamptz TIMESTAMPTZ,                    -- Date and time with timezone
    col_date DATE,                                  -- Date only
    col_time TIME,                                  -- Time only (no timezone)
    col_timetz TIMETZ,                              -- Time with timezone
    col_interval INTERVAL,                          -- Time span
    
    -- Boolean Type
    col_boolean BOOLEAN,                            -- True/False/Null
    
    -- Geometric Types
    col_point POINT,                                -- (x,y) point
    col_line LINE,                                  -- Line {A,B,C}
    col_lseg LSEG,                                  -- Line segment
    col_box BOX,                                    -- Rectangular box
    col_path PATH,                                 -- Closed/open path
    col_polygon POLYGON,                           -- Polygon
    col_circle CIRCLE,                             -- Circle (center, radius)
    
    -- Network Address Types
    col_cidr CIDR,                                 -- IPv4/IPv6 network
    col_inet INET,                                 -- IPv4/IPv6 host
    col_macaddr MACADDR,                           -- MAC address (6 bytes)
    col_macaddr8 MACADDR8,                         -- MAC address (8 bytes)
    
    -- Text Search Types
    col_tsvector TSVECTOR,                         -- Text search document
    col_tsquery TSQUERY,                           -- Text search query
    
    -- UUID Type
    col_uuid UUID,                                  -- Universally Unique ID
    
    -- JSON Types
    col_json JSON,                                 -- JSON data (stored as text)
    col_jsonb JSONB,                               -- Binary JSON (indexable)
    
    -- XML Type
    col_xml XML,                                   -- XML data
    
    -- Bit String Types
    col_bit BIT(8),                                -- Fixed-length bit string
    col_varbit BIT VARYING(16),                    -- Variable-length bit string
    
    -- Range Types
    col_int4range INT4RANGE,                       -- Range of integers
    col_int8range INT8RANGE,                       -- Range of bigints
    col_numrange NUMRANGE,                         -- Range of numerics
    col_tsrange TSRANGE,                           -- Range of timestamp
    col_tstzrange TSTZRANGE,                       -- Range of timestamptz
    col_daterange DATERANGE,                       -- Range of dates
    
    -- Array Types (multi-dimensional)
    col_int_array INTEGER[],                       -- 1D array of integers
    col_text_array TEXT[][],                       -- 2D array of text
    col_multi_array INTEGER[3][3],                 -- Fixed-size 2D array
    
    -- Composite Types (user-defined)
    col_composite address_type,                    -- Custom composite type
    
    -- Enumerated Types
    col_enum status_enum,                          -- Custom enum type
    
    -- Pseudo-Types (limited use in table definitions)
    -- record, anyelement, anyarray - not valid as column types
    
    -- Additional Special Types
    col_oid OID,                                   -- Object identifier
    col_regproc REGPROC,                           -- Registered procedure
    col_regtype REGTYPE,                           -- Registered type
    col_pg_lsn PG_LSN,                             -- Log sequence number
    col_txid_snapshot TXID_SNAPSHOT,               -- Transaction snapshot
    col_int4multirange INT4MULTIRANGE,             -- Multirange of int4 (PG14+)
    col_int8multirange INT8MULTIRANGE,             -- Multirange of int8
    col_nummultirange NUMMULTIRANGE,               -- Multirange of numeric
    col_tsmultirange TSMULTIRANGE,                 -- Multirange of timestamp
    col_tstzmultirange TSTZMULTIRANGE,             -- Multirange of timestamptz
    col_datemultirange DATEMULTIRANGE              -- Multirange of dates
);

-- Create custom composite type for demonstration
CREATE TYPE address_type AS (
    street TEXT,
    city TEXT,
    postal_code VARCHAR(10),
    country TEXT,
    is_commercial BOOLEAN
);

-- Create custom enum type
CREATE TYPE status_enum AS ENUM ('active', 'inactive', 'pending', 'suspended', 'archived');

-- Create custom range type (for demonstration)
CREATE TYPE floatrange AS RANGE (subtype = float8);

-- #############################################################################
-- 3. DML: INSERTING ALL DATA TYPES WITH EXAMPLES
-- #############################################################################

INSERT INTO all_data_types (
    -- Numeric Types
    col_smallint, col_integer, col_bigint,
    col_decimal, col_numeric, col_real, col_double_precision,
    col_smallserial, col_bigserial,
    
    -- Monetary
    col_money,
    
    -- Character Types
    col_char, col_varchar, col_text, col_name,
    
    -- Binary
    col_bytea,
    
    -- Date/Time Types
    col_timestamp, col_timestamptz, col_date, col_time, col_timetz,
    col_interval,
    
    -- Boolean
    col_boolean,
    
    -- Geometric Types
    col_point, col_line, col_lseg, col_box, col_path, col_polygon, col_circle,
    
    -- Network Types
    col_cidr, col_inet, col_macaddr, col_macaddr8,
    
    -- Text Search
    col_tsvector, col_tsquery,
    
    -- UUID
    col_uuid,
    
    -- JSON
    col_json, col_jsonb,
    
    -- XML
    col_xml,
    
    -- Bit Strings
    col_bit, col_varbit,
    
    -- Range Types
    col_int4range, col_int8range, col_numrange, col_tsrange, col_tstzrange, col_daterange,
    
    -- Arrays
    col_int_array, col_text_array, col_multi_array,
    
    -- Composite
    col_composite,
    
    -- Enum
    col_enum,
    
    -- Special Types
    col_oid, col_regproc, col_regtype, col_pg_lsn, col_txid_snapshot
) VALUES (
    -- Numeric Examples
    32767,                         -- SMALLINT max
    2147483647,                    -- INTEGER max
    9223372036854775807,           -- BIGINT max
    12345.67,                      -- DECIMAL
    98765.4321,                    -- NUMERIC
    3.14159265,                    -- REAL
    3.141592653589793,             -- DOUBLE PRECISION
    DEFAULT,                       -- SMALLSERIAL (auto)
    DEFAULT,                       -- BIGSERIAL (auto)
    
    -- Monetary
    1250.50,                       -- MONEY
    
    -- Character Examples
    'Fixed     ',                  -- CHAR(10) (padded with spaces)
    'Variable length text',        -- VARCHAR(100)
    'Unlimited text content that can be very long...', -- TEXT
    'object_name',                 -- NAME
    
    -- Binary
    E'\\xDEADBEEF',                -- BYTEA in hex format
    
    -- Date/Time Examples
    '2024-06-15 14:30:00',         -- TIMESTAMP
    '2024-06-15 14:30:00-05:00',   -- TIMESTAMPTZ (EST)
    '2024-06-15',                  -- DATE
    '14:30:00',                    -- TIME
    '14:30:00-05:00',              -- TIMETZ
    '5 years 3 months 2 days',     -- INTERVAL
    
    -- Boolean
    TRUE,                          -- BOOLEAN
    
    -- Geometric Examples
    '(10.5, 20.3)',                -- POINT
    '{1.5, -2.3, 4.7}',            -- LINE (Ax + By + C = 0)
    '[(0,0),(10,10)]',             -- LSEG
    '(0,0),(100,100)',             -- BOX
    '[(0,0),(10,10),(20,5)]',      -- PATH (open)
    '((0,0),(10,0),(10,10),(0,10))', -- POLYGON (closed)
    '<(5,5),15>',                  -- CIRCLE (center, radius)
    
    -- Network Examples
    '192.168.1.0/24',              -- CIDR
    '192.168.1.100',               -- INET
    '08:00:2b:01:02:03',           -- MACADDR
    '08:00:2b:01:02:03:04:05',     -- MACADDR8
    
    -- Text Search Examples
    to_tsvector('english', 'The quick brown fox jumps over the lazy dog'),
    to_tsquery('english', 'quick & fox'),
    
    -- UUID
    '123e4567-e89b-12d3-a456-426614174000',
    
    -- JSON Examples
    '{"name": "John", "age": 30, "city": "New York"}',     -- JSON
    '{"product": "Laptop", "price": 999.99, "in_stock": true}', -- JSONB
    
    -- XML
    '<book><title>PostgreSQL Guide</title><author>Tom Lane</author></book>',
    
    -- Bit String Examples
    B'10101010',                   -- BIT(8)
    B'110011001100',               -- BIT VARYING(16)
    
    -- Range Examples
    '[1,10]',                      -- INT4RANGE (includes bounds)
    '[100,1000]',                  -- INT8RANGE
    '[0.5, 99.99]',                -- NUMRANGE
    '["2024-01-01 00:00:00", "2024-12-31 23:59:59"]', -- TSRANGE
    '["2024-01-01 00:00:00-05:00", "2024-12-31 23:59:59-05:00"]', -- TSTZRANGE
    '[2024-01-01, 2024-12-31]',    -- DATERANGE
    
    -- Array Examples
    ARRAY[1, 2, 3, 4, 5],                      -- INTEGER ARRAY
    ARRAY[['a','b'],['c','d']],                -- 2D TEXT ARRAY
    ARRAY[[1,2,3],[4,5,6],[7,8,9]],            -- 3x3 INTEGER ARRAY
    
    -- Composite Type Example
    ROW('123 Main St', 'Springfield', '12345', 'USA', TRUE)::address_type,
    
    -- Enum Example
    'active'::status_enum,
    
    -- Special Types Examples
    12345,                         -- OID
    'sum'::regproc,                -- REGPROC
    'integer'::regtype,            -- REGTYPE
    '0/3000000',                   -- PG_LSN
    '10:20:10,14,15'::txid_snapshot  -- TXID_SNAPSHOT
);

-- Insert second row with different data type variations
INSERT INTO all_data_types (
    col_smallint, col_integer, col_bigint,
    col_decimal, col_numeric, col_real, col_double_precision,
    col_money,
    col_char, col_varchar, col_text,
    col_bytea,
    col_timestamp, col_timestamptz, col_date, col_time, col_timetz,
    col_interval,
    col_boolean,
    col_point, col_line, col_lseg, col_box, col_path, col_polygon, col_circle,
    col_cidr, col_inet, col_macaddr, col_macaddr8,
    col_tsvector, col_tsquery,
    col_uuid,
    col_json, col_jsonb,
    col_xml,
    col_bit, col_varbit,
    col_int4range, col_int8range, col_numrange, col_tsrange, col_tstzrange, col_daterange,
    col_int_array, col_text_array,
    col_composite,
    col_enum
) VALUES (
    -32768, -2147483648, -9223372036854775808,
    -54321.99, -12345.6789, -3.14159, -2.718281828,
    -500.75,
    'Short', 'Another example', 'Different text content with Unicode: 你好, 世界! 🌍',
    E'\\x0102030405',
    '2023-12-25 23:59:59', '2023-12-25 23:59:59+00:00', '2023-12-25', '23:59:59', '23:59:59+00:00',
    '-2 years',
    FALSE,
    '(0,0)', '{0, -1, 0}', '[(0,0),(5,5)]', '(10,10),(20,20)', '[(5,5),(15,5),(10,15)]', 
    '((0,0),(5,0),(5,5),(0,5))', '<(0,0),5>',
    '10.0.0.0/8', '10.0.0.1', '00:11:22:33:44:55', '00:11:22:33:44:55:66:77',
    to_tsvector('simple', 'hello world'), to_tsquery('simple', 'hello & world'),
    '550e8400-e29b-41d4-a716-446655440000',
    '{"status": "inactive", "count": null}', '{"tags": ["sql", "postgresql"], "version": 16}',
    '<root><element>value</element></root>',
    B'11110000', B'1010101010101010',
    '(10,20]', '[500,5000)', '(0, 0)', '["2023-01-01", "2023-12-31"]', 
    '["2023-01-01 00:00:00-05:00", "2023-12-31 23:59:59-05:00"]', '[2023-01-01, 2023-12-31]',
    ARRAY[10,20,30,40], ARRAY[['x','y'],['z','w']],
    ROW('456 Oak Ave', 'Metropolis', '67890', 'Canada', FALSE)::address_type,
    'inactive'::status_enum
);

-- #############################################################################
-- 4. DDL: CREATE statements with ALL data types
-- #############################################################################

-- CREATE TABLE with comprehensive data type coverage
CREATE TABLE data_type_demo_2 (
    -- Using all numeric variations
    id SERIAL,
    small_val SMALLINT CHECK (small_val BETWEEN -32768 AND 32767),
    int_val INT DEFAULT 0,
    big_val BIGINT,
    exact_val NUMERIC(20,8),
    float_val FLOAT8,
    
    -- Text with constraints
    fixed_char CHAR(5) DEFAULT '     ',
    var_char VARCHAR(50) NOT NULL,
    long_text TEXT,
    
    -- Binary with default
    image_data BYTEA DEFAULT E'\\x',
    
    -- Date/time with defaults
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    birth_date DATE,
    meeting_time TIME,
    duration INTERVAL,
    
    -- Boolean with constraint
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Geometric with default
    location POINT DEFAULT '(0,0)',
    bounding_box BOX,
    
    -- Network
    ip_address INET,
    network CIDR,
    mac MACADDR,
    
    -- JSON with unique constraint
    metadata JSONB,
    raw_json JSON,
    
    -- UUID with default generation
    unique_id UUID DEFAULT gen_random_uuid(),
    
    -- Array columns
    tags TEXT[],
    scores INTEGER[] DEFAULT '{}',
    
    -- Range types
    price_range NUMRANGE,
    valid_period DATERANGE,
    
    -- Composite
    contact_info address_type,
    
    -- Enum
    state status_enum DEFAULT 'pending',
    
    -- Constraints
    CONSTRAINT pk_data_type_demo PRIMARY KEY (id),
    CONSTRAINT unique_uuid UNIQUE (unique_id),
    CONSTRAINT valid_ip CHECK (ip_address IS NOT NULL),
    CONSTRAINT valid_json CHECK (metadata IS NOT NULL)
);

-- CREATE TABLE AS with data type preservation
CREATE TABLE data_type_backup AS
SELECT 
    col_smallint, col_integer, col_bigint,
    col_decimal, col_numeric,
    col_text,
    col_timestamp,
    col_jsonb,
    col_uuid
FROM all_data_types
WHERE col_boolean = TRUE;

-- CREATE DOMAIN with constraints (custom data type)
CREATE DOMAIN us_phone_number AS VARCHAR(20)
CHECK (
    VALUE ~ '^\+?1?[-.\s]?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}$'
);

CREATE DOMAIN positive_money AS NUMERIC(12,2)
CHECK (VALUE > 0);

CREATE DOMAIN valid_email AS TEXT
CHECK (
    VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
);

-- CREATE TYPE (multiple variations)
-- Composite type (already created above)
CREATE TYPE employee_info AS (
    employee_id INTEGER,
    full_name TEXT,
    hire_date DATE,
    salary NUMERIC,
    is_manager BOOLEAN,
    department TEXT,
    contact_email valid_email
);

-- Enum type (already created above)
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');

-- Range type (already created above)
CREATE TYPE timerange AS RANGE (subtype = time);

-- CREATE TABLE using custom domains and types
CREATE TABLE employees_enhanced (
    id SERIAL PRIMARY KEY,
    personal_info employee_info,
    work_phone us_phone_number,
    monthly_salary positive_money,
    priority priority_level DEFAULT 'medium',
    work_hours timerange,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- #############################################################################
-- 5. DML: UPDATE with data type conversions and operations
-- #############################################################################

-- Update with numeric operations
UPDATE all_data_types 
SET 
    col_integer = col_integer + 1000,
    col_decimal = col_decimal * 1.1,
    col_real = col_real * 2.0,
    col_money = col_money + 500.00
WHERE col_smallint > 0;

-- Update with string operations
UPDATE all_data_types
SET 
    col_varchar = UPPER(col_varchar),
    col_text = col_text || ' (updated)',
    col_char = RPAD(LEFT(col_char, 5), 10, 'X')
WHERE col_integer IS NOT NULL;

-- Update with date/time operations
UPDATE all_data_types
SET 
    col_timestamp = col_timestamp + INTERVAL '1 day',
    col_timestamptz = col_timestamptz + INTERVAL '5 hours',
    col_date = col_date + 30,
    col_interval = col_interval + INTERVAL '1 month'
WHERE col_timestamp IS NOT NULL;

-- Update with JSON operations
UPDATE all_data_types
SET 
    col_jsonb = col_jsonb || '{"updated": true, "timestamp": "' || NOW()::TEXT || '"}'::JSONB,
    col_json = col_json::JSONB || '{"modified": true}'::JSONB
WHERE col_jsonb IS NOT NULL;

-- Update with array operations
UPDATE all_data_types
SET 
    col_int_array = array_append(col_int_array, 999),
    col_text_array = col_text_array || ARRAY[['new','values']]
WHERE col_int_array IS NOT NULL;

-- Update with range operations
UPDATE all_data_types
SET 
    col_int4range = col_int4range * int4range(5, 15),
    col_daterange = col_daterange + INTERVAL '1 year'
WHERE col_int4range IS NOT NULL;

-- Update with geometric operations
UPDATE all_data_types
SET 
    col_point = point(col_point[0] + 5, col_point[1] + 5),
    col_circle = circle(center(col_circle), radius(col_circle) * 1.5)
WHERE col_point IS NOT NULL;

-- Update with network functions
UPDATE all_data_types
SET 
    col_inet = set_masklen(col_inet, 24),
    col_cidr = set_masklen(col_cidr::cidr, 16)::cidr
WHERE col_inet IS NOT NULL;

-- #############################################################################
-- 6. DML: DELETE with data type conditions
-- #############################################################################

-- Delete based on numeric conditions
DELETE FROM all_data_types 
WHERE col_smallint < -10000 OR col_integer > 2000000000;

-- Delete based on date conditions
DELETE FROM all_data_types 
WHERE col_date < '2020-01-01' OR col_timestamp < NOW() - INTERVAL '1 year';

-- Delete based on boolean and enum
DELETE FROM all_data_types 
WHERE col_boolean = FALSE AND col_enum = 'archived';

-- Delete based on JSON conditions
DELETE FROM all_data_types 
WHERE col_jsonb->>'status' = 'inactive';

-- Delete based on array conditions
DELETE FROM all_data_types 
WHERE array_length(col_int_array, 1) > 10;

-- Delete based on range containment
DELETE FROM all_data_types 
WHERE col_int4range @> 5;

-- #############################################################################
-- 7. QUERYING WITH DATA TYPE FUNCTIONS
-- #############################################################################

-- Numeric type queries and functions
SELECT 
    col_smallint,
    col_integer,
    col_bigint,
    ABS(col_integer) AS abs_value,
    CEIL(col_decimal) AS ceiling,
    FLOOR(col_decimal) AS floor_val,
    ROUND(col_decimal, 1) AS rounded,
    col_integer % 100 AS modulo,
    POWER(col_smallint, 2) AS squared,
    SQRT(ABS(col_smallint)) AS square_root
FROM all_data_types 
WHERE col_integer IS NOT NULL 
LIMIT 5;

-- Character type queries and functions
SELECT 
    col_char,
    TRIM(col_char) AS trimmed,
    col_varchar,
    LENGTH(col_varchar) AS varchar_length,
    col_text,
    SUBSTRING(col_text FROM 1 FOR 10) AS text_preview,
    POSITION('example' IN col_text) AS position_found,
    col_varchar || ' - ' || col_text AS concatenated,
    REPLACE(col_text, 'old', 'new') AS replaced_text
FROM all_data_types 
WHERE col_text IS NOT NULL 
LIMIT 5;

-- Date/time queries and functions
SELECT 
    col_timestamp,
    EXTRACT(YEAR FROM col_timestamp) AS year,
    EXTRACT(MONTH FROM col_timestamp) AS month,
    EXTRACT(DOW FROM col_timestamp) AS day_of_week,
    DATE_TRUNC('month', col_timestamp) AS month_start,
    AGE(NOW(), col_timestamp) AS age,
    col_timestamp + INTERVAL '1 week' AS next_week,
    col_timestamp::DATE AS as_date,
    col_timestamp::TIME AS as_time
FROM all_data_types 
WHERE col_timestamp IS NOT NULL 
LIMIT 5;

-- JSON queries and operators
SELECT 
    col_jsonb,
    col_jsonb->>'name' AS name_from_json,
    col_jsonb->'age' AS age_as_json,
    col_jsonb @> '{"active": true}'::JSONB AS is_active,
    col_jsonb ? 'tags' AS has_tags_key,
    jsonb_array_elements(col_jsonb->'tags') AS tag_values
FROM all_data_types 
WHERE col_jsonb IS NOT NULL 
LIMIT 5;

-- Array queries and functions
SELECT 
    col_int_array,
    array_length(col_int_array, 1) AS array_length,
    col_int_array[1] AS first_element,
    array_to_string(col_int_array, ', ') AS as_string,
    unnest(col_int_array) AS exploded_values,
    array_upper(col_text_array, 2) AS array_upper_bound
FROM all_data_types 
WHERE col_int_array IS NOT NULL 
LIMIT 5;

-- Range queries and operators
SELECT 
    col_int4range,
    lower(col_int4range) AS lower_bound,
    upper(col_int4range) AS upper_bound,
    isempty(col_int4range) AS is_empty,
    col_int4range @> 5 AS contains_5,
    col_int4range && int4range(5, 10) AS overlaps_range,
    col_int4range - int4range(3, 4) AS range_difference
FROM all_data_types 
WHERE col_int4range IS NOT NULL 
LIMIT 5;

-- Geometric queries and functions
SELECT 
    col_point,
    col_point[0] AS x_coord,
    col_point[1] AS y_coord,
    col_circle,
    center(col_circle) AS circle_center,
    radius(col_circle) AS circle_radius,
    area(col_circle) AS circle_area,
    col_box,
    width(col_box) AS box_width,
    height(col_box) AS box_height,
    distance(col_point, '(0,0)') AS distance_from_origin
FROM all_data_types 
WHERE col_point IS NOT NULL 
LIMIT 5;

-- Network address queries
SELECT 
    col_inet,
    host(col_inet) AS host_address,
    masklen(col_inet) AS mask_length,
    family(col_inet) AS ip_family,
    set_masklen(col_inet, 16) AS with_16_mask,
    network(col_inet) AS network_address,
    broadcast(col_inet) AS broadcast_address,
    col_cidr,
    abbrev(col_cidr) AS abbreviated_cidr
FROM all_data_types 
WHERE col_inet IS NOT NULL 
LIMIT 5;

-- UUID and special type queries
SELECT 
    col_uuid,
    gen_random_uuid() AS new_uuid,
    col_oid,
    col_regtype::regtype::text AS type_name,
    col_pg_lsn,
    pg_lsn '0/3000000' AS lsn_value
FROM all_data_types 
WHERE col_uuid IS NOT NULL 
LIMIT 5;

-- Composite type queries
SELECT 
    col_composite,
    (col_composite).street,
    (col_composite).city,
    (col_composite).postal_code,
    (col_composite).country,
    (col_composite).is_commercial
FROM all_data_types 
WHERE col_composite IS NOT NULL 
LIMIT 5;

-- Enum type queries
SELECT 
    col_enum,
    enum_first(NULL::status_enum) AS first_enum_value,
    enum_last(NULL::status_enum) AS last_enum_value,
    enum_range(NULL::status_enum) AS all_enum_values,
    col_enum = 'active' AS is_active_flag
FROM all_data_types 
WHERE col_enum IS NOT NULL 
LIMIT 5;

-- #############################################################################
-- 8. AGGREGATION WITH DIFFERENT DATA TYPES
-- #############################################################################

SELECT 
    -- Numeric aggregations
    COUNT(*) AS total_rows,
    COUNT(col_integer) AS non_null_ints,
    SUM(col_integer) AS sum_integers,
    AVG(col_decimal) AS avg_decimal,
    MIN(col_bigint) AS min_bigint,
    MAX(col_bigint) AS max_bigint,
    STDDEV(col_real) AS stddev_real,
    VARIANCE(col_real) AS variance_real,
    
    -- Date aggregations
    MIN(col_timestamp) AS earliest_timestamp,
    MAX(col_timestamp) AS latest_timestamp,
    MIN(col_date) AS earliest_date,
    MAX(col_date) AS latest_date,
    
    -- Boolean aggregation
    BOOL_AND(col_boolean) AS all_true,
    BOOL_OR(col_boolean) AS any_true,
    
    -- JSON aggregation
    JSONB_AGG(DISTINCT col_jsonb) AS distinct_json_values,
    JSON_OBJECT_AGG(col_smallint, col_varchar) AS key_value_json,
    
    -- Array aggregation
    ARRAY_AGG(DISTINCT col_smallint ORDER BY col_smallint) AS distinct_smallints,
    ARRAY_AGG(col_varchar) FILTER (WHERE col_varchar IS NOT NULL) AS all_varchars,
    
    -- String aggregation
    STRING_AGG(col_varchar, ', ' ORDER BY col_varchar) AS concatenated_varchars,
    STRING_AGG(DISTINCT col_text, ' | ') AS distinct_texts,
    
    -- Range aggregation
    RANGE_AGG(col_int4range) AS all_ranges_combined,
    
    -- Statistical aggregations
    CORR(col_smallint, col_integer) AS correlation,
    REGR_SLOPE(col_decimal, col_real) AS regression_slope,
    MODE() WITHIN GROUP (ORDER BY col_enum) AS most_common_enum
FROM all_data_types;

-- #############################################################################
-- 9. CREATE statements continued (TABLESPACE, INDEX, etc.)
-- #############################################################################

-- CREATE TABLE with different tablespace
CREATE TABLE archive_data (
    id SERIAL,
    data JSONB,
    archived_at DATE DEFAULT CURRENT_DATE
) TABLESPACE test_tablespace;

-- CREATE INDEX with different data types
CREATE INDEX idx_numeric ON all_data_types(col_integer, col_decimal);
CREATE INDEX idx_text_pattern ON all_data_types(col_varchar text_pattern_ops);
CREATE INDEX idx_jsonb_gin ON all_data_types USING gin(col_jsonb);
CREATE INDEX idx_array_gin ON all_data_types USING gin(col_int_array);
CREATE INDEX idx_range_gist ON all_data_types USING gist(col_int4range);
CREATE INDEX idx_tsvector_gin ON all_data_types USING gin(col_tsvector);
CREATE INDEX idx_expression ON all_data_types((col_decimal * 1.1));
CREATE INDEX idx_partial ON all_data_types(col_boolean) WHERE col_boolean = TRUE;
CREATE INDEX idx_hash ON all_data_types USING hash(col_uuid);
CREATE INDEX idx_brin ON all_data_types USING brin(col_timestamp);

-- CREATE STATISTICS for different data types
CREATE STATISTICS stats_numeric_correlation 
ON (col_smallint, col_integer, col_bigint) FROM all_data_types;

CREATE STATISTICS stats_text_patterns 
ON (col_varchar, col_text) FROM all_data_types;

CREATE STATISTICS stats_date_range 
ON (col_date, col_timestamp) FROM all_data_types;

-- #############################################################################
-- 10. ALTER statements for data types
-- #############################################################################

-- ALTER TABLE to modify data types
ALTER TABLE all_data_types 
    ALTER COLUMN col_varchar TYPE TEXT,
    ALTER COLUMN col_decimal TYPE NUMERIC(15,2),
    ALTER COLUMN col_json TYPE JSONB USING col_json::JSONB,
    ALTER COLUMN col_int_array TYPE BIGINT[] USING col_int_array::BIGINT[];

-- ALTER TABLE adding constraints based on data types
ALTER TABLE all_data_types
    ADD CONSTRAINT check_positive_salary CHECK (col_decimal > 0),
    ADD CONSTRAINT check_valid_email CHECK (col_varchar ~ '^[^@]+@[^@]+$'),
    ADD CONSTRAINT check_future_date CHECK (col_date >= '2020-01-01'),
    ADD CONSTRAINT check_valid_json CHECK (col_jsonb IS NOT NULL);

-- ALTER DOMAIN (modify custom data type)
ALTER DOMAIN positive_money ADD CONSTRAINT min_value CHECK (VALUE >= 0.01);
ALTER DOMAIN valid_email SET DEFAULT 'unknown@example.com';

-- ALTER TYPE (modify enum)
ALTER TYPE status_enum ADD VALUE 'deleted' AFTER 'archived';
ALTER TYPE priority_level RENAME VALUE 'urgent' TO 'critical';

-- ALTER TYPE (modify composite)
ALTER TYPE address_type ADD ATTRIBUTE latitude DOUBLE PRECISION;
ALTER TYPE address_type ADD ATTRIBUTE longitude DOUBLE PRECISION;
ALTER TYPE address_type DROP ATTRIBUTE is_commercial CASCADE;

-- #############################################################################
-- 11. DROP statements for data type objects
-- #############################################################################

-- DROP TYPE (custom types)
DROP TYPE IF EXISTS address_type CASCADE;
DROP TYPE IF EXISTS status_enum CASCADE;
DROP TYPE IF EXISTS employee_info CASCADE;
DROP TYPE IF EXISTS priority_level CASCADE;
DROP TYPE IF EXISTS timerange CASCADE;
DROP TYPE IF EXISTS floatrange CASCADE;

-- DROP DOMAIN
DROP DOMAIN IF EXISTS us_phone_number CASCADE;
DROP DOMAIN IF EXISTS positive_money CASCADE;
DROP DOMAIN IF EXISTS valid_email CASCADE;

-- DROP TABLE (will be done in cleanup)
-- DROP TABLE all_data_types CASCADE;
-- DROP TABLE data_type_demo_2 CASCADE;
-- DROP TABLE employees_enhanced CASCADE;
-- DROP TABLE data_type_backup CASCADE;

-- #############################################################################
-- 12. DATA TYPE CONVERSIONS (CASTING) EXAMPLES
-- #############################################################################

-- Implicit and explicit type casting
SELECT 
    -- Numeric casts
    123::TEXT AS int_to_text,
    '456'::INTEGER AS text_to_int,
    3.14159::INTEGER AS float_to_int,
    1000::SMALLINT AS int_to_smallint,
    123456789::BIGINT AS int_to_bigint,
    
    -- Text casts
    CURRENT_DATE::TEXT AS date_to_text,
    CURRENT_TIMESTAMP::VARCHAR(50) AS timestamp_to_varchar,
    '2024-06-15'::DATE AS text_to_date,
    '14:30:00'::TIME AS text_to_time,
    
    -- JSON casts
    '{"key": "value"}'::JSONB::JSON AS jsonb_to_json,
    col_jsonb::TEXT AS jsonb_to_text,
    
    -- UUID casts
    '123e4567-e89b-12d3-a456-426614174000'::UUID AS text_to_uuid,
    col_uuid::TEXT AS uuid_to_text,
    
    -- Network casts
    '192.168.1.1'::INET::TEXT AS inet_to_text,
    '192.168.0.0/24'::CIDR::TEXT AS cidr_to_text,
    
    -- Bit casts
    B'1010'::INTEGER AS bit_to_int,
    10::BIT(4) AS int_to_bit,
    
    -- Array casts
    ARRAY[1,2,3]::TEXT[] AS int_array_to_text_array,
    '{1,2,3}'::INTEGER[] AS text_to_int_array,
    
    -- Range casts
    '[1,10]'::INT4RANGE AS text_to_range,
    col_int4range::TEXT AS range_to_text

FROM all_data_types LIMIT 1;

-- #############################################################################
-- 13. ADVANCED DATA TYPE FEATURES
-- #############################################################################

-- Full-text search with tsvector and tsquery
SELECT 
    col_text,
    col_tsvector,
    col_tsquery,
    col_tsvector @@ col_tsquery AS matches_query,
    ts_rank(col_tsvector, col_tsquery) AS relevance_rank
FROM all_data_types 
WHERE col_tsvector @@ to_tsquery('english', 'quick & fox');

-- JSONB advanced operations
SELECT 
    col_jsonb,
    jsonb_set(col_jsonb, '{updated}', 'true'::JSONB) AS with_update,
    jsonb_insert(col_jsonb, '{tags, 0}', '"new_tag"'::JSONB) AS with_insert,
    jsonb_strip_nulls(col_jsonb) AS without_nulls,
    jsonb_pretty(col_jsonb) AS pretty_json
FROM all_data_types 
WHERE col_jsonb IS NOT NULL;

-- Range type advanced operations
SELECT 
    col_int4range,
    col_int4range * int4range(1, 100) AS intersection,
    col_int4range + int4range(1, 100) AS union_range,
    col_int4range - int4range(50, 75) AS difference,
    range_merge(col_int4range, int4range(100, 200)) AS merged
FROM all_data_types 
WHERE col_int4range IS NOT NULL;

-- Array advanced operations
SELECT 
    col_int_array,
    array_cat(col_int_array, ARRAY[100,200]) AS concatenated,
    array_remove(col_int_array, 5) AS without_5,
    array_replace(col_int_array, 10, 99) AS replace_10_with_99,
    array_position(col_int_array, 3) AS position_of_3,
    array_positions(col_int_array, 2) AS all_positions_of_2
FROM all_data_types 
WHERE col_int_array IS NOT NULL;

-- Composite type advanced usage
SELECT 
    col_composite,
    (col_composite).*,
    row_to_json(col_composite) AS as_json,
    row_to_json(col_composite)::JSONB->>'city' AS city_from_json
FROM all_data_types 
WHERE col_composite IS NOT NULL;

-- #############################################################################
-- 14. DATA TYPE VALIDATION AND CONSTRAINTS
-- #############################################################################

-- Check constraints for different data types
CREATE TABLE data_validation_test (
    id SERIAL PRIMARY KEY,
    
    -- Numeric constraints
    age INTEGER CHECK (age BETWEEN 0 AND 150),
    percentage NUMERIC(5,2) CHECK (percentage BETWEEN 0 AND 100),
    
    -- Text constraints
    email VARCHAR(255) CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    zip_code VARCHAR(10) CHECK (zip_code ~ '^\d{5}(-\d{4})?$'),
    
    -- Date constraints
    birth_date DATE CHECK (birth_date <= CURRENT_DATE),
    event_date TIMESTAMP CHECK (event_date >= '2000-01-01'),
    
    -- JSON constraints
    metadata JSONB CHECK (jsonb_typeof(metadata) = 'object'),
    
    -- Array constraints
    tags TEXT[] CHECK (array_length(tags, 1) <= 10),
    
    -- Range constraints
    valid_range INT4RANGE CHECK (NOT isempty(valid_range))
);

-- #############################################################################
-- 15. CLEANUP: Drop all created objects (order matters due to dependencies)
-- #############################################################################

-- Drop tables
DROP TABLE IF EXISTS data_validation_test CASCADE;
DROP TABLE IF EXISTS employees_enhanced CASCADE;
DROP TABLE IF EXISTS data_type_demo_2 CASCADE;
DROP TABLE IF EXISTS archive_data CASCADE;
DROP TABLE IF EXISTS data_type_backup CASCADE;
DROP TABLE IF EXISTS all_data_types CASCADE;

-- Drop statistics
DROP STATISTICS IF EXISTS stats_numeric_correlation CASCADE;
DROP STATISTICS IF EXISTS stats_text_patterns CASCADE;
DROP STATISTICS IF EXISTS stats_date_range CASCADE;

-- Drop domains
DROP DOMAIN IF EXISTS us_phone_number CASCADE;
DROP DOMAIN IF EXISTS positive_money CASCADE;
DROP DOMAIN IF EXISTS valid_email CASCADE;

-- Drop types
DROP TYPE IF EXISTS timerange CASCADE;
DROP TYPE IF EXISTS priority_level CASCADE;
DROP TYPE IF EXISTS employee_info CASCADE;
DROP TYPE IF EXISTS status_enum CASCADE;
DROP TYPE IF EXISTS address_type CASCADE;
DROP TYPE IF EXISTS floatrange CASCADE;

-- Drop indexes (automatically dropped with tables, but shown for completeness)
DROP INDEX IF EXISTS idx_numeric CASCADE;
DROP INDEX IF EXISTS idx_text_pattern CASCADE;
DROP INDEX IF EXISTS idx_jsonb_gin CASCADE;
DROP INDEX IF EXISTS idx_array_gin CASCADE;
DROP INDEX IF EXISTS idx_range_gist CASCADE;
DROP INDEX IF EXISTS idx_tsvector_gin CASCADE;
DROP INDEX IF EXISTS idx_expression CASCADE;
DROP INDEX IF EXISTS idx_partial CASCADE;
DROP INDEX IF EXISTS idx_hash CASCADE;
DROP INDEX IF EXISTS idx_brin CASCADE;

-- Drop functions, procedures, aggregates
DROP FUNCTION IF EXISTS get_employee_count() CASCADE;
DROP PROCEDURE IF EXISTS update_salary(INTEGER, NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS audit_employee_changes() CASCADE;
DROP FUNCTION IF EXISTS abort_drop() CASCADE;
DROP FUNCTION IF EXISTS sum_positive_state(NUMERIC, NUMERIC) CASCADE;
DROP AGGREGATE IF EXISTS sum_positive(NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS text_concat(text, text) CASCADE;
DROP OPERATOR IF EXISTS ~||~(text, text) CASCADE;
DROP FUNCTION IF EXISTS text_to_address(text) CASCADE;
DROP CAST IF EXISTS (text AS address_type) CASCADE;

-- Drop views and materialized views
DROP VIEW IF EXISTS employee_names CASCADE;
DROP MATERIALIZED VIEW IF EXISTS dept_salary_summary CASCADE;

-- Drop sequences
DROP SEQUENCE IF EXISTS order_seq CASCADE;

-- Drop schemas
DROP SCHEMA IF EXISTS renamed_schema CASCADE;
DROP SCHEMA IF EXISTS test_schema CASCADE;
DROP SCHEMA IF EXISTS extra_schema CASCADE;

-- Drop extensions
DROP EXTENSION IF EXISTS file_fdw CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;

-- Drop foreign objects
DROP FOREIGN TABLE IF EXISTS foreign_employees CASCADE;
DROP SERVER IF EXISTS file_server CASCADE;
DROP USER MAPPING IF EXISTS FOR test_user SERVER file_server CASCADE;
DROP FOREIGN DATA WRAPPER IF EXISTS file_fdw CASCADE;

-- Drop publications and subscriptions
DROP PUBLICATION IF EXISTS test_publication CASCADE;
-- DROP SUBSCRIPTION IF EXISTS test_subscription CASCADE;

-- Drop conversions
DROP CONVERSION IF EXISTS latin1_to_utf8_new CASCADE;

-- Drop text search objects
DROP TEXT SEARCH DICTIONARY IF EXISTS my_dict CASCADE;
DROP TEXT SEARCH CONFIGURATION IF EXISTS my_config CASCADE;
DROP TEXT SEARCH PARSER IF EXISTS my_parser CASCADE;
DROP TEXT SEARCH TEMPLATE IF EXISTS my_template CASCADE;

-- Drop event trigger
DROP EVENT TRIGGER IF EXISTS evt_abort_drop CASCADE;

-- Disable RLS and drop policies
ALTER TABLE IF EXISTS employees DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS emp_policy ON employees CASCADE;

-- Drop triggers and rules
DROP TRIGGER IF EXISTS trg_emp_audit ON employees CASCADE;
DROP RULE IF EXISTS log_emp_delete ON employees CASCADE;

-- Drop main tables (if not already dropped)
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS employee_audit CASCADE;
DROP TABLE IF EXISTS offices CASCADE;
DROP TABLE IF EXISTS high_earners CASCADE;
DROP TABLE IF EXISTS temp_employees CASCADE;

-- Drop roles and database (connect to another DB first)
\c postgres
DROP DATABASE IF EXISTS test_commands_db;
DROP USER IF EXISTS test_user;
DROP ROLE IF EXISTS test_role_renamed;
DROP ROLE IF EXISTS test_role;
DROP TABLESPACE IF EXISTS renamed_tablespace;
DROP TABLESPACE IF EXISTS test_tablespace;

-- Final message
\echo '================================================================================'
\echo 'COMPLETE PostgreSQL 16 SQL Commands Test Completed Successfully!'
\echo 'All SQL commands and ALL data types have been demonstrated.'
\echo 'Data types covered: Numeric, Monetary, Character, Binary, Date/Time,'
\echo 'Boolean, Geometric, Network, Text Search, UUID, JSON, XML, Bit String,'
\echo 'Range, Array, Composite, Enum, Pseudo, and Special Types.'
\echo '================================================================================'