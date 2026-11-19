
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
-- 5. ORDER ITEMS CLEAN
-- Grain: One row per order item
-- Composite key: (order_id, order_item_id)
-- Expected rows: 112,650
-- ============================================================

-- 5.1 Row count and composite key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_order_item_keys,
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id)) AS duplicate_order_item_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM transform.order_items_clean;


-- 5.2 Missing required fields
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS missing_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id,
    COUNT(*) FILTER (WHERE shipping_limit_timestamp IS NULL) AS missing_shipping_limit,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS missing_freight_value
FROM transform.order_items_clean;


-- 5.3 Price and freight validation
SELECT
    COUNT(*) FILTER (WHERE price <= 0) AS nonpositive_price,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight,
    COUNT(*) FILTER (WHERE freight_value = 0) AS zero_freight
FROM transform.order_items_clean;


-- 5.4 Referential integrity: orders
SELECT
    COUNT(*) AS unmatched_order_references
FROM transform.order_items_clean oi
LEFT JOIN transform.orders_clean o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 5.5 Referential integrity: products
SELECT
    COUNT(*) AS unmatched_product_references
FROM transform.order_items_clean oi
LEFT JOIN transform.products_clean p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 5.6 Referential integrity: sellers
SELECT
    COUNT(*) AS unmatched_seller_references
FROM transform.order_items_clean oi
LEFT JOIN transform.sellers_clean s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- 5.7 Order-item financial summary
SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(price)::numeric, 2) AS total_item_price,
    ROUND(SUM(freight_value)::numeric, 2) AS total_freight_value,
    ROUND(AVG(price)::numeric, 2) AS average_item_price,
    ROUND(AVG(freight_value)::numeric, 2) AS average_freight_value
FROM transform.order_items_clean;


-- 5.8 Orders without order items
SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM transform.orders_clean o
LEFT JOIN transform.order_items_clean oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;


-- 5.9 Total orders without order items
SELECT
    COUNT(*) AS orders_without_items
FROM transform.orders_clean o
LEFT JOIN transform.order_items_clean oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;