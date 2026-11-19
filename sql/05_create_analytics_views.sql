
-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Script: 05_create_analytics_views.sql
-- Purpose: Create reusable business reporting views.
-- Run after:
--   01.1 to 01.8_transform_data.sql
--   02_validate_dimensions.sql
--   03_validate_facts.sql
-- ============================================================


CREATE SCHEMA IF NOT EXISTS analytics;


-- ============================================================
-- 1. ORDER PERFORMANCE
-- Grain: One row per order
-- Purpose: Order status, customer, payment, review,
--          and purchase date analysis.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_order_performance AS

SELECT
    fo.order_key,
    fo.order_id,

    fo.customer_key,
    dc.customer_id,
    dc.customer_unique_id,
    dc.customer_city,
    dc.customer_state,

    fo.order_status,

    fo.purchase_date_key,
    dp.full_date AS purchase_date,

    fo.approval_date_key,
    da.full_date AS approval_date,

    fo.carrier_date_key,
    dca.full_date AS carrier_date,

    fo.delivery_date_key,
    dd.full_date AS delivery_date,

    fo.estimated_delivery_date_key,
    de.full_date AS estimated_delivery_date,

    fo.purchase_timestamp,
    fo.approved_timestamp,
    fo.carrier_timestamp,
    fo.delivered_timestamp,
    fo.estimated_delivery_timestamp,

    fo.approval_hours,
    fo.purchase_to_delivery_days,
    fo.delivery_delay_days,

    fo.is_delivered,
    fo.is_late_delivery,
    fo.is_delivered_order_missing_timestamps,
    fo.has_invalid_timestamp_sequence,

    fo.payment_total_value,
    fo.payment_record_count,
    fo.has_payment_record,

    fo.review_count,
    fo.average_review_score,
    fo.has_review

FROM warehouse.fact_orders fo

LEFT JOIN warehouse.dim_customer dc
    ON fo.customer_key = dc.customer_key

LEFT JOIN warehouse.dim_date dp
    ON fo.purchase_date_key = dp.date_key

LEFT JOIN warehouse.dim_date da
    ON fo.approval_date_key = da.date_key

LEFT JOIN warehouse.dim_date dca
    ON fo.carrier_date_key = dca.date_key

LEFT JOIN warehouse.dim_date dd
    ON fo.delivery_date_key = dd.date_key

LEFT JOIN warehouse.dim_date de
    ON fo.estimated_delivery_date_key = de.date_key;


-- ============================================================
-- 2. SALES PERFORMANCE
-- Grain: One row per order item
-- Purpose: Item sales, freight, product, seller,
--          customer, and order analysis.
--
-- Important:
-- Item sales and order payment totals are different
-- measures. Do not sum order payment totals at item grain.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_sales_performance AS

SELECT
    foi.order_item_key,
    foi.order_id,
    foi.order_item_id,

    fo.order_key,
    fo.order_status,

    fo.customer_key,
    dc.customer_id,
    dc.customer_unique_id,
    dc.customer_city AS customer_city,
    dc.customer_state AS customer_state,

    foi.product_key,
    dp.product_id,
    dp.product_category_name,
    dp.product_category_name_english,
    dp.category_status,

    foi.seller_key,
    ds.seller_id,
    ds.seller_city,
    ds.seller_state,

    fo.purchase_date_key,
    d.full_date AS purchase_date,

    foi.shipping_limit_date_key,
    foi.shipping_limit_timestamp,

    foi.price,
    foi.freight_value,
    foi.total_item_value,

    fo.is_delivered,
    fo.is_late_delivery,
    foi.is_shipping_limit_anomalous

FROM warehouse.fact_order_items foi

INNER JOIN warehouse.fact_orders fo
    ON foi.order_key = fo.order_key

LEFT JOIN warehouse.dim_customer dc
    ON fo.customer_key = dc.customer_key

LEFT JOIN warehouse.dim_product dp
    ON foi.product_key = dp.product_key

LEFT JOIN warehouse.dim_seller ds
    ON foi.seller_key = ds.seller_key

LEFT JOIN warehouse.dim_date d
    ON fo.purchase_date_key = d.date_key;


-- ============================================================
-- 3. CUSTOMER PERFORMANCE
-- Grain: One row per customer_key
-- Purpose: Customer order activity, payment value,
--          item sales, freight, and review analysis.
--
-- Order-level and item-level measures are aggregated
-- separately before joining to prevent fanout.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_customer_performance AS

WITH order_metrics AS (

    SELECT
        customer_key,

        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE is_late_delivery = TRUE
        ) AS late_delivered_orders,

        SUM(payment_total_value) AS total_payment_value,

        AVG(payment_total_value) AS average_order_payment,

        SUM(review_count) AS total_reviews,

        AVG(average_review_score) AS average_review_score

    FROM warehouse.fact_orders

    GROUP BY customer_key
),

item_metrics AS (

    SELECT
        fo.customer_key,

        COUNT(*) AS total_order_items,

        SUM(foi.price) AS total_item_sales,

        SUM(foi.freight_value) AS total_freight,

        SUM(foi.total_item_value) AS total_item_value,

        COUNT(DISTINCT fo.order_id) AS orders_with_items

    FROM warehouse.fact_order_items foi

    INNER JOIN warehouse.fact_orders fo
        ON foi.order_key = fo.order_key

    GROUP BY fo.customer_key
)

