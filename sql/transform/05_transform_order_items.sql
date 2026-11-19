
-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Order Items
-- Source: staging.order_items_raw
-- Target: transform.order_items_clean
-- Grain: One row per order item, uniquely identified by (order_id, order_item_id).
-- ============================================================

-- Rebuild only this derived table when rerunning the script.
DROP TABLE IF EXISTS transform.order_items_clean;

CREATE TABLE transform.order_items_clean AS
SELECT
    NULLIF(BTRIM(order_id), '')
        AS order_id,

    NULLIF(BTRIM(order_item_id), '')::INTEGER
        AS order_item_id,

    NULLIF(BTRIM(product_id), '')
        AS product_id,

    NULLIF(BTRIM(seller_id), '')
        AS seller_id,

    NULLIF(BTRIM(shipping_limit_date), '')::TIMESTAMP
        AS shipping_limit_timestamp,

    NULLIF(BTRIM(price), '')::NUMERIC(12,2)
        AS price,

    NULLIF(BTRIM(freight_value), '')::NUMERIC(12,2)
        AS freight_value,

    -- Data quality flags
    NULLIF(BTRIM(order_id), '') IS NULL
        AS is_missing_order_id,

    NULLIF(BTRIM(order_item_id), '') IS NULL
        AS is_missing_order_item_id,

    NULLIF(BTRIM(product_id), '') IS NULL
        AS is_missing_product_id,

    NULLIF(BTRIM(seller_id), '') IS NULL
        AS is_missing_seller_id,

    NULLIF(BTRIM(shipping_limit_date), '') IS NULL
        AS is_missing_shipping_limit_date,

    COALESCE(
        NULLIF(BTRIM(order_item_id), '')::INTEGER <= 0,
        FALSE
    ) AS is_invalid_order_item_id,

    COALESCE(
        NULLIF(BTRIM(price), '')::NUMERIC(12,2) <= 0,
        FALSE
    ) AS is_nonpositive_price,

    COALESCE(
        NULLIF(BTRIM(freight_value), '')::NUMERIC(12,2) < 0,
        FALSE
    ) AS is_negative_freight

FROM staging.order_items_raw;
