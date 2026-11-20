
# Olist E-Commerce Analytics

An end-to-end Business Intelligence portfolio project analyzing the Olist Brazilian E-Commerce Public Dataset using PostgreSQL, SQL, Power BI, and Tableau.

The project examines sales performance, order fulfillment, delivery reliability, seller and product activity, and customer experience.

## 1. Project Overview

E-commerce marketplace performance extends beyond sales. Businesses need visibility into order fulfillment, delivery reliability, seller performance, customer purchasing behavior, and customer satisfaction to understand overall marketplace operations.

This project develops a structured analytical solution using historical Olist marketplace data.

The workflow covers:

- Source data ingestion and profiling
- Data quality assessment
- SQL-based data transformation
- Dimensional data modeling
- Fact-table development
- Analytical reporting views
- Business KPI development
- Power BI and Tableau reporting

The PostgreSQL data foundation has been implemented and validated. Dashboard development is the next phase.

## 2. Business Objectives

The project is designed to support the following business questions:

- How do order volume and item sales change over time?
- What proportion of delivered orders arrive after their estimated delivery dates?
- Which states and regions contribute the most orders and sales?
- Which sellers contribute the most sales and order volume?
- Which product categories generate the highest item sales?
- How does customer purchasing activity vary across the marketplace?
- What patterns exist between delivery outcomes and customer review scores?
- Which payment methods and installment patterns are most common?

## 3. Analytical Scope

| Business Area | Analytical Focus |
|---|---|
| Executive Overview | Marketplace order volume, item sales, delivery, and customer KPIs |
| Sales Performance | Order trends, item sales, freight, and product contribution |
| Delivery Operations | Fulfillment timelines, on-time delivery, and delays |
| Geographic Analysis | Customer and seller distribution by state and city |
| Seller Performance | Seller contribution, order volume, and delivery outcomes |
| Product Performance | Product and category sales contribution |
| Customer Analytics | Customer activity and repeat purchasing |
| Customer Experience | Review scores and delivery outcomes |
| Payments | Payment methods, installments, and payment values |

## 4. Technology Stack

| Technology | Purpose |
|---|---|
| PostgreSQL | Data staging, transformation, and dimensional warehouse |
| SQL | Data profiling, transformation, validation, and analytical views |
| Power BI | Interactive dashboards and DAX-based KPI reporting |
| Tableau | Analytical dashboards and visual exploration |
| Git and GitHub | Version control and project documentation |

## 5. Data Architecture

The project follows a layered analytical architecture.

```text
Olist Source CSV Files
        |
        v
PostgreSQL Staging
        |
        v
SQL Transformation
        |
        v
Dimensional Warehouse
        |
        v
Analytics Reporting Views
        |
        +----------------+
        |                |
        v                v
     Power BI         Tableau
```

The PostgreSQL database contains four schemas:

| Schema | Purpose |
|---|---|
| staging | Preserves imported source records |
| transform | Standardizes fields, converts data types, and creates quality flags |
| warehouse | Stores dimensional tables and fact tables |
| analytics | Provides reporting-ready analytical views |

## 6. Warehouse Design

The dimensional warehouse contains four dimensions and two fact tables.

### Dimensions

| Dimension | Grain | Rows |
|---|---|---:|
| dim_date | One row per calendar date | 1,314 |
| dim_customer | One row per customer record | 99,441 |
| dim_product | One row per product | 32,951 |
| dim_seller | One row per seller | 3,095 |

### Fact Tables

| Fact Table | Grain | Rows |
|---|---|---:|
| fact_orders | One row per order | 99,441 |
| fact_order_items | One row per order item | 112,650 |

Payment and review records are aggregated to order grain before being incorporated into `fact_orders`.

This prevents multiple payment or review records from multiplying order-level measures.

The separate order and order-item facts preserve their respective grains. Item sales and freight remain at item grain, while payment and delivery measures remain at order grain.

See [Data Model and Warehouse Design](docs/data_model.md) for the detailed schema and modeling decisions.

## 7. Analytics Reporting Views

Six reporting views have been implemented in the PostgreSQL `analytics` schema.

| View | Grain | Purpose |
|---|---|---|
| vw_order_performance | One row per order | Order status, customer, payment, review, and lifecycle analysis |
| vw_sales_performance | One row per order item | Item sales, freight, product, seller, customer, and order analysis |
| vw_customer_performance | One row per customer record | Customer order activity, payment value, reviews, and item sales |
| vw_product_performance | One row per product | Product and category sales performance |
| vw_seller_performance | One row per seller | Seller sales, order volume, and delivery outcomes |
| vw_delivery_performance | One row per order | Delivery timelines, delays, and timestamp quality |

