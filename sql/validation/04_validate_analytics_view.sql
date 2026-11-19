
-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Script: 04_validate_analytics_views.sql
-- Purpose: Validate analytics views, including grain,
--          financial reconciliation, dimension key integrity,
--          date mappings, and data-quality flags.
-- Run after: 05_create_analytics_views.sql
-- ============================================================


-- 1. Order performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM analytics.vw_order_performance;


-- 2. Sales performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id))
        AS distinct_order_items,
    SUM(price) AS total_item_sales,
    SUM(freight_value) AS total_freight,
    SUM(total_item_value) AS total_item_value
FROM analytics.vw_sales_performance;


-- 3. Customer performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_key) AS distinct_customers,
    SUM(total_orders) AS total_orders,
    SUM(total_payment_value) AS total_payment_value,
    SUM(total_item_sales) AS total_item_sales
FROM analytics.vw_customer_performance;


-- 4. Product performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_key) AS distinct_products,
    SUM(total_order_items) AS total_order_items,
    SUM(total_item_sales) AS total_item_sales
FROM analytics.vw_product_performance;


-- 5. Seller performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_key) AS distinct_sellers,
    SUM(total_order_items) AS total_order_items,
    SUM(total_item_sales) AS total_item_sales
FROM analytics.vw_seller_performance;


-- 6. Delivery performance

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) FILTER (
        WHERE is_delivered = TRUE
    ) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE is_late_delivery = TRUE
    ) AS late_delivered_orders
FROM analytics.vw_delivery_performance;