SELECT
    dc.customer_key,
    dc.customer_id,
    dc.customer_unique_id,

    dc.customer_zip_code_prefix,
    dc.customer_city,
    dc.customer_state,

    COALESCE(om.total_orders, 0) AS total_orders,
    COALESCE(om.delivered_orders, 0) AS delivered_orders,
    COALESCE(om.late_delivered_orders, 0)
        AS late_delivered_orders,

    om.total_payment_value,
    om.average_order_payment,

    COALESCE(im.total_order_items, 0) AS total_order_items,
    COALESCE(im.orders_with_items, 0) AS orders_with_items,

    COALESCE(im.total_item_sales, 0) AS total_item_sales,
    COALESCE(im.total_freight, 0) AS total_freight,
    COALESCE(im.total_item_value, 0) AS total_item_value,

    COALESCE(om.total_reviews, 0) AS total_reviews,
    om.average_review_score

FROM warehouse.dim_customer dc

LEFT JOIN order_metrics om
    ON dc.customer_key = om.customer_key

LEFT JOIN item_metrics im
    ON dc.customer_key = im.customer_key;


-- ============================================================
-- 4. PRODUCT PERFORMANCE
-- Grain: One row per product_key
-- Purpose: Product and category sales performance.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_product_performance AS

SELECT
    dp.product_key,
    dp.product_id,

    dp.product_category_name,
    dp.product_category_name_english,
    dp.category_status,

    dp.product_name_length,
    dp.product_description_length,
    dp.product_photos_qty,

    dp.product_weight_g,
    dp.product_length_cm,
    dp.product_height_cm,
    dp.product_width_cm,

    COUNT(foi.order_item_key) AS total_order_items,

    COUNT(DISTINCT foi.order_id) AS total_orders,

    COUNT(DISTINCT fo.customer_key) AS unique_customer_records,

    SUM(foi.price) AS total_item_sales,

    SUM(foi.freight_value) AS total_freight,

    SUM(foi.total_item_value) AS total_item_value,

    AVG(foi.price) AS average_item_price,

    AVG(foi.freight_value) AS average_freight

FROM warehouse.dim_product dp

LEFT JOIN warehouse.fact_order_items foi
    ON dp.product_key = foi.product_key

LEFT JOIN warehouse.fact_orders fo
    ON foi.order_key = fo.order_key

GROUP BY
    dp.product_key,
    dp.product_id,
    dp.product_category_name,
    dp.product_category_name_english,
    dp.category_status,
    dp.product_name_length,
    dp.product_description_length,
    dp.product_photos_qty,
    dp.product_weight_g,
    dp.product_length_cm,
    dp.product_height_cm,
    dp.product_width_cm;


-- ============================================================
-- 5. SELLER PERFORMANCE
-- Grain: One row per seller_key
-- Purpose: Seller sales, order volume, freight,
--          and delivery performance.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_seller_performance AS

SELECT
    ds.seller_key,
    ds.seller_id,
    ds.seller_zip_code_prefix,
    ds.seller_city,
    ds.seller_state,

    COUNT(foi.order_item_key) AS total_order_items,

    COUNT(DISTINCT foi.order_id) AS total_orders,

    COUNT(DISTINCT fo.customer_key) AS unique_customer_records,

    SUM(foi.price) AS total_item_sales,

    SUM(foi.freight_value) AS total_freight,

    SUM(foi.total_item_value) AS total_item_value,

    AVG(foi.price) AS average_item_price,

    COUNT(DISTINCT foi.order_id) FILTER (
        WHERE fo.is_delivered = TRUE
    ) AS delivered_orders,

    COUNT(DISTINCT foi.order_id) FILTER (
        WHERE fo.is_late_delivery = TRUE
    ) AS late_delivered_orders

FROM warehouse.dim_seller ds

LEFT JOIN warehouse.fact_order_items foi
    ON ds.seller_key = foi.seller_key

LEFT JOIN warehouse.fact_orders fo
    ON foi.order_key = fo.order_key

GROUP BY
    ds.seller_key,
    ds.seller_id,
    ds.seller_zip_code_prefix,
    ds.seller_city,
    ds.seller_state;


-- ============================================================
-- 6. DELIVERY PERFORMANCE
-- Grain: One row per order
-- Purpose: Delivery time, delay, on-time performance,
--          and timestamp quality analysis.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delivery_performance AS

SELECT
    fo.order_key,
    fo.order_id,
    fo.order_status,

    fo.customer_key,
    dc.customer_id,
    dc.customer_city,
    dc.customer_state,

    fo.purchase_date_key,
    dp.full_date AS purchase_date,

    fo.carrier_date_key,
    dcarr.full_date AS carrier_date,

    fo.delivery_date_key,
    dd.full_date AS delivery_date,

    fo.estimated_delivery_date_key,
    de.full_date AS estimated_delivery_date,

    fo.purchase_timestamp,
    fo.carrier_timestamp,
    fo.delivered_timestamp,
    fo.estimated_delivery_timestamp,

    fo.purchase_to_delivery_days,
    fo.delivery_delay_days,

    fo.is_delivered,
    fo.is_late_delivery,

    fo.is_delivered_order_missing_timestamps,
    fo.has_invalid_timestamp_sequence

FROM warehouse.fact_orders fo

LEFT JOIN warehouse.dim_customer dc
    ON fo.customer_key = dc.customer_key

LEFT JOIN warehouse.dim_date dp
    ON fo.purchase_date_key = dp.date_key

LEFT JOIN warehouse.dim_date dcarr
    ON fo.carrier_date_key = dcarr.date_key

LEFT JOIN warehouse.dim_date dd
    ON fo.delivery_date_key = dd.date_key

LEFT JOIN warehouse.dim_date de
    ON fo.estimated_delivery_date_key = de.date_key;