# Data Model and Warehouse Design

## 1. Status

This document describes the implemented dimensional warehouse structure, fact-table design, and analytical reporting layer for the Olist Brazilian E-Commerce Public Dataset.

The PostgreSQL staging, transformation, warehouse, and analytics layers have been implemented and validated.

The warehouse contains four dimensions and two fact tables. The analytics schema contains six reporting views designed to support business intelligence and dashboard development in Power BI and Tableau.

## 2. Database Architecture

The PostgreSQL architecture contains four schemas.

| Schema | Purpose | Status |
|---|---|---|
| staging | Source-aligned imported data | Implemented and validated |
| transform | Standardized fields, derived attributes, and data-quality flags | Implemented and validated |
| warehouse | Dimensional fact and dimension tables | Implemented and validated |
| analytics | Reporting views and BI-facing datasets | Implemented and validated |

### Data Flow

```text
Source CSV Files
      |
      v
   staging
      |
      v
  transform
      |
      v
  warehouse
      |
      v
  analytics
      |
      +------> Power BI
      |
      +------> Tableau
```

The staging layer preserves imported source data. The transformation layer standardizes data types, derives attributes, and retains data-quality indicators. The warehouse organizes the transformed data into dimensions and fact tables. The analytics layer provides reporting-ready views.

## 3. Fact Tables

Two primary fact tables have been implemented in the warehouse.

### 3.1 fact_orders

**Grain:** One row per order, identified by `order_id`.

**Validated rows:** 99,441

The table supports analysis of:

- Order counts and status.
- Purchase and approval timestamps.
- Carrier and customer-delivery timestamps.
- Estimated delivery dates.
- Approval duration and delivery duration.
- On-time and late-delivery outcomes.
- Order-level payment measures.
- Order-level review measures.
- Missing and invalid timestamp sequences.

**Dimension relationships:**

- `customer_key` references `dim_customer`.
- `purchase_date_key` references `dim_date`.
- `approval_date_key` references `dim_date`.
- `carrier_date_key` references `dim_date`.
- `delivery_date_key` references `dim_date`.
- `estimated_delivery_date_key` references `dim_date`.

The date dimension is used through five role-playing date relationships to support different stages of the order lifecycle.

Payment and review records are aggregated separately to order grain before being incorporated into the fact table. This prevents multiple payment records or reviews from multiplying order-level measures.

Orders without payment records are retained, with payment availability identified through `has_payment_record`.

### 3.2 fact_order_items

**Grain:** One row per order item, identified by the composite key `(order_id, order_item_id)`.

**Validated rows:** 112,650

The table supports analysis of:

- Item sales value.
- Freight value.
- Total item value.
- Product and product-category performance.
- Seller performance.
- Shipping-limit dates.
- Delivery performance associated with orders.
- Shipping-limit timestamp anomalies.

**Dimension and fact relationships:**

- `order_key` references `fact_orders`.
- `product_key` references `dim_product`.
- `seller_key` references `dim_seller`.
- `shipping_limit_date_key` references `dim_date`.

Customer and order-level attributes are accessed through the related `fact_orders` record.

The item-level financial measures are defined as:

- Item sales: `price`
- Freight: `freight_value`
- Total item value: `price + freight_value`

Order-level payment totals are not stored or repeated in this fact table. This prevents duplication when analyzing item-level sales.

## 4. Implemented Dimensions

The following dimensions have been created and validated in the warehouse.

| Dimension | Grain / Business Key | Validated Rows | Status |
|---|---|---:|---|
| dim_date | One row per calendar date | 1,314 | Validated |
| dim_customer | One row per customer_id | 99,441 | Validated |
| dim_product | One row per product_id | 32,951 | Validated |
| dim_seller | One row per seller_id | 3,095 | Validated |

### 4.1 dim_date

Provides calendar attributes for relevant business dates.

- Date coverage: September 4, 2016 – April 9, 2020.
- One row per calendar date.
- Includes day, week, month, quarter, year, and weekend attributes.
- Used for purchase, approval, carrier, delivery, estimated delivery, and shipping-limit date analysis.

### 4.2 dim_customer

Contains customer record attributes and customer geography.

- Business key: `customer_id`.
- `customer_unique_id` remains available for repeat-customer analysis.
- Contains ZIP code prefix, city, and state attributes.

The dimension contains 99,441 customer records and 96,096 distinct `customer_unique_id` values.

### 4.3 dim_product

Contains product attributes and translated product categories.

- Business key: `product_id`.
- Preserves the original Portuguese category.
- Includes the English product category.
- Includes `category_status` to distinguish missing source categories, unmatched translations, and available translations.
- Includes product dimensions and descriptive attributes where available.

Current category classification:

| Category Status | Products |
|---|---:|
| Missing source category | 610 |
| Translation available | 32,341 |
| No translation match | 0 |
| **Total** | **32,951** |

Products with missing source categories retain their original NULL category and use `Unknown` for the English reporting category.

### 4.4 dim_seller

Contains seller attributes and seller geography.

- Business key: `seller_id`.
- One row per seller record.
- Includes ZIP code prefix, city, and state attributes.

Additional dimensions should be introduced only when they support a clear analytical requirement.

## 5. Source Key Considerations

### Customer Identifiers

- `customer_id` identifies the customer record associated with an order.
- `customer_unique_id` identifies the customer across potentially multiple customer records and orders.
- The customer source contains 99,441 records but only 96,096 distinct `customer_unique_id` values.
- Customer performance in the warehouse is grouped by `customer_key`, representing the customer record.

