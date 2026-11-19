-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Orders
-- Source: staging.orders_raw
-- Target: transform.orders_clean
-- Grain: One row per order
-- ============================================================

-- Rebuild only this derived table when rerunning the script.
DROP TABLE IF EXISTS transform.orders_clean;

CREATE TABLE transform.orders_clean AS

WITH source_data AS (
    SELECT
        NULLIF(BTRIM(order_id), '') AS order_id,
        NULLIF(BTRIM(customer_id), '') AS customer_id,

        LOWER(NULLIF(BTRIM(order_status), '')) AS order_status,

        NULLIF(BTRIM(order_purchase_timestamp), '')::TIMESTAMP
            AS purchase_timestamp,

        NULLIF(BTRIM(order_approved_at), '')::TIMESTAMP
            AS approved_timestamp,

        NULLIF(BTRIM(order_delivered_carrier_date), '')::TIMESTAMP
            AS carrier_timestamp,

        NULLIF(BTRIM(order_delivered_customer_date), '')::TIMESTAMP
            AS delivered_timestamp,

        NULLIF(BTRIM(order_estimated_delivery_date), '')::TIMESTAMP
            AS estimated_delivery_timestamp

    FROM staging.orders_raw
),

quality_checks AS (
    SELECT
        *,

        -- Missing timestamp indicators
        (approved_timestamp IS NULL)
            AS is_approval_timestamp_missing,

        (carrier_timestamp IS NULL)
            AS is_carrier_timestamp_missing,

        (delivered_timestamp IS NULL)
            AS is_delivery_timestamp_missing,

        (
            order_status = 'delivered'
            AND (
                approved_timestamp IS NULL
                OR carrier_timestamp IS NULL
                OR delivered_timestamp IS NULL
            )
        ) AS is_delivered_order_missing_timestamps,

        -- Invalid timestamp sequence indicators
        (
            approved_timestamp IS NOT NULL
            AND purchase_timestamp IS NOT NULL
            AND approved_timestamp < purchase_timestamp
        ) AS is_approval_before_purchase,

        (
            carrier_timestamp IS NOT NULL
            AND purchase_timestamp IS NOT NULL
            AND carrier_timestamp < purchase_timestamp
        ) AS is_carrier_before_purchase,

        (
            delivered_timestamp IS NOT NULL
            AND carrier_timestamp IS NOT NULL
            AND delivered_timestamp < carrier_timestamp
        ) AS is_delivery_before_carrier,

        (
            delivered_timestamp IS NOT NULL
            AND purchase_timestamp IS NOT NULL
            AND delivered_timestamp < purchase_timestamp
        ) AS is_delivery_before_purchase

    FROM source_data
)

SELECT
    order_id,
    customer_id,
    order_status,

    purchase_timestamp,
    approved_timestamp,
    carrier_timestamp,
    delivered_timestamp,
    estimated_delivery_timestamp,

    -- Order classification
    (order_status = 'delivered') AS is_delivered,

    
    -- Duration metrics
    CASE
        WHEN purchase_timestamp IS NOT NULL
         AND approved_timestamp IS NOT NULL
         AND approved_timestamp >= purchase_timestamp
        THEN ROUND(
            (EXTRACT(EPOCH FROM
                (approved_timestamp - purchase_timestamp)) / 3600)::NUMERIC,
            2
        )
    END AS approval_hours,

    CASE
        WHEN order_status = 'delivered'
         AND purchase_timestamp IS NOT NULL
         AND delivered_timestamp IS NOT NULL
         AND delivered_timestamp >= purchase_timestamp
        THEN ROUND(
            (EXTRACT(EPOCH FROM
                (delivered_timestamp - purchase_timestamp)) / 86400)::NUMERIC,
            2
        )
    END AS purchase_to_delivery_days,

    CASE
        WHEN order_status = 'delivered'
         AND purchase_timestamp IS NOT NULL
         AND delivered_timestamp IS NOT NULL
         AND estimated_delivery_timestamp IS NOT NULL
         AND delivered_timestamp >= purchase_timestamp
        THEN ROUND(
            (EXTRACT(EPOCH FROM
                (delivered_timestamp - estimated_delivery_timestamp)) / 86400)::NUMERIC,
            2
        )
    END AS delivery_delay_days,

    -- Delivery performance
    CASE
        WHEN order_status = 'delivered'
         AND purchase_timestamp IS NOT NULL
         AND delivered_timestamp IS NOT NULL
         AND estimated_delivery_timestamp IS NOT NULL
         AND delivered_timestamp >= purchase_timestamp
        THEN delivered_timestamp > estimated_delivery_timestamp
    END AS is_late_delivery,

    -- Missing timestamp flags
    is_approval_timestamp_missing,
    is_carrier_timestamp_missing,
    is_delivery_timestamp_missing,
    is_delivered_order_missing_timestamps,

    -- Invalid sequence flags
    is_approval_before_purchase,
    is_carrier_before_purchase,
    is_delivery_before_carrier,
    is_delivery_before_purchase,

    (
        is_approval_before_purchase
        OR is_carrier_before_purchase
        OR is_delivery_before_carrier
        OR is_delivery_before_purchase
    ) AS has_invalid_timestamp_sequence

FROM quality_checks;
