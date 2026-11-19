
-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Script: 03_validate_facts.sql
-- Purpose: Validate warehouse fact tables, including grain,
--          financial reconciliation, dimension key integrity,
--          date mappings, and data-quality flags.
-- Run after: 04_create_facts.sql
-- ============================================================


-- ============================================================
-- FACT TABLE 1: fact_orders
-- Grain: One row per order_id
-- ============================================================


-- 1. Fact row count and order uniqueness

SELECT
    COUNT(*) AS total_fact_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM warehouse.fact_orders;


-- 2. Payment and review record reconciliation

SELECT
    SUM(payment_record_count) AS fact_payment_records,
    SUM(payment_total_value) AS fact_payment_total,
    COUNT(*) FILTER (
        WHERE has_payment_record = TRUE
    ) AS orders_with_payments,
    SUM(review_count) AS fact_review_records,
    COUNT(*) FILTER (
        WHERE has_review = TRUE
    ) AS orders_with_reviews
FROM warehouse.fact_orders;


-- 3. Foreign key completeness

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE customer_key IS NULL
    ) AS missing_customer_keys,

    COUNT(*) FILTER (
        WHERE purchase_date_key IS NULL
    ) AS missing_purchase_date_keys,

    COUNT(*) FILTER (
        WHERE approval_date_key IS NULL
    ) AS missing_approval_date_keys,

    COUNT(*) FILTER (
        WHERE carrier_date_key IS NULL
    ) AS missing_carrier_date_keys,

    COUNT(*) FILTER (
        WHERE delivery_date_key IS NULL
    ) AS missing_delivery_date_keys,

    COUNT(*) FILTER (
        WHERE estimated_delivery_date_key IS NULL
    ) AS missing_estimated_delivery_date_keys

FROM warehouse.fact_orders;


-- 4. Date key mapping validation

SELECT
    COUNT(*) FILTER (
        WHERE f.purchase_timestamp IS NOT NULL
          AND d_purchase.date_key IS NULL
    ) AS purchase_date_mapping_failures,

    COUNT(*) FILTER (
        WHERE f.approved_timestamp IS NOT NULL
          AND d_approval.date_key IS NULL
    ) AS approval_date_mapping_failures,

    COUNT(*) FILTER (
        WHERE f.carrier_timestamp IS NOT NULL
          AND d_carrier.date_key IS NULL
    ) AS carrier_date_mapping_failures,

    COUNT(*) FILTER (
        WHERE f.delivered_timestamp IS NOT NULL
          AND d_delivery.date_key IS NULL
    ) AS delivery_date_mapping_failures,

    COUNT(*) FILTER (
        WHERE f.estimated_delivery_timestamp IS NOT NULL
          AND d_estimated.date_key IS NULL
    ) AS estimated_delivery_date_mapping_failures

FROM warehouse.fact_orders f

LEFT JOIN warehouse.dim_date d_purchase
    ON f.purchase_date_key = d_purchase.date_key

LEFT JOIN warehouse.dim_date d_approval
    ON f.approval_date_key = d_approval.date_key

LEFT JOIN warehouse.dim_date d_carrier
    ON f.carrier_date_key = d_carrier.date_key

LEFT JOIN warehouse.dim_date d_delivery
    ON f.delivery_date_key = d_delivery.date_key

LEFT JOIN warehouse.dim_date d_estimated
    ON f.estimated_delivery_date_key = d_estimated.date_key;


-- 5. Payment and review financial reconciliation

SELECT
    'Payment total' AS validation_metric,
    (
        SELECT SUM(payment_value)
        FROM transform.payments_clean
    ) AS source_value,
    (
        SELECT SUM(payment_total_value)
        FROM warehouse.fact_orders
    ) AS fact_value

UNION ALL

SELECT
    'Review score total',
    (
        SELECT SUM(review_score)
        FROM transform.reviews_clean
    ),
    (
        SELECT SUM(average_review_score * review_count)
        FROM warehouse.fact_orders
    );


-- ============================================================
-- FACT TABLE 2: fact_order_items
-- Grain: One row per (order_id, order_item_id)
-- ============================================================


-- 6. Fact row count and order item uniqueness

SELECT
    COUNT(*) AS total_fact_rows,
    COUNT(DISTINCT (order_id, order_item_id))
        AS distinct_order_items,
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_order_items
FROM warehouse.fact_order_items;


-- 7. Item-level financial metrics

SELECT
    SUM(price) AS total_item_price,
    SUM(freight_value) AS total_freight,
    SUM(total_item_value) AS total_item_value,
    AVG(price) AS average_item_price,
    AVG(freight_value) AS average_freight
FROM warehouse.fact_order_items;


-- 8. Foreign key completeness

SELECT
    COUNT(*) AS total_items,

    COUNT(*) FILTER (
        WHERE order_key IS NULL
    ) AS missing_order_keys,

    COUNT(*) FILTER (
        WHERE product_key IS NULL
    ) AS missing_product_keys,

    COUNT(*) FILTER (
        WHERE seller_key IS NULL
    ) AS missing_seller_keys

FROM warehouse.fact_order_items;


-- 9. Shipping date mapping validation

SELECT
    COUNT(*) FILTER (
        WHERE f.shipping_limit_timestamp IS NOT NULL
          AND d.date_key IS NULL
    ) AS shipping_date_mapping_failures

FROM warehouse.fact_order_items f

LEFT JOIN warehouse.dim_date d
    ON f.shipping_limit_date_key = d.date_key
   AND f.shipping_limit_timestamp::DATE = d.full_date;


-- 10. Shipping timestamp anomaly distribution

SELECT
    is_shipping_limit_anomalous,
    COUNT(*) AS order_item_count,
    COUNT(DISTINCT order_id) AS affected_orders,
    MIN(shipping_limit_timestamp) AS first_date,
    MAX(shipping_limit_timestamp) AS last_date

FROM warehouse.fact_order_items

GROUP BY is_shipping_limit_anomalous

ORDER BY is_shipping_limit_anomalous;


-- 11. Source-to-fact financial reconciliation

SELECT
    'Source' AS dataset,
    COUNT(*) AS total_rows,
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight

FROM transform.order_items_clean

UNION ALL

SELECT
    'Fact',
    COUNT(*),
    SUM(price),
    SUM(freight_value)

FROM warehouse.fact_order_items;