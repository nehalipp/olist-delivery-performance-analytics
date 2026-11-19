# Data Quality Assessment

## 1. Purpose

This document records the source-data profiling, transformation, and validation performed for the Olist Brazilian E-Commerce Public Dataset.

The assessment covers:

- Source record counts and table grain
- Missing values and invalid attributes
- Key uniqueness and referential integrity
- Timestamp consistency and delivery performance
- Numeric and financial field validation
- Payment and review record patterns
- Geolocation duplication and coordinate anomalies

The project uses a layered PostgreSQL architecture:

`staging → transform → warehouse → analytics`

The original source data is preserved in the staging schema. Standardization, type conversion, derived attributes, and data-quality flags are implemented in the transform schema.

## 2. Source Import Validation

All nine source CSV files were imported into PostgreSQL staging tables.

The imported row counts matched the expected source record counts.

| Source Table | Imported Records |
|---|---:|
| customers_raw | 99,441 |
| geolocation_raw | 1,000,163 |
| order_items_raw | 112,650 |
| order_payments_raw | 103,886 |
| order_reviews_raw | 99,224 |
| orders_raw | 99,441 |
| product_category_translation_raw | 71 |
| products_raw | 32,951 |
| sellers_raw | 3,095 |
| **Total** | **1,650,922** |

These counts represent imported source records, not unique customers, orders, products, or geographic locations.

All staging columns were defined as `TEXT` to preserve source representations during ingestion.

## 3. Source Keys and Relationship Validation

The source profiling and transformation checks established the following key characteristics.

| Dataset | Record Grain / Key | Validation Result |
|---|---|---|
| Orders | One row per `order_id` | 99,441 rows; no duplicate order IDs |
| Customers | One row per `customer_id` | 99,441 rows; no duplicate customer IDs |
| Products | One row per `product_id` | 32,951 rows; no duplicate product IDs |
| Sellers | One row per `seller_id` | 3,095 rows; no duplicate seller IDs |
| Order Items | (`order_id`, `order_item_id`) | 112,650 rows; no duplicate composite keys |
| Payments | (`order_id`, `payment_sequential`) | 103,886 rows; no duplicate composite keys |
| Reviews | (`review_id`, `order_id`) | 99,224 rows; composite keys unique; `review_id` alone is not unique |
| Geolocation | Source geographic record | ZIP prefixes are not unique |
| Category Translation | One row per Portuguese category | 71 rows |

### Identifier Considerations

- `customer_id` identifies the customer record associated with an order.
- `customer_unique_id` identifies the underlying customer across potentially multiple customer records and orders.
- The customer source contains 96,096 distinct `customer_unique_id` values across 99,441 customer records.
- The 3,345 additional customer records reflect multiple customer records associated with the same underlying customer identifier.
- `review_id` repeats across different orders and must not be treated as a unique key.
- Geolocation ZIP prefixes are not unique and must not be used as standalone geographic primary keys.

### Referential Integrity

The following checks returned no unmatched records:

- Order items referencing unknown orders
- Order items referencing unknown products
- Order items referencing unknown sellers
- Payments referencing unknown orders
- Reviews referencing unknown orders

No unmatched customer references were identified in the order/customer relationship checks.

## 4. Orders Data Quality

### 4.1 Order Status Distribution

The source contains 99,441 orders across eight order statuses.

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
| **Total** | **99,441** | **100.00%** |

Percentages are rounded.

### 4.2 Missing Order Timestamps

| Source Field | Missing Records |
|---|---:|
| `order_approved_at` | 160 |
| `order_delivered_carrier_date` | 1,783 |
| `order_delivered_customer_date` | 2,965 |

Missing timestamps were investigated by order status.

Among delivered orders:

- 14 orders have missing approval timestamps.
- 2 orders have missing carrier timestamps.
- 8 orders have missing customer-delivery timestamps.
- One order overlaps the missing carrier and customer-delivery groups.

Therefore, 23 distinct delivered orders have at least one missing lifecycle timestamp.

Missing lifecycle timestamps on non-delivered orders are generally consistent with incomplete or non-delivered order processes. They should not automatically be classified as invalid records.

### 4.3 Timestamp Sequence Validation

