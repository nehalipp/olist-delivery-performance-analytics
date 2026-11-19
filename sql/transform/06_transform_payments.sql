-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Payments
-- Source: staging.order_payments_raw
-- Target: transform.payments_clean
-- Grain: One row per payment record, identified by (order_id, payment_sequential)
-- ============================================================

-- Rebuild only this derived table when rerunning the script.

DROP TABLE IF EXISTS p;

CREATE TABLE transform.payments_clean AS
SELECT
    NULLIF(BTRIM(order_id), '')
        AS order_id,

    NULLIF(BTRIM(payment_sequential), '')::INTEGER
        AS payment_sequential,

    LOWER(NULLIF(BTRIM(payment_type), ''))
        AS payment_type,

    NULLIF(BTRIM(payment_installments), '')::INTEGER
        AS payment_installments,

    NULLIF(BTRIM(payment_value), '')::NUMERIC(12,2)
        AS payment_value,

    -- Data quality flags
    NULLIF(BTRIM(order_id), '') IS NULL
        AS is_missing_order_id,

    NULLIF(BTRIM(payment_sequential), '') IS NULL
        AS is_missing_payment_sequential,

    NULLIF(BTRIM(payment_type), '') IS NULL
        AS is_missing_payment_type,

    NULLIF(BTRIM(payment_installments), '') IS NULL
        AS is_missing_payment_installments,

    NULLIF(BTRIM(payment_value), '') IS NULL
        AS is_missing_payment_value,

    COALESCE(
        NULLIF(BTRIM(payment_sequential), '')::INTEGER <= 0,
        FALSE
    ) AS is_invalid_payment_sequential,

    COALESCE(
        NULLIF(BTRIM(payment_installments), '')::INTEGER <= 0,
        FALSE
    ) AS is_invalid_payment_installments,

    COALESCE(
        NULLIF(BTRIM(payment_value), '')::NUMERIC(12,2) < 0,
        FALSE
    ) AS is_negative_payment_value

FROM staging.order_payments_raw;
