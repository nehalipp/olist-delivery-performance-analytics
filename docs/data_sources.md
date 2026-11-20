
# Data Sources

## 1. Source Overview

This project uses the Olist Brazilian E-Commerce Public Dataset, published on Kaggle.

**Source:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains historical Brazilian marketplace transactions and related customer, seller, product, payment, review, and geographic information.

The original CSV files are stored locally for database ingestion and are excluded from GitHub.

## 2. Dataset Inventory

The project uses nine source datasets.

| Source Table | Imported Rows | Purpose |
|---|---:|---|
| customers_raw | 99,441 | Customer records and customer geography |
| geolocation_raw | 1,000,163 | ZIP-prefix geographic coordinates and locality |
| order_items_raw | 112,650 | Products and sellers associated with orders |
| order_payments_raw | 103,886 | Payment methods, installments, and payment values |
| order_reviews_raw | 99,224 | Review scores, comments, and timestamps |
| orders_raw | 99,441 | Order status and lifecycle timestamps |
| product_category_translation_raw | 71 | Portuguese-to-English product category mapping |
| products_raw | 32,951 | Product categories and physical attributes |
| sellers_raw | 3,095 | Seller records and seller geography |
| **Total** | **1,650,922** | |

These are imported source-row counts, not counts of unique orders, customers, or products.

## 3. Source Table Grain

Understanding the grain of each source table is necessary to prevent duplicated counts and financial measures during analysis.

| Source Table | Grain / Identifier |
|---|---|
| Customers | One record per `customer_id` |
| Geolocation | Multiple records may share a ZIP prefix |
| Order Items | One record per order item, identified by (`order_id`, `order_item_id`) |
| Order Payments | One record per payment sequence within an order, identified by (`order_id`, `payment_sequential`) |
| Order Reviews | One source review record; `review_id` is not unique by itself |
| Orders | One record per `order_id` |
| Category Translation | One record per Portuguese category |
| Products | One record per `product_id` |
| Sellers | One record per `seller_id` |

### Identifier Notes

- `customer_id` identifies the customer record associated with an order.
- `customer_unique_id` identifies the underlying customer across potentially multiple customer records and orders.
- `review_id` can repeat across different orders. The combination of `review_id` and `order_id` is used when validating review records.
- Geolocation ZIP prefixes are not unique and must not be treated as primary keys.

## 4. Geographic and Time Coverage

The dataset represents Brazilian e-commerce activity primarily from 2016 through 2018.

The validated date dimension covers September 4, 2016 through April 9, 2020 because it includes relevant source lifecycle and shipping-limit timestamps.

Four anomalous shipping-limit timestamps from 2020 were identified in records associated with orders from 2017. These records are retained and flagged rather than silently corrected.

Date coverage for individual analyses should be determined from the relevant source timestamp field rather than assumed from the dataset publication date.

## 5. Import and Transformation Approach

All nine source datasets were imported into PostgreSQL schema `staging`.

The staging columns were defined as `TEXT` to preserve the original source representations during ingestion.

Eight table-specific SQL transformation scripts have been implemented and validated in the `transform` schema.

The transformation scripts:

- Trim and standardize text fields.
- Convert source values into appropriate data types.
- Preserve missing values where appropriate.
- Derive analytical attributes and timestamps.
- Create data-quality flags for identified exceptions.
- Retain source records rather than silently deleting valid business exceptions.

The product category translation table was incorporated during product dimension development. Two additional category mappings were added for the 13 product records that did not match the original translation lookup.

The resulting product dimension contains 32,341 products with available English category translations and 610 products with missing source categories. No unresolved translation matches remain.

Source row counts and transformation validation findings are documented in [Data Quality Assessment](data_quality_report.md).

## 6. Warehouse Usage

The transformed datasets support a PostgreSQL dimensional warehouse containing:

### Dimensions

- `warehouse.dim_date`
- `warehouse.dim_customer`
- `warehouse.dim_product`
- `warehouse.dim_seller`

### Fact Tables

- `warehouse.fact_orders`
- `warehouse.fact_order_items`

Payment and review records are aggregated to order grain before being included in `fact_orders`.

The separate order and order-item fact tables preserve their respective grains and prevent order-level measures from being multiplied by the number of items in an order.

## 7. Analytical Usage

Six reporting views are available in the PostgreSQL `analytics` schema:

- `analytics.vw_order_performance`
- `analytics.vw_sales_performance`
- `analytics.vw_customer_performance`
- `analytics.vw_product_performance`
- `analytics.vw_seller_performance`
- `analytics.vw_delivery_performance`

These views support Power BI and Tableau reporting across sales, delivery, seller, product, customer, and order performance.

The views have different grains. Order-level measures should not be summed from item-level records, and delivery metrics should be calculated at order grain.

## 8. Known Source Limitations

- Geolocation ZIP prefixes are not unique.
- Some order lifecycle timestamps are missing.
- Some order timestamps have inconsistent chronological sequences.
- Some product attributes are missing or nonpositive.
- Review IDs repeat across different orders.
- One delivered order has no associated payment record.
- Four anomalous shipping-limit timestamps extend into 2020.
- The dataset is historical and does not represent current marketplace activity.
- The source data does not contain all information required to calculate complete marketplace profitability.

## 9. Data Usage and Attribution

Raw source CSV files are not included in this repository.

Users reproducing the project should obtain the dataset from its original publisher and follow the applicable license and usage terms.

**Dataset:** Olist Brazilian E-Commerce Public Dataset, published on Kaggle.

This is an independent portfolio project and is not affiliated with or commissioned by Olist.