
-- ============================================================
-- 08_transform_geolocation.sql
-- Purpose: Clean and standardize Olist geolocation records
-- Source: staging.geolocation_raw
-- Target: transform.geolocation_clean
-- Grain: One row per source geolocation record
-- ============================================================

DROP TABLE IF EXISTS transform.geolocation_clean;

CREATE TABLE transform.geolocation_clean AS
SELECT
    -- ZIP prefix
    NULLIF(BTRIM(geolocation_zip_code_prefix), '')
        AS zip_code_prefix,

    -- Coordinates
    CASE
        WHEN BTRIM(geolocation_lat)
             ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
        THEN BTRIM(geolocation_lat)::NUMERIC(12,8)
        ELSE NULL
    END AS latitude,

    CASE
        WHEN BTRIM(geolocation_lng)
             ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
        THEN BTRIM(geolocation_lng)::NUMERIC(12,8)
        ELSE NULL
    END AS longitude,

    -- Location attributes
    UPPER(NULLIF(BTRIM(geolocation_city), ''))
        AS city,

    UPPER(NULLIF(BTRIM(geolocation_state), ''))
        AS state,

    -- Missing-value flags
    NULLIF(BTRIM(geolocation_zip_code_prefix), '') IS NULL
        AS is_missing_zip_code_prefix,

    NULLIF(BTRIM(geolocation_lat), '') IS NULL
        AS is_missing_latitude,

    NULLIF(BTRIM(geolocation_lng), '') IS NULL
        AS is_missing_longitude,

    NULLIF(BTRIM(geolocation_city), '') IS NULL
        AS is_missing_city,

    NULLIF(BTRIM(geolocation_state), '') IS NULL
        AS is_missing_state,

    -- Coordinate format validation
    CASE
        WHEN NULLIF(BTRIM(geolocation_lat), '') IS NOT NULL
         AND BTRIM(geolocation_lat)
             !~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
        THEN TRUE
        ELSE FALSE
    END AS has_invalid_latitude_format,

    CASE
        WHEN NULLIF(BTRIM(geolocation_lng), '') IS NOT NULL
         AND BTRIM(geolocation_lng)
             !~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
        THEN TRUE
        ELSE FALSE
    END AS has_invalid_longitude_format,

    -- Coordinate range validation
    CASE
        WHEN BTRIM(geolocation_lat)
             ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
         AND BTRIM(geolocation_lat)::NUMERIC NOT BETWEEN -90 AND 90
        THEN TRUE
        ELSE FALSE
    END AS has_out_of_range_latitude,

    CASE
        WHEN BTRIM(geolocation_lng)
             ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
         AND BTRIM(geolocation_lng)::NUMERIC NOT BETWEEN -180 AND 180
        THEN TRUE
        ELSE FALSE
    END AS has_out_of_range_longitude

FROM staging.geolocation_raw;
