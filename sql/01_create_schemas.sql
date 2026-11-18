
-- Project: Olist Delivery Performance & Revenue at Risk
-- Database: olist_analytics

CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE SCHEMA IF NOT EXISTS analytics;

-- Verify schemas
SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN (
    'staging',
    'warehouse',
    'analytics'
)
ORDER BY schema_name;
