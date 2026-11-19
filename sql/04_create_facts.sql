-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Script: 04_create_facts.sql
-- Purpose: Create and populate the warehouse facts.
-- Source: transform schema.
-- ============================================================

-- ============================================================
-- 1. Orders Fact
-- Grain: One row per order.
-- ============================================================
BEGIN;

CREATE TABLE IF NOT EXISTS warehouse.fact_orders (
    order_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Business identifiers
    order_id VARCHAR(50) NOT NULL UNIQUE,
    customer_key BIGINT NOT NULL,

    -- Role-playing date keys
    purchase_date_key INTEGER,
    approval_date_key INTEGER,
    carrier_date_key INTEGER,
    delivery_date_key INTEGER,
    estimated_delivery_date_key INTEGER,

    -- Order attributes
    order_status VARCHAR(30) NOT NULL,

    -- Original lifecycle timestamps
    purchase_timestamp TIMESTAMP,
    approved_timestamp TIMESTAMP,
    carrier_timestamp TIMESTAMP,
    delivered_timestamp TIMESTAMP,
    estimated_delivery_timestamp TIMESTAMP,

    -- Delivery measures
    approval_hours NUMERIC,
    purchase_to_delivery_days NUMERIC,
    delivery_delay_days NUMERIC,

    -- Delivery flags
    is_delivered BOOLEAN,
    is_late_delivery BOOLEAN,
    is_delivered_order_missing_timestamps BOOLEAN,
    has_invalid_timestamp_sequence BOOLEAN,

    -- Payment measures
    payment_total_value NUMERIC,
    payment_record_count INTEGER NOT NULL DEFAULT 0,
    has_payment_record BOOLEAN NOT NULL,

    -- Review measures
    review_count INTEGER NOT NULL DEFAULT 0,
    average_review_score NUMERIC,
    has_review BOOLEAN NOT NULL,

    -- Dimension relationships
    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_key)
        REFERENCES warehouse.dim_customer (customer_key),

    CONSTRAINT fk_fact_orders_purchase_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES warehouse.dim_date (date_key),

    CONSTRAINT fk_fact_orders_approval_date
        FOREIGN KEY (approval_date_key)
        REFERENCES warehouse.dim_date (date_key),

    CONSTRAINT fk_fact_orders_carrier_date
        FOREIGN KEY (carrier_date_key)
        REFERENCES warehouse.dim_date (date_key),

    CONSTRAINT fk_fact_orders_delivery_date
        FOREIGN KEY (delivery_date_key)
        REFERENCES warehouse.dim_date (date_key),

    CONSTRAINT fk_fact_orders_estimated_delivery_date
        FOREIGN KEY (estimated_delivery_date_key)
        REFERENCES warehouse.dim_date (date_key)
);

-- Clear existing rows when rerunning the load.
-- The identity sequence is reset so generated keys start consistently.
TRUNCATE TABLE warehouse.fact_orders RESTART IDENTITY;

WITH payment_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_total_value,
        COUNT(*) AS payment_record_count
    FROM transform.payments_clean
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

review_agg AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score)::NUMERIC AS average_review_score
    FROM transform.reviews_clean
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

INSERT INTO warehouse.fact_orders (
    order_id,
    customer_key,

    purchase_date_key,
    approval_date_key,
    carrier_date_key,
    delivery_date_key,
    estimated_delivery_date_key,

    order_status,

    purchase_timestamp,
    approved_timestamp,
    carrier_timestamp,
    delivered_timestamp,
    estimated_delivery_timestamp,

    approval_hours,
    purchase_to_delivery_days,
    delivery_delay_days,

    is_delivered,
    is_late_delivery,
    is_delivered_order_missing_timestamps,
    has_invalid_timestamp_sequence,

    payment_total_value,
    payment_record_count,
    has_payment_record,

    review_count,
    average_review_score,
    has_review
)