These views provide reporting-ready datasets for Power BI and Tableau.

**Important:** The views have different grains. Do not combine or aggregate their measures without considering the underlying grain. In particular:

- Do not sum order-level payment totals from an item-level dataset.
- Calculate delivery metrics at order grain.
- Keep item sales, freight, total item value, and payment value as separate measures.

## 8. Repository Structure

```text
olist-delivery-performance-analytics/
|
|-- docs/
|   |-- business_requirements.md
|   |-- data_model.md
|   |-- data_quality_report.md
|   |-- data_sources.md
|   |-- executive_summary.md
|
|-- sql/
|   |-- 01_create_schemas.sql
|   |-- 02_create_staging.sql
|   |-- 03_create_dimensions.sql
|   |-- 04_create_facts.sql
|   |-- 05_create_analytics_views.sql
|   |
|   |-- transform/
|   |   |-- 01_transform_orders.sql
|   |   |-- 02_transform_customers.sql
|   |   |-- 03_transform_products.sql
|   |   |-- 04_transform_sellers.sql
|   |   |-- 05_transform_order_items.sql
|   |   |-- 06_transform_payments.sql
|   |   |-- 07_transform_reviews.sql
|   |   |-- 08_transform_geolocation.sql
|   |
|   |-- validation/
|       |-- 01.1_validate_orders.sql
|       |-- 01.2_validate_customers.sql
|       |-- 01.3_validate_products.sql
|       |-- 01.4_validate_sellers.sql
|       |-- 01.5_validate_order_items.sql
|       |-- 01.6_validate_payments.sql
|       |-- 01.7_validate_reviews.sql
|       |-- 01.8_validate_geolocation.sql
|       |-- 02_validate_dimensions.sql
|       |-- 03_validate_facts.sql
|       |-- 04_validate_analytics_view.sql
|
|-- .gitignore
|-- README.md
|-- requirements.txt
```

Raw source CSV files and dashboard files are not included in the current repository.

## 9. Project Documentation

| Document | Description |
|---|---|
| [Business Requirements](docs/business_requirements.md) | Business objectives, analytical questions, and project scope |
| [Data Sources](docs/data_sources.md) | Dataset inventory, source characteristics, and table grain |
| [Data Model](docs/data_model.md) | Database architecture, dimensional model, and modeling decisions |
| [Data Quality Report](docs/data_quality_report.md) | Data profiling findings, validation results, and quality treatments |
| [Executive Summary](docs/executive_summary.md) | Business context, implemented solution, validated metrics, and project status |

## 10. Dataset

**Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains historical Brazilian marketplace data, including:

- Customers
- Geolocation
- Orders
- Order items
- Payments
- Reviews
- Products
- Product category translations
- Sellers

The nine source datasets contain a combined 1,650,922 records.

Original source CSV files are excluded from this repository. Users wishing to reproduce the project should obtain the dataset from its original publisher and comply with its applicable licensing and usage terms.

## 11. Setup and Execution

The following sequence describes how to reproduce the PostgreSQL data foundation.

### Prerequisites

- PostgreSQL
- A PostgreSQL client such as pgAdmin or another SQL editor
- The nine Olist source CSV files
- Git, if cloning the repository

### Step 1: Obtain the Source Data

Download the Olist Brazilian E-Commerce Public Dataset from:

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Keep the source CSV files locally. They are not committed to this repository.

### Step 2: Create the Database

Create a PostgreSQL database for the project.

For example:

```sql
CREATE DATABASE olist_analytics;
```

Connect your SQL client to the new database before executing the project scripts.

### Step 3: Create Schemas

Run:

```text
sql/01_create_schemas.sql
```

This creates the schemas used by the project.

### Step 4: Create Staging Tables

Run:

```text
sql/02_create_staging.sql
```

This creates the staging tables for the nine source datasets.

### Step 5: Import the CSV Files

Import each source CSV into its corresponding staging table.

| CSV Dataset | PostgreSQL Staging Table |
|---|---|
| olist_customers_dataset.csv | staging.customers_raw |
| olist_geolocation_dataset.csv | staging.geolocation_raw |
| olist_order_items_dataset.csv | staging.order_items_raw |
| olist_order_payments_dataset.csv | staging.order_payments_raw |
| olist_order_reviews_dataset.csv | staging.order_reviews_raw |
| olist_orders_dataset.csv | staging.orders_raw |
| product_category_name_translation.csv | staging.product_category_translation_raw |
| olist_products_dataset.csv | staging.products_raw |
| olist_sellers_dataset.csv | staging.sellers_raw |

