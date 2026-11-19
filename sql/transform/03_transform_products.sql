-- ============================================================
-- Project: Olist E-Commerce Delivery Performance & Analytics
-- Transformation: Clean Products
-- Source: staging.products_raw
-- Target: transform.products_clean
-- Grain: One row per product
-- ============================================================

-- Rebuild only this derived table when rerunning the script.
DROP TABLE IF EXISTS transform.products_clean;

CREATE TABLE transform.products_clean AS
SELECT
    NULLIF(BTRIM(product_id), '') AS product_id,

    NULLIF(BTRIM(product_category_name), '')
        AS product_category_name,

    NULLIF(BTRIM(product_name_lenght), '')::INTEGER
        AS product_name_length,

    NULLIF(BTRIM(product_description_lenght), '')::INTEGER
        AS product_description_length,

    NULLIF(BTRIM(product_photos_qty), '')::INTEGER
        AS product_photos_qty,

    NULLIF(BTRIM(product_weight_g), '')::INTEGER
        AS product_weight_g,

    NULLIF(BTRIM(product_length_cm), '')::INTEGER
        AS product_length_cm,

    NULLIF(BTRIM(product_height_cm), '')::INTEGER
        AS product_height_cm,

    NULLIF(BTRIM(product_width_cm), '')::INTEGER
        AS product_width_cm,

    -- Data quality flags
    NULLIF(BTRIM(product_id), '') IS NULL
        AS is_missing_product_id,

    NULLIF(BTRIM(product_category_name), '') IS NULL
        AS is_missing_category,

    NULLIF(BTRIM(product_photos_qty), '') IS NULL
        AS is_missing_photo_count,

    NULLIF(BTRIM(product_weight_g), '') IS NULL
        AS is_missing_weight,

    COALESCE(
        NULLIF(BTRIM(product_weight_g), '')::INTEGER = 0,
        FALSE
    ) AS is_zero_weight,

    COALESCE(
        (
            NULLIF(BTRIM(product_length_cm), '')::INTEGER <= 0
            OR NULLIF(BTRIM(product_height_cm), '')::INTEGER <= 0
            OR NULLIF(BTRIM(product_width_cm), '')::INTEGER <= 0
        ),
        FALSE
    ) AS has_nonpositive_dimension
