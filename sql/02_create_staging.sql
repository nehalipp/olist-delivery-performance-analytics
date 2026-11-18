
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Database: olist_analytics
-- Purpose: Create source-aligned staging tables.
--
-- Design decision:
-- All source columns are TEXT to preserve source representations
-- during ingestion. Type conversion and validation are handled
-- in the transformation layer.
--
-- This script creates missing tables only.
-- It does not truncate, reload, or modify existing staging data.

CREATE SCHEMA IF NOT EXISTS staging;


-- 1. Customers

CREATE TABLE IF NOT EXISTS staging.customers_raw (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);


-- 2. Geolocation

CREATE TABLE IF NOT EXISTS staging.geolocation_raw (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);


-- 3. Order Items

CREATE TABLE IF NOT EXISTS staging.order_items_raw (
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);


-- 4. Order Payments

CREATE TABLE IF NOT EXISTS staging.order_payments_raw (
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);


-- 5. Order Reviews

CREATE TABLE IF NOT EXISTS staging.order_reviews_raw (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);


-- 6. Orders

CREATE TABLE IF NOT EXISTS staging.orders_raw (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);


-- 7. Product Category Translation

CREATE TABLE IF NOT EXISTS staging.product_category_translation_raw (
    product_category_name TEXT,
    product_category_name_english TEXT
);


-- 8. Products

CREATE TABLE IF NOT EXISTS staging.products_raw (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);


-- 9. Sellers

CREATE TABLE IF NOT EXISTS staging.sellers_raw (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);


-- Verify staging tables.

SELECT
    table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'staging'
GROUP BY table_name
ORDER BY table_name;
