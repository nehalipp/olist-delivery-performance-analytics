-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Sellers
-- Source: staging.sellers_raw
-- Target: transform.sellers_clean
-- Grain: One row per seller
-- ============================================================

-- Rebuild only this derived table when rerunning the script.
DROP TABLE IF EXISTS transform.sellers_clean;

CREATE TABLE transform.sellers_clean AS
SELECT
    NULLIF(BTRIM(seller_id), '')
        AS seller_id,

    NULLIF(BTRIM(seller_zip_code_prefix), '')
        AS seller_zip_code_prefix,

    UPPER(NULLIF(BTRIM(seller_city), ''))
        AS seller_city,

    UPPER(NULLIF(BTRIM(seller_state), ''))
        AS seller_state,

    -- Data quality flags
    NULLIF(BTRIM(seller_id), '') IS NULL
        AS is_missing_seller_id,

    NULLIF(BTRIM(seller_zip_code_prefix), '') IS NULL
        AS is_missing_zip_code,

    NULLIF(BTRIM(seller_city), '') IS NULL
        AS is_missing_city,

    NULLIF(BTRIM(seller_state), '') IS NULL
        AS is_missing_state

FROM staging.sellers_raw;