SELECT
    o.order_id,
    c.customer_key,

    dp.date_key AS purchase_date_key,
    da.date_key AS approval_date_key,
    dc.date_key AS carrier_date_key,
    dd.date_key AS delivery_date_key,
    de.date_key AS estimated_delivery_date_key,

    o.order_status,

    o.purchase_timestamp,
    o.approved_timestamp,
    o.carrier_timestamp,
    o.delivered_timestamp,
    o.estimated_delivery_timestamp,

    o.approval_hours,
    o.purchase_to_delivery_days,
    o.delivery_delay_days,

    o.is_delivered,
    o.is_late_delivery,
    o.is_delivered_order_missing_timestamps,
    o.has_invalid_timestamp_sequence,

    p.payment_total_value,
    COALESCE(p.payment_record_count, 0)::INTEGER,
    (p.order_id IS NOT NULL) AS has_payment_record,

    COALESCE(r.review_count, 0)::INTEGER,
    r.average_review_score,
    (r.order_id IS NOT NULL) AS has_review

FROM transform.orders_clean o

INNER JOIN warehouse.dim_customer c
    ON o.customer_id = c.customer_id

LEFT JOIN warehouse.dim_date dp
    ON o.purchase_timestamp::DATE = dp.full_date

LEFT JOIN warehouse.dim_date da
    ON o.approved_timestamp::DATE = da.full_date

LEFT JOIN warehouse.dim_date dc
    ON o.carrier_timestamp::DATE = dc.full_date

LEFT JOIN warehouse.dim_date dd
    ON o.delivered_timestamp::DATE = dd.full_date

LEFT JOIN warehouse.dim_date de
    ON o.estimated_delivery_timestamp::DATE = de.full_date

LEFT JOIN payment_agg p
    ON o.order_id = p.order_id

LEFT JOIN review_agg r
    ON o.order_id = r.order_id;

COMMIT;

-- ============================================================
-- 2. Orders Item Fact
-- Grain: One row per (order_id, order_item_id).
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS warehouse.fact_order_items (
    order_item_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Business identifiers
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,

    -- Warehouse foreign keys
    order_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    seller_key BIGINT NOT NULL,
    shipping_limit_date_key INTEGER,

    -- Original shipping deadline
    shipping_limit_timestamp TIMESTAMP,

    -- Financial measures
    price NUMERIC NOT NULL,
    freight_value NUMERIC NOT NULL,
    total_item_value NUMERIC NOT NULL,

    -- Data quality flags
    is_missing_shipping_limit_date BOOLEAN NOT NULL,
    is_invalid_order_item_id BOOLEAN NOT NULL,
    is_shipping_limit_anomalous BOOLEAN NOT NULL,

    CONSTRAINT uq_fact_order_items
        UNIQUE (order_id, order_item_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_key)
        REFERENCES warehouse.fact_orders (order_key),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_key)
        REFERENCES warehouse.dim_product (product_key),

    CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_key)
        REFERENCES warehouse.dim_seller (seller_key),

    CONSTRAINT fk_order_items_shipping_date
        FOREIGN KEY (shipping_limit_date_key)
        REFERENCES warehouse.dim_date (date_key)
);

TRUNCATE TABLE warehouse.fact_order_items RESTART IDENTITY;

INSERT INTO warehouse.fact_order_items (
    order_id,
    order_item_id,
    order_key,
    product_key,
    seller_key,
    shipping_limit_date_key,
    shipping_limit_timestamp,
    price,
    freight_value,
    total_item_value,
    is_missing_shipping_limit_date,
    is_invalid_order_item_id,
    is_shipping_limit_anomalous
)

SELECT
    oi.order_id,
    oi.order_item_id,
    fo.order_key,
    p.product_key,
    s.seller_key,
    d.date_key,
    oi.shipping_limit_timestamp,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value,

    oi.is_missing_shipping_limit_date,
    oi.is_invalid_order_item_id,

    -- Four previously identified 2020 shipping-limit anomalies
    COALESCE(
        oi.shipping_limit_timestamp >= TIMESTAMP '2020-01-01'
        AND oi.shipping_limit_timestamp < TIMESTAMP '2021-01-01',
        FALSE
    )

FROM transform.order_items_clean oi

INNER JOIN warehouse.fact_orders fo
    ON oi.order_id = fo.order_id

INNER JOIN warehouse.dim_product p
    ON oi.product_id = p.product_id

INNER JOIN warehouse.dim_seller s
    ON oi.seller_id = s.seller_id

LEFT JOIN warehouse.dim_date d
    ON oi.shipping_limit_timestamp::DATE = d.full_date;

COMMIT;