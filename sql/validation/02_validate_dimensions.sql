
-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Script: 02_validate_dimensions.sql
-- Purpose: Validate warehouse dimension tables.
-- Run after: 03_create_dimensions.sql
-- ============================================================


-- 1. Dimension row counts

SELECT 'dim_date' AS dimension_name, COUNT(*) AS row_count
FROM warehouse.dim_date

UNION ALL

SELECT 'dim_customer', COUNT(*)
FROM warehouse.dim_customer

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM warehouse.dim_product

UNION ALL

SELECT 'dim_seller', COUNT(*)
FROM warehouse.dim_seller

ORDER BY dimension_name;


-- 2. Business key uniqueness

SELECT
    'dim_customer' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_business_keys
FROM warehouse.dim_customer

UNION ALL

SELECT
    'dim_product',
    COUNT(*),
    COUNT(DISTINCT product_id)
FROM warehouse.dim_product

UNION ALL

SELECT
    'dim_seller',
    COUNT(*),
    COUNT(DISTINCT seller_id)
FROM warehouse.dim_seller;


-- 3. Date dimension coverage

SELECT
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date,
    COUNT(*) AS calendar_days,
    COUNT(DISTINCT full_date) AS distinct_dates
FROM warehouse.dim_date;


-- 4. Date continuity check
-- Expected result: zero missing calendar dates.

WITH date_sequence AS (
    SELECT
        full_date,
        LEAD(full_date) OVER (ORDER BY full_date) AS next_date
    FROM warehouse.dim_date
)
SELECT
    full_date,
    next_date
FROM date_sequence
WHERE next_date IS NOT NULL
  AND next_date <> full_date + 1;


-- 5. Product category distribution

SELECT
    product_category_name_english,
    COUNT(*) AS product_count
FROM warehouse.dim_product
GROUP BY product_category_name_english
ORDER BY product_count DESC;


-- 6. Unknown product category count

SELECT
    COUNT(*) AS unknown_category_products
FROM warehouse.dim_product
WHERE product_category_name_english = 'Unknown';


-- 7. Product category mapping diagnostics

SELECT
    CASE
        WHEN p.product_category_name IS NULL
          OR BTRIM(p.product_category_name) = ''
            THEN 'Missing source category'
        WHEN t.product_category_name IS NULL
            THEN 'No translation match'
        ELSE 'Translation available'
    END AS category_status,
    COUNT(*) AS product_count
FROM transform.products_clean p
LEFT JOIN staging.product_category_translation_raw t
    ON BTRIM(p.product_category_name) =
       BTRIM(t.product_category_name)
GROUP BY 1
ORDER BY 1;


-- 8. Check duplicate product category translations
-- Expected result: zero rows.

SELECT
    BTRIM(product_category_name) AS product_category_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT BTRIM(product_category_name_english))
        AS distinct_translations
FROM staging.product_category_translation_raw
GROUP BY BTRIM(product_category_name)
HAVING COUNT(*) > 1
ORDER BY row_count DESC;


-- 9. Source timestamp coverage

SELECT
    'purchase_timestamp' AS date_field,
    MIN(purchase_timestamp::DATE) AS min_date,
    MAX(purchase_timestamp::DATE) AS max_date,
    COUNT(*) FILTER (
        WHERE purchase_timestamp IS NOT NULL
    ) AS populated_rows
FROM transform.orders_clean

UNION ALL

SELECT
    'approved_timestamp',
    MIN(approved_timestamp::DATE),
    MAX(approved_timestamp::DATE),
    COUNT(*) FILTER (WHERE approved_timestamp IS NOT NULL)
FROM transform.orders_clean

UNION ALL

SELECT
    'carrier_timestamp',
    MIN(carrier_timestamp::DATE),
    MAX(carrier_timestamp::DATE),
    COUNT(*) FILTER (WHERE carrier_timestamp IS NOT NULL)
FROM transform.orders_clean

UNION ALL

SELECT
    'delivered_timestamp',
    MIN(delivered_timestamp::DATE),
    MAX(delivered_timestamp::DATE),
    COUNT(*) FILTER (WHERE delivered_timestamp IS NOT NULL)
FROM transform.orders_clean

UNION ALL

SELECT
    'estimated_delivery_timestamp',
    MIN(estimated_delivery_timestamp::DATE),
    MAX(estimated_delivery_timestamp::DATE),
    COUNT(*) FILTER (WHERE estimated_delivery_timestamp IS NOT NULL)
FROM transform.orders_clean

UNION ALL

SELECT
    'shipping_limit_timestamp',
    MIN(shipping_limit_timestamp::DATE),
    MAX(shipping_limit_timestamp::DATE),
    COUNT(*) FILTER (WHERE shipping_limit_timestamp IS NOT NULL)
FROM transform.order_items_clean

ORDER BY date_field;