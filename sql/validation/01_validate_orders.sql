
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
-- 1. ORDERS CLEAN
-- Grain: One row per order
-- Expected rows: 99,441
-- ============================================================

-- 1.1 Row count and order uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM transform.orders_clean;


-- 1.2 Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM transform.orders_clean
GROUP BY order_status
ORDER BY order_count DESC;


-- 1.3 Delivery status and late-delivery summary
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_delivered) AS delivered_orders,
    COUNT(*) FILTER (WHERE is_late_delivery) AS late_delivered_orders,
    COUNT(*) FILTER (
        WHERE is_delivered AND NOT is_late_delivery
    ) AS on_time_delivered_orders
FROM transform.orders_clean;


-- 1.4 Missing timestamp flags
SELECT
    COUNT(*) FILTER (
        WHERE is_approval_timestamp_missing
    ) AS missing_approval_timestamp,
    COUNT(*) FILTER (
        WHERE is_carrier_timestamp_missing
    ) AS missing_carrier_timestamp,
    COUNT(*) FILTER (
        WHERE is_delivery_timestamp_missing
    ) AS missing_delivery_timestamp,
    COUNT(*) FILTER (
        WHERE is_delivered_order_missing_timestamps
    ) AS delivered_orders_with_missing_timestamps
FROM transform.orders_clean;


-- 1.5 Invalid timestamp sequence checks
SELECT
    COUNT(*) FILTER (
        WHERE is_approval_before_purchase
    ) AS approval_before_purchase,
    COUNT(*) FILTER (
        WHERE is_carrier_before_purchase
    ) AS carrier_before_purchase,
    COUNT(*) FILTER (
        WHERE is_delivery_before_carrier
    ) AS delivery_before_carrier,
    COUNT(*) FILTER (
        WHERE is_delivery_before_purchase
    ) AS delivery_before_purchase,
    COUNT(*) FILTER (
        WHERE has_invalid_timestamp_sequence
    ) AS orders_with_invalid_timestamp_sequence
FROM transform.orders_clean;


-- 1.6 Carrier timestamp before purchase: breakdown
SELECT
    CASE
        WHEN purchase_timestamp - carrier_timestamp <= INTERVAL '1 hour'
            THEN 'Within 1 hour'
        WHEN purchase_timestamp - carrier_timestamp <= INTERVAL '24 hours'
            THEN '1 to 24 hours'
        WHEN purchase_timestamp - carrier_timestamp <= INTERVAL '7 days'
            THEN '1 to 7 days'
        ELSE 'More than 7 days'
    END AS time_difference_category,
    COUNT(*) AS order_count
FROM transform.orders_clean
WHERE is_carrier_before_purchase
GROUP BY 1
ORDER BY 2 DESC;


-- 1.7 Delivery timestamp before carrier timestamp
SELECT
    COUNT(*) AS affected_orders,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (carrier_timestamp - delivered_timestamp)) / 3600)::numeric,
        2
    ) AS average_difference_hours,
    ROUND(
        MIN(EXTRACT(EPOCH FROM (carrier_timestamp - delivered_timestamp)) / 3600)::numeric,
        2
    ) AS minimum_difference_hours,
    ROUND(
        MAX(EXTRACT(EPOCH FROM (carrier_timestamp - delivered_timestamp)) / 3600)::numeric,
        2
    ) AS maximum_difference_hours
FROM transform.orders_clean
WHERE is_delivery_before_carrier;


-- 1.8 Late delivery count
-- Only delivered orders with valid actual and estimated timestamps
SELECT
    COUNT(*) AS late_delivered_orders
FROM transform.orders_clean
WHERE is_delivered = TRUE
  AND delivered_timestamp IS NOT NULL
  AND estimated_delivery_timestamp IS NOT NULL
  AND delivered_timestamp > estimated_delivery_timestamp;