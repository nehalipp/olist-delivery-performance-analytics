
# Data Sources

## 1. Source Overview

This project uses the Olist Brazilian E-Commerce Public Dataset, published by Olist on Kaggle.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains historical Brazilian marketplace transactions and related customer, seller, product, payment, review, and geographic information.

The original CSV files are stored locally in `data/raw/` and are excluded from Git.

## 2. Dataset Inventory

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

| Source Table | Grain / Identifier |
|---|---|
| Customers | One record per `customer_id` |
| Geolocation | Multiple records may share a ZIP prefix |
| Order Items | One record per order item |
| Order Payments | One record per payment sequence within an order |
| Order Reviews | Source review record; `review_id` is not unique |
| Orders | One record per `order_id` |
| Category Translation | One record per Portuguese category |
| Products | One record per `product_id` |
| Sellers | One record per `seller_id` |

## 4. Geographic and Time Coverage

The dataset represents Brazilian e-commerce activity from 2016 through 2018.

Date coverage for specific analyses should be determined from the relevant source timestamp field rather than assumed from the dataset publication date.

## 5. Import Approach

All nine source datasets were imported into PostgreSQL schema `staging`.

The staging columns were defined as `TEXT` to preserve the original source representations during ingestion.

Data-type conversion, standardization, and quality validation are intended to occur in the transformation layer.

## 6. Known Source Limitations

- Geolocation ZIP prefixes are not unique.
- Some order lifecycle timestamps are missing.
- Some order timestamps have inconsistent chronological sequences.
- Some product attributes are missing or nonpositive.
- Review IDs repeat across different orders.
- The dataset is historical and does not represent current marketplace activity.

## 7. Data Usage

Raw source CSV files are not included in this repository.

Users reproducing the project should obtain the dataset from its original publisher and follow the applicable license and usage terms.