The staging columns are defined as `TEXT` to preserve the source representations during ingestion.

Verify the imported row counts against [Data Quality Assessment](docs/data_quality_report.md) before proceeding.

### Step 6: Run the Transformation Scripts

Execute the eight SQL transformation scripts in numerical order:

```text
sql/transform/01_transform_orders.sql
sql/transform/02_transform_customers.sql
sql/transform/03_transform_products.sql
sql/transform/04_transform_sellers.sql
sql/transform/05_transform_order_items.sql
sql/transform/06_transform_payments.sql
sql/transform/07_transform_reviews.sql
sql/transform/08_transform_geolocation.sql
```

These scripts create the cleaned and standardized tables in the `transform` schema.

### Step 7: Run Source Transformation Validation

Execute the validation scripts in `sql/validation/`:

```text
01.1_validate_orders.sql
01.2_validate_customers.sql
01.3_validate_products.sql
01.4_validate_sellers.sql
01.5_validate_order_items.sql
01.6_validate_payments.sql
01.7_validate_reviews.sql
01.8_validate_geolocation.sql
```

Review the results and compare them with the documented findings in [Data Quality Assessment](docs/data_quality_report.md).

### Step 8: Create the Dimensions

Run:

```text
sql/03_create_dimensions.sql
```

This creates and populates:

- `warehouse.dim_date`
- `warehouse.dim_customer`
- `warehouse.dim_product`
- `warehouse.dim_seller`

### Step 9: Validate the Dimensions

Run:

```text
sql/validation/02_validate_dimensions.sql
```

Confirm the dimension row counts, business-key uniqueness, and date coverage.

### Step 10: Create the Fact Tables

Run:

```text
sql/04_create_facts.sql
```

This creates and populates:

- `warehouse.fact_orders`
- `warehouse.fact_order_items`

Payment and review records are aggregated to order grain before loading the order fact.

### Step 11: Validate the Fact Tables

Run:

```text
sql/validation/03_validate_facts.sql
```

Review row counts, business-key uniqueness, foreign-key completeness, and financial reconciliation.

### Step 12: Create the Analytics Views

Run:

```text
sql/05_create_analytics_views.sql
```

This creates the six reporting views in the `analytics` schema.

### Step 13: Validate the Analytics Views

Run:

```text
sql/validation/04_validate_analytics_view.sql
```

Confirm reporting-view row counts, distinct business keys, and financial reconciliation.

## 12. Rebuild Considerations

The dimension creation script rebuilds dimension tables. The fact tables contain foreign-key references to those dimensions.

If you need to rebuild the warehouse after fact tables have already been created, do not rerun the dimension script in isolation.

Rebuild the warehouse in dependency order:

1. Clear or drop the existing fact tables.
2. Recreate and populate the dimensions.
3. Recreate and populate the fact tables.
4. Recreate the analytics views.
5. Rerun warehouse and analytics validation.

For a complete rebuild, use a fresh project database or carefully remove dependent tables in the correct order.

## 13. Project Considerations and Limitations

- The analysis is based on historical marketplace data and does not represent current business performance.
- Source data contains missing values, inconsistent timestamps, and incomplete product attributes.
- Analytical metrics must account for the grain of the underlying data to avoid duplicated measures.
- Geographic ZIP-code prefixes are not necessarily unique geographic identifiers.
- Observed relationships between operational performance and customer reviews do not establish causation.
- Item sales, freight, total item value, and payment value are different measures.
- The dataset does not provide all information required to calculate complete marketplace profitability.

## 14. Current Project Status

| Component | Status |
|---|---|
| Source data import | Complete |
| Source data profiling | Complete |
| SQL transformations | Complete |
| Data quality validation | Complete |
| Dimensional warehouse | Complete |
| Fact-table validation | Complete |
| Analytics reporting views | Complete |
| Power BI semantic model and dashboards | Next phase |
| Tableau dashboards | Next phase |

The PostgreSQL data foundation is ready for dashboard development.

## 15. Attribution

Dataset: Olist Brazilian E-Commerce Public Dataset, published on Kaggle.

This is an independent portfolio project and is not affiliated with or commissioned by Olist.
