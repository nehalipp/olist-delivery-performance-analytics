
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
-- 8. GEOLOCATION CLEAN
-- Grain: One row per source geolocation record
-- ZIP prefixes are not unique.
-- Expected rows: 1,000,163
-- ============================================================

-- 8.1 Row count and geographic coverage
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT zip_code_prefix) AS distinct_zip_prefixes,
    COUNT(DISTINCT city) AS distinct_cities,
    COUNT(DISTINCT state) AS distinct_states
FROM transform.geolocation_clean;


-- 8.2 Missing and invalid geographic attributes
SELECT
    COUNT(*) FILTER (
        WHERE is_missing_zip_code_prefix
    ) AS missing_zip_code_prefix,
    COUNT(*) FILTER (
        WHERE is_missing_latitude
    ) AS missing_latitude,
    COUNT(*) FILTER (
        WHERE is_missing_longitude
    ) AS missing_longitude,
    COUNT(*) FILTER (WHERE is_missing_city) AS missing_city,
    COUNT(*) FILTER (WHERE is_missing_state) AS missing_state,
    COUNT(*) FILTER (
        WHERE has_invalid_latitude_format
    ) AS invalid_latitude_format,
    COUNT(*) FILTER (
        WHERE has_invalid_longitude_format
    ) AS invalid_longitude_format,
    COUNT(*) FILTER (
        WHERE has_out_of_range_latitude
    ) AS out_of_range_latitude,
    COUNT(*) FILTER (
        WHERE has_out_of_range_longitude
    ) AS out_of_range_longitude
FROM transform.geolocation_clean;


-- 8.3 Coordinate range and coordinate availability
SELECT
    ROUND(MIN(latitude)::numeric, 8) AS minimum_latitude,
    ROUND(MAX(latitude)::numeric, 8) AS maximum_latitude,
    ROUND(MIN(longitude)::numeric, 8) AS minimum_longitude,
    ROUND(MAX(longitude)::numeric, 8) AS maximum_longitude,
    COUNT(*) FILTER (
        WHERE latitude IS NOT NULL
          AND longitude IS NOT NULL
    ) AS records_with_both_coordinates
FROM transform.geolocation_clean;


-- 8.4 ZIP prefix duplication
SELECT
    COUNT(*) AS total_zip_prefixes,
    COUNT(*) FILTER (WHERE record_count > 1) AS zip_prefixes_with_multiple_records,
    MAX(record_count) AS maximum_records_per_zip_prefix
FROM (
    SELECT
        zip_code_prefix,
        COUNT(*) AS record_count
    FROM transform.geolocation_clean
    GROUP BY zip_code_prefix
) zip_counts;


-- 8.5 ZIP prefixes with the most records
SELECT
    zip_code_prefix,
    COUNT(*) AS record_count
FROM transform.geolocation_clean
GROUP BY zip_code_prefix
ORDER BY record_count DESC
LIMIT 20;


-- 8.6 Geographic variation within ZIP prefixes
SELECT
    zip_code_prefix,
    COUNT(*) AS record_count,
    COUNT(DISTINCT city) AS distinct_cities,
    COUNT(DISTINCT state) AS distinct_states,
    COUNT(DISTINCT latitude) AS distinct_latitudes,
    COUNT(DISTINCT longitude) AS distinct_longitudes
FROM transform.geolocation_clean
GROUP BY zip_code_prefix
HAVING COUNT(DISTINCT city) > 1
    OR COUNT(DISTINCT state) > 1
    OR COUNT(DISTINCT latitude) > 1
    OR COUNT(DISTINCT longitude) > 1
ORDER BY record_count DESC
LIMIT 100;


-- 8.7 Exact duplicate geolocation groups
SELECT
    zip_code_prefix,
    latitude,
    longitude,
    city,
    state,
    COUNT(*) AS duplicate_count
FROM transform.geolocation_clean
GROUP BY
    zip_code_prefix,
    latitude,
    longitude,
    city,
    state
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 100;


-- 8.8 Total exact duplicate groups and excess rows
WITH duplicate_groups AS (
    SELECT
        COUNT(*) AS group_count,
        SUM(record_count - 1) AS excess_duplicate_rows
    FROM (
        SELECT
            zip_code_prefix,
            latitude,
            longitude,
            city,
            state,
            COUNT(*) AS record_count
        FROM transform.geolocation_clean
        GROUP BY
            zip_code_prefix,
            latitude,
            longitude,
            city,
            state
        HAVING COUNT(*) > 1
    ) duplicates
)
SELECT
    group_count AS exact_duplicate_groups,
    excess_duplicate_rows
FROM duplicate_groups;


-- 8.9 Geolocation distribution by state
SELECT
    state,
    COUNT(*) AS geolocation_records,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM transform.geolocation_clean
GROUP BY state
ORDER BY geolocation_records DESC;


-- 8.10 Approximate Brazil geographic bounds screening
-- These are screening bounds, not a definitive geographic validity test.
-- Longitude lower bound includes Fernando de Noronha.
SELECT
    COUNT(*) FILTER (
        WHERE latitude NOT BETWEEN -34 AND 6
    ) AS outside_latitude_bounds,
    COUNT(*) FILTER (
        WHERE longitude NOT BETWEEN -74 AND -32
    ) AS outside_longitude_bounds,
    COUNT(*) FILTER (
        WHERE latitude NOT BETWEEN -34 AND 6
           OR longitude NOT BETWEEN -74 AND -32
    ) AS outside_either_bound
FROM transform.geolocation_clean;


-- 8.11 Records outside approximate Brazil bounds
SELECT
    zip_code_prefix,
    latitude,
    longitude,
    city,
    state
FROM transform.geolocation_clean
WHERE latitude NOT BETWEEN -34 AND 6
   OR longitude NOT BETWEEN -74 AND -32
ORDER BY state, city;


-- 8.12 ZIP prefixes assigned to multiple states
SELECT
    zip_code_prefix,
    COUNT(DISTINCT state) AS distinct_states,
    STRING_AGG(
        state || ' (' || state_count || ')',
        ', ' ORDER BY state_count DESC
    ) AS state_distribution
FROM (
    SELECT
        zip_code_prefix,
        state,
        COUNT(*) AS state_count
    FROM transform.geolocation_clean
    GROUP BY zip_code_prefix, state
) zip_state_counts
GROUP BY zip_code_prefix
HAVING COUNT(DISTINCT state) > 1
ORDER BY distinct_states DESC, zip_code_prefix;