| Validation | Affected Orders |
|---|---:|
| Approval before purchase | 0 |
| Carrier timestamp before purchase | 166 |
| Customer delivery before carrier timestamp | 23 |
| Customer delivery before purchase | 0 |

The 166 carrier-before-purchase cases were investigated:

| Time Difference | Orders |
|---|---:|
| Within 1 hour | 121 |
| 1 to 24 hours | 43 |
| 1 to 7 days | 1 |
| More than 7 days | 1 |
| **Total** | **166** |

For the 23 orders with customer delivery before carrier timestamps:

| Measure | Result |
|---|---:|
| Average sequence difference | 78.46 hours |
| Minimum sequence difference | 0.39 hours |
| Maximum sequence difference | 386.31 hours |

These timestamp sequences are flagged in `transform.orders_clean`.

Original timestamp values are preserved. Duration calculations must exclude invalid or incomplete timestamp sequences.

### 4.4 Late Delivery Validation

A raw timestamp comparison initially identified 7,827 records where customer delivery occurred after the estimated delivery date.

One of those records belonged to a canceled order.

The validated delivered-order result is:

| Measure | Orders |
|---|---:|
| Delivered orders with delivery after estimated date | 7,826 |

Late delivery is a valid business outcome, not a data-quality error.

The `is_late_delivery` flag in `transform.orders_clean` identifies delivered orders with both required timestamps and an actual delivery timestamp later than the estimated date.

The late-delivery KPI should use delivered orders with valid actual and estimated delivery timestamps as its denominator.

## 5. Customer Data Quality

The customer transformation produced:

| Validation | Result |
|---|---:|
| Total customer records | 99,441 |
| Distinct `customer_id` values | 99,441 |
| Duplicate customer records | 0 |
| Distinct `customer_unique_id` values | 96,096 |
| Additional customer records | 3,345 |
| Missing required customer fields | 0 |

Customer city and state values were standardized to uppercase, and text fields were trimmed.

ZIP prefixes were retained as text.

The distinction between `customer_id` and `customer_unique_id` must be maintained in customer-level analysis:

- Use `customer_id` to identify the customer record associated with an order.
- Use `customer_unique_id` to identify repeat customers across orders.

## 6. Product Data Quality

The product transformation produced 32,951 records with no duplicate product IDs.

### 6.1 Missing Attributes

| Product Attribute | Missing Records |
|---|---:|
| Product category | 610 |
| Product photo count | 610 |
| Product name length | 610 |
| Product description length | 610 |
| Product weight | 2 |

The same 610 products are missing category, photo count, name length, and description length.

These are not four separate groups of missing products.

### 6.2 Weight and Dimension Validation

| Validation | Result |
|---|---:|
| Missing product weights | 2 |
| Zero product weights | 4 |
| Nonpositive product lengths | 0 |
| Nonpositive product heights | 0 |
| Nonpositive product widths | 0 |
| Negative photo counts | 0 |
| Negative weights | 0 |

The source column names `product_name_lenght` and `product_description_lenght` were standardized to `product_name_length` and `product_description_length`.

### Treatment

- Missing product attributes remain `NULL`.
- Zero weight remains zero and is identified using a quality flag.
- Missing product categories retain their original NULL source values and are classified as `Unknown` in the English reporting category.
- Product dimensions are retained without unnecessary modification.

### 6.3 Product Category Translation Validation

The product dimension uses the source category translation table containing 71 Portuguese-to-English mappings.

Initial validation identified 13 products across two categories without translation matches.

The following mappings were added during product dimension loading:

| Portuguese Category | English Category | Products |
|---|---|---:|
| `portateis_cozinha_e_preparadores_de_alimentos` | Portable Kitchen and Food Preparers | 10 |
| `pc_gamer` | Gaming PC | 3 |

Final category classification:

| Category Status | Products |
|---|---:|
| Missing source category | 610 |
| Translation available | 32,341 |
| No translation match | 0 |
| **Total** | **32,951** |

The product dimension retains the original Portuguese category and includes the translated English category and a `category_status` quality classification.

All 32,951 product records were retained. No product records were removed during category translation handling.

## 7. Seller Data Quality

The seller transformation produced:

| Validation | Result |
|---|---:|
| Total seller records | 3,095 |
| Distinct seller IDs | 3,095 |
| Duplicate seller records | 0 |
| Missing required fields | 0 |
| Distinct seller states | 23 |

