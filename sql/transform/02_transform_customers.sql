-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Customers
-- Source: staging.customers_raw
-- Target: transform.customers_clean
-- Grain: One row per customer
-- ============================================================

-- Rebuild only this derived table when rerunning the script.
DROP TABLE IF EXISTS transform.customers_clean;

CREATE TABLE transform.customers_clean AS
SELECT
    NULLIF(BTRIM(customer_id), '') AS customer_id,

    NULLIF(BTRIM(customer_unique_id), '') AS customer_unique_id,

    NULLIF(BTRIM(customer_zip_code_prefix), '')
        AS customer_zip_code_prefix,

    UPPER(NULLIF(BTRIM(customer_city), ''))
        AS customer_city,

    UPPER(NULLIF(BTRIM(customer_state), ''))
        AS customer_state,

    -- Data quality flags
    NULLIF(BTRIM(customer_id), '') IS NULL
        AS is_missing_customer_id,

    NULLIF(BTRIM(customer_unique_id), '') IS NULL
        AS is_missing_customer_unique_id,

    NULLIF(BTRIM(customer_zip_code_prefix), '') IS NULL
        AS is_missing_zip_code,

    NULLIF(BTRIM(customer_city), '') IS NULL
        AS is_missing_city,

    NULLIF(BTRIM(customer_state), '') IS NULL
        AS is_missing_state

FROM staging.customers_raw;
