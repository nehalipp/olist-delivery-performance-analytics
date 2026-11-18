
# Data Quality Assessment

## 1. Purpose

This document records the source-data profiling and validation performed before transformation.

The assessment covers data completeness, uniqueness, referential integrity, numeric validity, timestamp consistency, and potential duplicate patterns.

The original source data and imported staging tables are preserved. Data-quality handling will be implemented in the transformation layer.

## 2. Import and Row-Count Validation

All nine source datasets were successfully imported into PostgreSQL staging tables.

Actual row counts matched the expected source counts.

| Dataset | Records |
|---|---:|
| Customers | 99,441 |
| Geolocation | 1,000,163 |
| Order Items | 112,650 |
| Order Payments | 103,886 |
| Order Reviews | 99,224 |
| Orders | 99,441 |
| Product Category Translation | 71 |
| Products | 32,951 |
| Sellers | 3,095 |
| **Total** | **1,650,922** |

## 3. Key and Relationship Validation

The following validation checks returned no violations:

| Validation | Result |
|---|---:|
| Duplicate order IDs | 0 |
| Duplicate customer IDs | 0 |
| Duplicate product IDs | 0 |
| Duplicate seller IDs | 0 |
| Duplicate order-item composite keys | 0 |
| Missing tested primary-key candidate values | 0 |
| Order items referencing unknown orders | 0 |
| Order items referencing unknown products | 0 |
| Order items referencing unknown sellers | 0 |
| Orders referencing unknown customers | 0 |
| Payments referencing unknown orders | 0 |
| Reviews referencing unknown orders | 0 |
| Duplicate category translation keys | 0 |

These findings apply to the validation checks performed.

### Identifier Considerations

- `customer_id` identifies the customer record associated with an order.
- `customer_unique_id` identifies a customer across potentially multiple customer records and orders.
- `customer_unique_id` should not be assumed unique in the customer source table.
- Geolocation ZIP prefixes are not unique.
- `review_id` is not unique across all review records.

## 4. Missing-Value Assessment

### 4.1 Order Timestamps

| Field | Missing Records |
|---|---:|
| `order_approved_at` | 160 |
| `order_delivered_carrier_date` | 1,783 |
| `order_delivered_customer_date` | 2,965 |

Missing timestamps were investigated by order status.

Missing delivery timestamps on orders that were not delivered are generally consistent with incomplete or non-delivered order lifecycles.

However, delivered orders with missing lifecycle timestamps are exceptions.

Among delivered orders:

- 14 orders have missing approval timestamps.
- 2 orders have missing carrier timestamps.
- 8 orders have missing customer-delivery timestamps.

One order is missing both carrier and customer-delivery timestamps. Therefore, 23 distinct delivered orders have at least one of these missing timestamps.

### 4.2 Product Attributes

| Field | Missing Records |
|---|---:|
| Product category | 610 |
| Product photo count | 610 |
| Product weight | 2 |

The 610 products missing product categories are the exact same products missing photo counts.

There are no category-only or photo-count-only missing records in this check.

Six products have missing or nonpositive weight values:

- Two products have missing weights.
- Four products have zero weights.

## 5. Order Status Distribution

| Order Status | Orders | Percentage |
|---|---:|---:|
| Delivered | 96,478 | 97.02% |
| Shipped | 1,107 | 1.11% |
| Canceled | 625 | 0.63% |
| Unavailable | 609 | 0.61% |
| Invoiced | 314 | 0.32% |
| Processing | 301 | 0.30% |
| Created | 5 | 0.01% |
| Approved | 2 | 0.00% |

Percentages are rounded.

## 6. Timestamp Consistency

### 6.1 Carrier Timestamp Before Purchase

A total of 166 orders have a carrier timestamp earlier than the purchase timestamp.

| Time Difference | Affected Orders |
|---|---:|
| Within 1 hour | 121 |
| 1 to 24 hours | 43 |
| 1 to 7 days | 1 |
| More than 7 days | 1 |
| **Total** | **166** |

The discrepancies include both small and substantial time differences.

They should not all be assumed to be timezone or rounding issues.

### 6.2 Customer Delivery Before Carrier

A total of 23 orders have customer-delivery timestamps earlier than their carrier timestamps.

| Measure | Hours |
|---|---:|
| Average difference | 78.46 |
| Minimum difference | 0.39 |
| Maximum difference | 386.31 |

These records have an invalid chronological sequence for carrier-to-customer delivery duration calculations.

### 6.3 Late Deliveries

A total of 7,827 delivered orders have a customer-delivery timestamp later than the estimated delivery date.

These are valid late-delivery business outcomes, not invalid records.

They should remain available for delivery-performance analysis.

## 7. Numeric and Product Attribute Validation

The completed checks found:

- No missing or nonpositive order-item prices.
- No missing or negative freight values.
- No missing or negative payment values.
- No missing or invalid review scores.
- Four products with zero weight.
- Two products with missing weight.
- No nonpositive product lengths.
- No nonpositive product heights.
- No nonpositive product widths.
- No negative product photo counts.

The freight check tested negative values; zero freight was not classified as negative.

## 8. Review Record Investigation

The review investigation identified:

| Check | Result |
|---|---:|
| Repeated review ID groups | 789 |
| Excess rows beyond the first row in repeated groups | 814 |
| Orders with multiple reviews | 547 |
| Exact duplicate review rows | 0 |

Additional findings:

- Repeated review IDs occur across different orders.
- All occurrences within repeated ID groups have the same review score.
- No exact duplicate review rows were found.

### Decision

Do not deduplicate review records using `review_id` alone.

Do not impose a unique constraint on `review_id`.

Preserve the source review records and define the appropriate review grain and aggregation logic before combining reviews with order-level data.

## 9. Planned Data Quality Treatment

| Issue | Planned Treatment |
|---|---|
| Missing source timestamps | Preserve NULL |
| Missing timestamps on non-delivered orders | Preserve NULL; interpret with order status |
| Missing timestamps on delivered orders | Preserve NULL and add quality flags |
| Carrier timestamp before purchase | Preserve source values and flag invalid sequence |
| Customer delivery before carrier | Preserve source values and flag invalid sequence |
| Late delivery | Retain as a valid business outcome |
| Missing product category | Map to `Unknown` in reporting while retaining the source value |
| Missing product photo count | Preserve NULL |
| Missing or zero product weight | Preserve raw value; set analytical weight to NULL and flag |
| Repeated review IDs | Retain records; do not deduplicate on review ID alone |

Duration calculations should use valid timestamp sequences. Invalid or incomplete sequences should not be silently included in delivery-duration averages.

## 10. Limitations

- Timestamp inconsistencies can affect delivery-duration metrics.
- Late-delivery calculations must define their denominator clearly.
- ZIP-code prefixes cannot be treated as unique geographic identifiers.
- Review IDs cannot be treated as unique keys.
- The source data is historical.
- Relationships between review scores and delivery performance are descriptive and do not establish causation.

## 11. Assessment Status

Source-data import, row-count reconciliation, key and relationship validation, and the profiling checks documented above are complete.

The proposed data-quality treatments have not yet all been implemented. They will be applied and validated during the SQL transformation phase.