### Geolocation

`geolocation_zip_code_prefix` is not unique.

Multiple geographic records can share the same ZIP prefix. It must not be treated as a unique primary key or arbitrarily reduced to one coordinate without a documented selection or aggregation rule.

### Reviews

`review_id` repeats across different orders.

It must not be treated as a unique source key, and review records must not be deduplicated solely on that field.

Review measures are aggregated at order grain before being incorporated into `fact_orders`.

## 6. Grain and Fan-Out Controls

The warehouse uses separate order-level and order-item-level fact tables to preserve the correct grain of business measures.

The following controls have been implemented:

- `fact_orders` contains one row per order.
- `fact_order_items` contains one row per `(order_id, order_item_id)`.
- Payment records are aggregated to order grain before being joined to the order-level fact.
- Review records are aggregated to order grain before being joined to the order-level fact.
- Order-item financial measures remain at item grain.
- Order-level payment totals are not repeated across order-item rows.
- Orders without order-item records are preserved in `fact_orders`.
- Orders without payment records are preserved and identified through payment availability flags.
- Fact-table row counts, business-key uniqueness, foreign-key completeness, and financial totals are validated after loading.

These controls prevent duplicated measures when combining order, payment, review, and order-item data.

## 7. Business Measures

The warehouse and analytics views support the following business measures:

| Measure | Definition / Source |
|---|---|
| Order count | Count of orders from `fact_orders` |
| Item sales value | Sum of item prices, excluding freight |
| Freight value | Sum of item freight charges |
| Total item value | Sum of item prices and freight |
| Payment value | Aggregated order-level payment amount |
| Delivered-order count | Count of delivered orders |
| Late-delivery count | Count of orders flagged as late |
| On-time delivery rate | Delivered orders not flagged late divided by delivered orders |
| Delivery duration | Time between purchase and delivery |
| Average review score | Aggregated order-level review score |
| Repeat-customer activity | Analysis using `customer_unique_id` across customer records |

Final KPI definitions, filters, and denominators should be maintained consistently in the BI semantic model and documented separately where required.

## 8. Data Quality Integration

The transformation and warehouse layers retain data-quality indicators to support transparent reporting and analysis.

### Order Timestamp Quality

- Invalid timestamp sequences are identifiable through flags in `transform.orders_clean` and the corresponding warehouse order-level quality indicators.
- Missing approval, carrier, and delivery timestamps are retained rather than artificially populated.
- Delivery-duration calculations rely on available, valid timestamp sequences.
- Orders with incomplete or invalid lifecycle timestamps remain identifiable through quality flags.

### Product Category Quality

- Missing product categories are represented as `Unknown` in English reporting while preserving the original source value.
- The product dimension retains `category_status` to distinguish missing source categories from translation failures.
- All product categories requiring translation were successfully mapped or classified.

### Shipping-Limit Timestamp Anomalies

Four anomalous shipping-limit timestamp records across three orders were identified during source profiling.

These records are retained in the warehouse and identified through `is_shipping_limit_anomalous`.

They must not be silently corrected or removed. Reporting and analysis should account for the anomaly flag where shipping-limit dates are used.

### Missing and Incomplete Records

- Orders without order-item records remain available in `fact_orders`.
- Orders without payment records remain available and are identified through `has_payment_record`.
- Missing review information is distinguishable through review availability indicators.

## 9. Analytics Layer

The analytics schema contains six reporting views built on top of the validated warehouse tables. These views provide business-ready datasets for Power BI and Tableau.

| View | Grain | Purpose |
|---|---|---|
| vw_order_performance | One row per order | Order status, customer details, payment, review, and order lifecycle metrics |
| vw_sales_performance | One row per order item | Item sales, freight, product, seller, customer, and delivery attributes |
| vw_customer_performance | One row per customer record | Customer order activity, payment value, reviews, and item sales |
| vw_product_performance | One row per product | Product sales, order volume, and customer activity |
| vw_seller_performance | One row per seller | Seller sales, order volume, and delivery performance |
| vw_delivery_performance | One row per order | Delivery timelines, delays, and timestamp quality indicators |

### 9.1 Aggregation Rules

- Item sales represent the sum of product prices, excluding freight.
- Freight represents the sum of shipping charges.
- Total item value includes both item prices and freight.
- Order payment totals are retained at order grain and must not be summed from the order-item view.
- Customer performance is grouped by `customer_key`, representing an individual customer record rather than the repeat-customer identifier `customer_unique_id`.
- Payment and review metrics are aggregated at order grain to prevent duplication when combined with order-item data.

### 9.2 Analytics Validation

All six reporting views were validated for row counts, distinct business keys, and financial reconciliation.

| Validation | Validated Rows / Count |
|---|---:|
| Orders | 99,441 |
| Order items | 112,650 |
| Customer records | 99,441 |
| Products | 32,951 |
| Sellers | 3,095 |
| Delivered orders | 96,478 |
| Late delivered orders | 7,826 |

Financial reconciliation:

| Measure | Validated Total |
|---|---:|
| Item sales | 13,591,643.70 |
| Freight | 2,251,909.54 |
| Total item value | 15,843,553.24 |
| Order payment value | 16,008,872.12 |

The analytics views reconcile to the corresponding warehouse totals. All reported row-count, uniqueness, and financial validation checks passed.