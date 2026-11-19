
-- ============================================================
-- 07_transform_reviews.sql
-- Purpose: Clean and standardize Olist order review records
-- Source: staging.order_reviews_raw
-- Target: transform.reviews_clean
-- Grain: One row per source review record
-- ============================================================

DROP TABLE IF EXISTS transform.reviews_clean;

CREATE TABLE transform.reviews_clean AS
SELECT
    -- Identifiers
    NULLIF(BTRIM(review_id), '') AS review_id,
    NULLIF(BTRIM(order_id), '') AS order_id,

    -- Review attributes
    NULLIF(BTRIM(review_score), '')::INTEGER AS review_score,
    NULLIF(BTRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(BTRIM(review_comment_message), '') AS review_comment_message,

    -- Review timestamps
    NULLIF(BTRIM(review_creation_date), '')::TIMESTAMP
        AS review_creation_timestamp,

    NULLIF(BTRIM(review_answer_timestamp), '')::TIMESTAMP
        AS review_answer_timestamp,

    -- Missing-value flags
    NULLIF(BTRIM(review_id), '') IS NULL
        AS is_missing_review_id,

    NULLIF(BTRIM(order_id), '') IS NULL
        AS is_missing_order_id,

    NULLIF(BTRIM(review_score), '') IS NULL
        AS is_missing_review_score,

    NULLIF(BTRIM(review_creation_date), '') IS NULL
        AS is_missing_review_creation_timestamp,

    NULLIF(BTRIM(review_answer_timestamp), '') IS NULL
        AS is_missing_review_answer_timestamp,

    -- Review score validation
    CASE
        WHEN NULLIF(BTRIM(review_score), '') IS NULL THEN FALSE
        WHEN BTRIM(review_score) !~ '^[0-9]+$' THEN TRUE
        WHEN BTRIM(review_score)::INTEGER NOT BETWEEN 1 AND 5 THEN TRUE
        ELSE FALSE
    END AS has_invalid_review_score,

    -- Timestamp sequence validation
    CASE
        WHEN NULLIF(BTRIM(review_creation_date), '') IS NOT NULL
         AND NULLIF(BTRIM(review_answer_timestamp), '') IS NOT NULL
         AND BTRIM(review_answer_timestamp)::TIMESTAMP
             < BTRIM(review_creation_date)::TIMESTAMP
        THEN TRUE
        ELSE FALSE
    END AS has_invalid_review_timestamp_sequence

FROM staging.order_reviews_raw;
