
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
-- 3. PRODUCTS CLEAN
-- Grain: One row per product_id
-- Expected rows: 32,951
-- ============================================================

-- 3.1 Row count and product ID uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_product_rows
FROM transform.products_clean;


-- 3.2 Missing and zero-value attribute flags
SELECT
    COUNT(*) FILTER (WHERE is_missing_product_id) AS missing_product_id,
    COUNT(*) FILTER (WHERE is_missing_category) AS missing_category,
    COUNT(*) FILTER (WHERE is_missing_photo_count) AS missing_photo_count,
    COUNT(*) FILTER (WHERE is_missing_weight) AS missing_weight,
    COUNT(*) FILTER (WHERE is_zero_weight) AS zero_weight,
    COUNT(*) FILTER (
        WHERE has_nonpositive_dimension
    ) AS products_with_nonpositive_dimensions
FROM transform.products_clean;


-- 3.3 Check whether missing product attributes overlap
SELECT
    COUNT(*) FILTER (
        WHERE is_missing_category
    ) AS missing_category,
    COUNT(*) FILTER (
        WHERE is_missing_photo_count
    ) AS missing_photo_count,
    COUNT(*) FILTER (
        WHERE is_missing_weight
    ) AS missing_weight,
    COUNT(*) FILTER (
        WHERE product_name_length IS NULL
    ) AS missing_name_length,
    COUNT(*) FILTER (
        WHERE product_description_length IS NULL
    ) AS missing_description_length,
    COUNT(*) FILTER (
        WHERE is_missing_category
          AND is_missing_photo_count
          AND product_name_length IS NULL
          AND product_description_length IS NULL
    ) AS missing_all_four_attributes
FROM transform.products_clean;


-- 3.4 Products with missing attributes
SELECT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g
FROM transform.products_clean
WHERE is_missing_category
   OR is_missing_photo_count
   OR is_missing_weight
   OR product_name_length IS NULL
   OR product_description_length IS NULL
ORDER BY product_id;


-- 3.5 Negative or invalid numeric attributes
SELECT
    COUNT(*) FILTER (
        WHERE product_name_length < 0
    ) AS negative_name_length,
    COUNT(*) FILTER (
        WHERE product_description_length < 0
    ) AS negative_description_length,
    COUNT(*) FILTER (
        WHERE product_photos_qty < 0
    ) AS negative_photo_count,
    COUNT(*) FILTER (
        WHERE product_weight_g < 0
    ) AS negative_weight,
    COUNT(*) FILTER (
        WHERE product_length_cm <= 0
           OR product_height_cm <= 0
           OR product_width_cm <= 0
    ) AS nonpositive_dimensions
FROM transform.products_clean;


-- 3.6 Zero-weight products
SELECT
    product_id,
    product_category_name,
    product_weight_g
FROM transform.products_clean
WHERE is_zero_weight
ORDER BY product_id;


-- 3.7 Product category distribution
SELECT
    COALESCE(product_category_name, 'Unknown') AS product_category,
    COUNT(*) AS product_count
FROM transform.products_clean
GROUP BY COALESCE(product_category_name, 'Unknown')
ORDER BY product_count DESC;