Seller city and state values were standardized to uppercase, and text fields were trimmed.

ZIP prefixes were retained as text.

## 8. Order Item Data Quality

The order-item transformation produced 112,650 records.

The composite key is (`order_id`, `order_item_id`).

| Validation | Result |
|---|---:|
| Total order-item records | 112,650 |
| Distinct orders with items | 98,666 |
| Distinct composite keys | 112,650 |
| Duplicate composite keys | 0 |
| Missing required identifiers or dates | 0 |
| Nonpositive item prices | 0 |
| Negative freight values | 0 |
| Zero freight values | 383 |
| Unmatched order references | 0 |
| Unmatched product references | 0 |
| Unmatched seller references | 0 |

Zero freight values are retained and are not classified as negative freight.

### 8.1 Financial Baseline

| Measure | Amount |
|---|---:|
| Total item price | 13,591,643.70 |
| Total freight value | 2,251,909.54 |
| Average item price | 120.65 |
| Average freight per item | 19.99 |

These amounts represent sums across source order-item records. Total item price should not automatically be described as recognized revenue or equated with total payment value.

### 8.2 Orders Without Item Records

There are 775 orders in `transform.orders_clean` without corresponding order-item records.

Their status distribution is:

| Order Status | Orders Without Items |
|---|---:|
| Unavailable | 603 |
| Canceled | 164 |
| Created | 5 |
| Invoiced | 2 |
| Shipped | 1 |
| **Total** | **775** |

No order-item records should be invented for these orders.

These orders remain part of the order-level dataset, while `fact_order_items` should contain only actual source order items.

### 8.3 Shipping Limit Timestamp Anomalies

Shipping-limit timestamp profiling identified four anomalous order-item records across three distinct orders.

| Shipping Limit Year | Order Items |
|---|---:|
| 2016 | 370 |
| 2017 | 49,765 |
| 2018 | 62,511 |
| 2020 | 4 |

The four records with 2020 shipping-limit dates have purchase timestamps from 2017.

The affected records span February 3, 2020 through April 9, 2020.

The affected orders include delivered, canceled, and shipped statuses. One delivered order contains two affected order items.

These records represent anomalous source timestamps and are not automatically corrected or removed.

**Treatment**

- Preserve the original shipping-limit timestamps.
- Retain all four order-item records.
- Flag the anomalous records for data-quality monitoring.
- Do not use the anomalous shipping-limit timestamps in delivery-performance calculations unless their validity has been independently established.

## 9. Payment Data Quality

The payment transformation produced 103,886 records.

The payment record grain is one row per order payment sequence, identified by (`order_id`, `payment_sequential`).

| Validation | Result |
|---|---:|
| Total payment records | 103,886 |
| Distinct orders with payments | 99,440 |
| Distinct payment composite keys | 103,886 |
| Duplicate payment composite keys | 0 |
| Missing payment fields | 0 |
| Invalid payment sequence values | 0 |
| Invalid installment values | 2 |
| Negative payment values | 0 |
| Zero payment values | 9 |
| Total payment value | 16,008,872.12 |
| Average payment record value | 154.10 |

### 9.1 Payment Patterns

- 2,961 orders have multiple payment records.
- The maximum number of payment records for one order is 29.
- Zero payment values are retained.
- `not_defined` payment types are retained.
- Two credit-card records have zero installments and are flagged as invalid installment records.

The two records with invalid installments have payment values of 129.94 and 58.69.

### 9.2 Orders Without Payment Records

One delivered order has no associated payment record:

`bfbd0f9bdef84302105ad712db648a6c`

| Attribute | Result |
|---|---:|
| Order status | Delivered |
| Order items | 3 |
| Total item price | 134.97 |
| Total freight | 8.49 |
| Payment records | 0 |

The order and its item records are preserved. No synthetic payment record is created.

### Treatment

- Preserve all payment records.
- Retain zero-value payment records.
- Flag invalid installment values.
- Retain `not_defined` payment types.
- Aggregate payment records to order grain before joining them to `fact_orders`.
- Do not join raw payment records directly to raw order-item records when calculating financial measures.

## 10. Review Data Quality

The review transformation produced 99,224 records.

