
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
-- 4. SELLERS CLEAN
-- Grain: One row per seller_id
-- Expected rows: 3,095
-- ============================================================

-- 4.1 Row count and seller ID uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    COUNT(*) - COUNT(DISTINCT seller_id) AS duplicate_seller_rows
FROM transform.sellers_clean;


-- 4.2 Missing and nonstandard seller attributes
SELECT
    COUNT(*) FILTER (WHERE is_missing_seller_id) AS missing_seller_id,
    COUNT(*) FILTER (WHERE is_missing_zip_code) AS missing_zip_code,
    COUNT(*) FILTER (WHERE is_missing_city) AS missing_city,
    COUNT(*) FILTER (WHERE is_missing_state) AS missing_state,
    COUNT(*) FILTER (WHERE has_nonstandard_city) AS nonstandard_city,
    COUNT(*) FILTER (WHERE has_nonstandard_state) AS nonstandard_state
FROM transform.sellers_clean;


-- 4.3 Seller ZIP code length validation
SELECT
    seller_zip_code_prefix,
    LENGTH(seller_zip_code_prefix) AS zip_code_length,
    COUNT(*) AS record_count
FROM transform.sellers_clean
WHERE LENGTH(seller_zip_code_prefix) <> 5
GROUP BY seller_zip_code_prefix
ORDER BY record_count DESC;


-- 4.4 Seller distribution by state
SELECT
    seller_state,
    COUNT(*) AS seller_count
FROM transform.sellers_clean
GROUP BY seller_state
ORDER BY seller_count DESC;


-- 4.5 Seller distribution by city
SELECT
    seller_state,
    seller_city,
    COUNT(*) AS seller_count
FROM transform.sellers_clean
GROUP BY seller_state, seller_city
ORDER BY seller_count DESC;