
-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- MASTER TRANSFORMATION VALIDATION SCRIPT
-- ============================================================
-- Purpose:
--   Validate all eight cleaned tables in the transform schema.
--
-- Tables:
--   1. orders_clean
--   2. customers_clean
--   3. products_clean
--   4. sellers_clean
--   5. order_items_clean
--   6. payments_clean
--   7. reviews_clean
--   8. geolocation_clean
--
-- Notes:
--   - All queries are read-only.
--   - Source records and valid business exceptions are preserved.
--   - Review IDs and geolocation ZIP prefixes are not assumed unique.
--   - Order-level and item-level measures must not be joined
--     directly without first controlling their respective grains.
-- ============================================================


-- ============================================================
-- 2. CUSTOMERS CLEAN
-- Grain: One row per customer_id
-- Expected rows: 99,441
-- ============================================================

-- 2.1 Row count and customer ID uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_rows
FROM transform.customers_clean;


-- 2.2 Missing customer attributes
SELECT
    COUNT(*) FILTER (WHERE is_missing_customer_id) AS missing_customer_id,
    COUNT(*) FILTER (
        WHERE is_missing_customer_unique_id
    ) AS missing_customer_unique_id,
    COUNT(*) FILTER (WHERE is_missing_zip_code) AS missing_zip_code,
    COUNT(*) FILTER (WHERE is_missing_city) AS missing_city,
    COUNT(*) FILTER (WHERE is_missing_state) AS missing_state
FROM transform.customers_clean;


-- 2.3 Repeat-customer identity analysis
SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_unique_id) AS additional_customer_records
FROM transform.customers_clean;


-- 2.4 Customer records associated with multiple customer IDs
SELECT
    customer_unique_id,
    COUNT(DISTINCT customer_id) AS customer_id_count
FROM transform.customers_clean
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY customer_id_count DESC;


-- 2.5 Customer ZIP code length validation
SELECT
    customer_zip_code_prefix,
    LENGTH(customer_zip_code_prefix) AS zip_code_length,
    COUNT(*) AS record_count
FROM transform.customers_clean
WHERE LENGTH(customer_zip_code_prefix) <> 5
GROUP BY customer_zip_code_prefix
ORDER BY record_count DESC;


-- 2.6 Customer distribution by state
SELECT
    customer_state,
    COUNT(*) AS customer_records
FROM transform.customers_clean
GROUP BY customer_state
ORDER BY customer_records DESC;