| Validation | Result |
|---|---:|
| Total review records | 99,224 |
| Distinct review IDs | 98,410 |
| Distinct orders with reviews | 98,673 |
| Repeated review ID groups | 789 |
| Excess rows associated with repeated review IDs | 814 |
| Duplicate (`review_id`, `order_id`) combinations | 0 |
| Orders with multiple reviews | 547 |
| Maximum reviews per order | 3 |
| Exact duplicate review rows | 0 |
| Missing required fields | 0 |
| Invalid review scores | 0 |
| Invalid review timestamp sequences | 0 |
| Unmatched order references | 0 |

### 10.1 Review Score Distribution

| Review Score | Review Records | Percentage |
|---|---:|---:|
| 1 | 11,424 | 11.51% |
| 2 | 3,151 | 3.18% |
| 3 | 8,179 | 8.24% |
| 4 | 19,142 | 19.29% |
| 5 | 57,328 | 57.78% |
| **Total** | **99,224** | **100.00%** |

### Treatment

- Preserve all review records.
- Do not impose a unique constraint on `review_id`.
- Do not deduplicate using `review_id` alone.
- The combination (`review_id`, `order_id`) was validated as unique in the source review records.
- Aggregate review metrics to order grain before joining them to `fact_orders`.

Average review score and review count should be calculated using an explicit order-level aggregation rule.

## 11. Geolocation Data Quality

The geolocation transformation produced 1,000,163 records.

| Validation | Result |
|---|---:|
| Total records | 1,000,163 |
| Distinct ZIP prefixes | 19,015 |
| Distinct cities | 8,010 |
| Distinct states | 27 |
| Missing ZIP prefixes | 0 |
| Missing coordinates | 0 |
| Missing cities or states | 0 |
| Invalid numeric coordinate formats | 0 |
| Coordinates outside standard latitude/longitude limits | 0 |

### 11.1 Duplicate Records

| Validation | Result |
|---|---:|
| Exact duplicate groups | 128,178 |
| Excess rows in exact duplicate groups | 261,836 |
| ZIP prefixes with multiple records | 17,972 |
| Maximum records for one ZIP prefix | 1,146 |

The geolocation source contains substantial repetition and multiple coordinate records per ZIP prefix.

These are source characteristics that must be considered when designing the location lookup.

### 11.2 Geographic Coordinate Screening

A broad geographic screening range was used to identify records outside approximate Brazilian geographic bounds:

- Latitude: -34 to 6
- Longitude: -74 to -32

The revised longitude range accommodates locations such as Fernando de Noronha.

| Validation | Records |
|---|---:|
| Outside approximate latitude bounds | 31 |
| Outside approximate longitude bounds | 26 |
| Outside either coordinate bound | 31 |

These 31 records are geographically suspicious and should be flagged for geographic reporting.

The screening range is a broad rectangular approximation, not an exact Brazilian national boundary. Records outside the range should not automatically be deleted.

### 11.3 ZIP Prefixes Associated with Multiple States

Eight ZIP prefixes were identified with records assigned to more than one state.

Examples include:

- `02116`: São Paulo, SP and São Paulo, RN
- `04011`: São Paulo, SP and São Paulo, AC
- `21550`: Rio de Janeiro, RJ and Rio de Janeiro, AC
- `23056`: Rio de Janeiro, RJ and Rio de Janeiro, AC
- `72915`: Goiás and Distrito Federal assignments
- `78557`: Mato Grosso and Rondônia assignments
- `79750`: Mato Grosso do Sul and Rio Grande do Sul assignments
- `80630`: Paraná and Santa Catarina assignments

Some conflicts involve isolated records against a much larger group with consistent geographic assignments.

These records should be investigated rather than automatically resolved using the most frequent state.

### Treatment

- Preserve all source records in `transform.geolocation_clean`.
- Do not deduplicate the cleaned source table.
- Do not treat ZIP prefix as a unique geographic key.
- Flag geographically suspicious coordinates.
- Investigate ZIP prefixes associated with multiple states.
- Create a separate geographic lookup during warehouse modeling using a documented aggregation or representative-location rule.

## 12. Transformation Summary

All eight table-specific transformation scripts have been executed and validated.

