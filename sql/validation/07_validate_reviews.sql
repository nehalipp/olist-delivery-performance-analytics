
-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- MASTER TRANSFORMATION VALIDATION SCRIPT
-- ============================================================
-- Purpose:
--   Validate all eight cleaned tables in the transform schema.
--
-- Tables:
--   1. orders_clean
--   2. customers_clean
--   3. products_clean
--   4. sellers_clean
--   5. order_items_clean
--   6. payments_clean
--   7. reviews_clean
--   8. geolocation_clean
--
-- Notes:
--   - All queries are read-only.
--   - Source records and valid business exceptions are preserved.
--   - Review IDs and geolocation ZIP prefixes are not assumed unique.
--   - Order-level and item-level measures must not be joined
--     directly without first controlling their respective grains.
-- ============================================================


-- ============================================================
-- 7. REVIEWS CLEAN
-- Grain: One row per source review record
-- Do not assume review_id is unique.
-- Expected rows: 99,224
-- ============================================================

-- 7.1 Row count and review identifier summary
SELECT
    COUNT(*) AS total_review_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT review_id) AS excess_rows_vs_distinct_review_ids
FROM transform.reviews_clean;


-- 7.2 Repeated review IDs
SELECT
    review_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_comment_message) AS distinct_messages,
    COUNT(DISTINCT review_creation_timestamp) AS distinct_creation_dates
FROM transform.reviews_clean
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC, review_id;


-- 7.3 Missing and invalid review attributes
SELECT
    COUNT(*) FILTER (WHERE is_missing_review_id) AS missing_review_id,
    COUNT(*) FILTER (WHERE is_missing_order_id) AS missing_order_id,
    COUNT(*) FILTER (WHERE is_missing_review_score) AS missing_review_score,
    COUNT(*) FILTER (
        WHERE is_missing_review_creation_timestamp
    ) AS missing_review_creation_timestamp,
    COUNT(*) FILTER (
        WHERE is_missing_review_answer_timestamp
    ) AS missing_review_answer_timestamp,
    COUNT(*) FILTER (
        WHERE has_invalid_review_score
    ) AS invalid_review_score,
    COUNT(*) FILTER (
        WHERE has_invalid_review_timestamp_sequence
    ) AS invalid_review_timestamp_sequence
FROM transform.reviews_clean;


-- 7.4 Review score distribution
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM transform.reviews_clean
GROUP BY review_score
ORDER BY review_score;


-- 7.5 Positive and negative review summary
SELECT
    COUNT(*) FILTER (WHERE review_score IN (4, 5)) AS positive_reviews,
    COUNT(*) FILTER (WHERE review_score IN (1, 2)) AS negative_reviews,
    COUNT(*) FILTER (WHERE review_score = 3) AS neutral_reviews,
    ROUND(
        COUNT(*) FILTER (WHERE review_score IN (4, 5)) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_percentage,
    ROUND(
        COUNT(*) FILTER (WHERE review_score IN (1, 2)) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS negative_review_percentage
FROM transform.reviews_clean;


-- 7.6 Duplicate review_id and order_id combinations
SELECT
    review_id,
    order_id,
    COUNT(*) AS duplicate_count
FROM transform.reviews_clean
GROUP BY review_id, order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- 7.7 Referential integrity: orders
SELECT
    COUNT(*) AS unmatched_order_references
FROM transform.reviews_clean r
LEFT JOIN transform.orders_clean o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 7.8 Orders with multiple review records
SELECT
    order_id,
    COUNT(*) AS review_count,
    ROUND(AVG(review_score)::numeric, 2) AS average_review_score
FROM transform.reviews_clean
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC, order_id;


-- 7.9 Count of orders with multiple review records
SELECT
    COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT order_id
    FROM transform.reviews_clean
    GROUP BY order_id
    HAVING COUNT(*) > 1
) multiple_reviews;