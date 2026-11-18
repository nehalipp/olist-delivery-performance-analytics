
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Database: olist_analytics
-- Purpose: Create the logical database schemas.

CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS transform;

CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE SCHEMA IF NOT EXISTS analytics;


-- Verify project schemas.

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN (
    'staging',
    'transform',
    'warehouse',
    'analytics'
)
ORDER BY schema_name;