| Transformation Script | Target Table | Source Records | Status |
|---|---|---:|---|
| 01_transform_orders.sql | `transform.orders_clean` | 99,441 | Validated |
| 02_transform_customers.sql | `transform.customers_clean` | 99,441 | Validated |
| 03_transform_products.sql | `transform.products_clean` | 32,951 | Validated |
| 04_transform_sellers.sql | `transform.sellers_clean` | 3,095 | Validated |
| 05_transform_order_items.sql | `transform.order_items_clean` | 112,650 | Validated |
| 06_transform_payments.sql | `transform.payments_clean` | 103,886 | Validated |
| 07_transform_reviews.sql | `transform.reviews_clean` | 99,224 | Validated |
| 08_transform_geolocation.sql | `transform.geolocation_clean` | 1,000,163 | Validated |

The product category translation source contains 71 records and was incorporated during product dimension development. Two additional category mappings were added to resolve the 13 initially unmatched product records.

## 13. Cross-Table Modeling Considerations

The following rules must be maintained during warehouse implementation:

1. `fact_orders` must contain one row per order.
2. `fact_order_items` must contain one row per order item.
3. Payment records must be aggregated to order grain before joining to an order-level fact.
4. Review records must be aggregated to order grain using a documented rule.
5. Raw order-item records must not be joined directly to raw payment or review records without controlling for fan-out.
6. Orders without order items must remain represented in the order-level fact.
7. Orders without payment records must remain represented, with missing payment information identified.
8. Customer-level repeat-order analysis must use `customer_unique_id`.
9. Geolocation ZIP prefixes must not be treated as unique keys.
10. Delivery-duration calculations must use valid and complete timestamp sequences.

## 14. Known Limitations

- The source order activity primarily spans 2016 through 2018. Four anomalous shipping-limit timestamps extend into 2020 and are documented separately.
- Some order lifecycle timestamps are missing or have inconsistent chronological sequences.
- Some products have incomplete descriptive attributes.
- Payment records do not exist for one delivered order.
- Review IDs repeat across different orders.
- Geolocation contains substantial duplicate records and some geographic inconsistencies.
- ZIP-prefix geography is not sufficiently reliable to serve as a unique location key.
- Item sales value and payment value are different measures and should not be treated as interchangeable.
- Review-score and delivery-performance comparisons are descriptive and do not establish causation.
- The source data does not contain all information required to calculate complete marketplace profitability.

## 15. Assessment Status

**Source import, transformation validation, and initial dimension validation are complete.**

The staging and transformation layers have been created and validated against the source data.

The initial dimensional warehouse contains validated customer, product, seller, and date dimensions.

Known data-quality exceptions have been retained, flagged, or documented rather than silently removed.

The following warehouse activities remain pending:

- `fact_orders` implementation and validation.
- `fact_order_items` implementation and validation.
- Payment and review aggregation validation.
- Warehouse referential integrity and financial reconciliation.
- Analytical reporting view development.

The next phase is fact-table implementation, beginning with `fact_orders`.

This document will be extended with fact-table, warehouse-level, and analytics-level validation results after those layers are implemented.

## 16. Warehouse Dimension Validation

The initial dimensional warehouse tables have been created and validated.

### 16.1 Dimension Row Counts and Business-Key Uniqueness

| Dimension | Total Rows | Distinct Business Keys | Duplicate Keys |
|---|---:|---:|---:|
| dim_customer | 99,441 | 99,441 | 0 |
| dim_product | 32,951 | 32,951 | 0 |
| dim_seller | 3,095 | 3,095 | 0 |

All three dimensions passed row-count and business-key uniqueness validation.

### 16.2 Date Dimension Validation

| Validation | Result |
|---|---|
| First calendar date | 2016-09-04 |
| Last calendar date | 2020-04-09 |
| Total calendar records | 1,314 |
| Missing calendar dates | 0 |

The date dimension provides continuous calendar coverage across the validated date range.

### 16.3 Product Dimension Validation

The product dimension contains 32,951 unique product records.

Category translation validation confirmed:

- 32,341 products with available English translations.
- 610 products with missing source categories.
- 0 products with unresolved translation matches.

The original source category values are preserved, and missing categories are classified as `Unknown` for English reporting.

### 16.4 Warehouse Validation Status

The initial customer, product, seller, and date dimensions have passed their current validation checks.

Fact-table implementation and subsequent warehouse reconciliation remain pending.