
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
-- 6. PAYMENTS CLEAN
-- Grain: One row per payment record
-- Composite key: (order_id, payment_sequential)
-- Expected rows: 103,886
-- ============================================================

-- 6.1 Row count and composite key uniqueness
SELECT
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT (order_id, payment_sequential)) AS distinct_payment_keys,
    COUNT(*) - COUNT(DISTINCT (order_id, payment_sequential)) AS duplicate_payment_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM transform.payments_clean;


-- 6.2 Missing payment attributes
SELECT
    COUNT(*) FILTER (WHERE is_missing_order_id) AS missing_order_id,
    COUNT(*) FILTER (
        WHERE is_missing_payment_sequential
    ) AS missing_payment_sequential,
    COUNT(*) FILTER (WHERE is_missing_payment_type) AS missing_payment_type,
    COUNT(*) FILTER (
        WHERE is_missing_payment_installments
    ) AS missing_payment_installments,
    COUNT(*) FILTER (WHERE is_missing_payment_value) AS missing_payment_value
FROM transform.payments_clean;


-- 6.3 Invalid payment values and flags
SELECT
    COUNT(*) FILTER (
        WHERE is_invalid_payment_sequential
    ) AS invalid_payment_sequential,
    COUNT(*) FILTER (
        WHERE is_invalid_payment_installments
    ) AS invalid_payment_installments,
    COUNT(*) FILTER (
        WHERE is_negative_payment_value
    ) AS negative_payment_value,
    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payment_value
FROM transform.payments_clean;


-- 6.4 Payment type distribution
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(payment_value)::numeric, 2) AS average_payment_value
FROM transform.payments_clean
GROUP BY payment_type
ORDER BY payment_records DESC;


-- 6.5 Referential integrity: orders
SELECT
    COUNT(*) AS unmatched_order_references
FROM transform.payments_clean p
LEFT JOIN transform.orders_clean o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6.6 Orders with multiple payment records
SELECT
    order_id,
    COUNT(*) AS payment_record_count,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value
FROM transform.payments_clean
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_record_count DESC, order_id;


-- 6.7 Count of orders with multiple payment records
SELECT
    COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT order_id
    FROM transform.payments_clean
    GROUP BY order_id
    HAVING COUNT(*) > 1
) multiple_payments;


-- 6.8 Overall payment financial summary
SELECT
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(payment_value)::numeric, 2) AS average_payment_value,
    ROUND(MIN(payment_value)::numeric, 2) AS minimum_payment_value,
    ROUND(MAX(payment_value)::numeric, 2) AS maximum_payment_value
FROM transform.payments_clean;


-- 6.9 Zero-value payment records
SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status
FROM transform.payments_clean p
LEFT JOIN transform.orders_clean o
    ON p.order_id = o.order_id
WHERE p.payment_value = 0
ORDER BY p.order_id, p.payment_sequential;


-- 6.10 Orders without payment records
SELECT
    o.order_id,
    o.order_status
FROM transform.orders_clean o
LEFT JOIN transform.payments_clean p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL
ORDER BY o.order_id;