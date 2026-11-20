# Executive Summary

## 1. Project Overview

This portfolio project analyzes the Olist Brazilian E-Commerce Public Dataset to examine marketplace sales, order fulfillment, delivery performance, seller and product activity, and customer feedback.

The project demonstrates an end-to-end Business Intelligence workflow using PostgreSQL and SQL. It covers source-data profiling, data quality assessment, data transformation, dimensional modeling, analytical view development, and preparation for interactive reporting in Power BI and Tableau.

The objective is to create a structured analytical solution that allows business users to evaluate commercial performance and operational outcomes using consistent measures.

## 2. Business Objectives

The project is designed to answer business questions across the following areas:

- How do order volume and item sales change over time?
- What proportion of delivered orders arrive after their estimated delivery dates?
- Which states and regions contribute the most orders and sales?
- Which sellers contribute the most sales and order volume?
- Which product categories generate the highest item sales?
- How does customer purchasing activity vary across the marketplace?
- What patterns exist between delivery outcomes and customer review scores?
- Which payment methods and installment patterns are most common?

## 3. Data and Technology

The analysis uses the Olist Brazilian E-Commerce Public Dataset, which contains nine source datasets covering orders, customers, products, sellers, order items, payments, reviews, category translations, and geolocation.

The nine source datasets contain a combined 1,650,922 records.

| Technology | Project Use |
|---|---|
| PostgreSQL | Source staging, transformation, dimensional warehouse, and analytical views |
| SQL | Data profiling, validation, transformation, modeling, and analytical queries |
| Power BI | Planned interactive dashboards and DAX-based KPI reporting |
| Tableau | Planned analytical dashboards and visual exploration |
| Git and GitHub | Version control and project documentation |

## 4. Implemented Data Architecture

The project uses a layered architecture:

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

| Schema | Purpose | Status |
|---|---|---|
| staging | Preserves imported source records | Implemented |
| transform | Standardizes data types and creates quality flags | Implemented |
| warehouse | Stores dimensions and fact tables | Implemented |
| analytics | Provides reporting-ready analytical views | Implemented |

## 5. Warehouse Summary

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

Payment and review records are aggregated to order grain before being incorporated into `fact_orders`. This prevents payment and review records from multiplying order-level measures.

The separate order and order-item facts preserve their respective grains and allow order-level operational measures to be analyzed alongside item-level sales measures.

## 6. Analytical Reporting Layer

Six reporting views have been implemented in the PostgreSQL `analytics` schema.

| Reporting View | Grain | Analytical Purpose |
|---|---|---|
| vw_order_performance | One row per order | Order status, customer, payment, review, and lifecycle analysis |
| vw_sales_performance | One row per order item | Item sales, freight, product, seller, customer, and order analysis |
| vw_customer_performance | One row per customer record | Customer order activity, payment value, reviews, and item sales |
| vw_product_performance | One row per product | Product and category sales performance |
| vw_seller_performance | One row per seller | Seller sales, order volume, and delivery outcomes |
| vw_delivery_performance | One row per order | Delivery timelines, delays, and timestamp quality |

These views provide reporting-ready datasets for Power BI and Tableau.

## 7. Data Quality and Validation

All nine source datasets were imported into PostgreSQL staging tables. Eight table-specific transformation scripts were implemented and validated.

The assessment covered:

- Source row-count reconciliation
- Primary-key and composite-key uniqueness
- Referential integrity
- Missing values and incomplete attributes
- Order lifecycle timestamp consistency
- Payment and review record patterns
- Financial field validation
- Geolocation duplication and coordinate anomalies
- Dimension and fact-table validation
- Analytics view row counts and financial reconciliation

Important findings include:

- 99,441 unique orders were identified.
- 112,650 order-item records were retained.
- 775 orders have no corresponding order-item records and remain available in the order-level fact.
- One delivered order has no associated payment record.
- 610 products have missing source categories and are classified as `Unknown` for English reporting.
- Four anomalous shipping-limit timestamps across three orders were retained and flagged.
- Review IDs repeat across different orders and are not treated as unique identifiers.
- Geolocation ZIP prefixes are not unique and are not used as standalone geographic keys.

Known exceptions were retained, flagged, or documented rather than silently removed.

## 8. Validated Business Measures

The warehouse and analytics views reconcile to the following source-derived totals:

| Measure | Validated Value |
|---|---:|
| Total orders | 99,441 |
| Delivered orders | 96,478 |
| Late delivered orders | 7,826 |
| Total order items | 112,650 |
| Item sales | 13,591,643.70 |
| Freight value | 2,251,909.54 |
| Total item value | 15,843,553.24 |
| Order payment value | 16,008,872.12 |

**Metric definitions matter:**

- Item sales represent the sum of product prices, excluding freight.
- Freight represents the sum of shipping charges.
- Total item value includes item prices and freight.
- Order payment value represents aggregated payment records.
- These measures are not interchangeable.
- The dataset does not provide all information required to calculate complete marketplace profitability.

## 9. Planned BI Reporting

The next phase is dashboard development.

The planned Power BI reporting solution will cover:

1. Executive Overview
2. Sales Performance
3. Delivery Performance
4. Seller Performance
5. Product Performance
6. Customer Experience

The Tableau implementation will provide a focused set of complementary analytical dashboards.

The BI layer will use consistent KPI definitions and respect the grain of the underlying warehouse facts. Order-level payment and delivery measures will remain separate from item-level sales and freight measures.

## 10. Limitations

- The dataset represents historical Brazilian marketplace activity, primarily from 2016 through 2018.
- Some order lifecycle timestamps are missing or have inconsistent chronological sequences.
- Some product attributes are incomplete.
- One delivered order has no associated payment record.
- Geolocation records contain substantial duplication and some geographic inconsistencies.
- ZIP-prefix geography requires additional validation before being used for precise mapping.
- Relationships between delivery outcomes and review scores are descriptive and do not establish causation.
- Complete marketplace profitability cannot be calculated from the available source fields.

## 11. Project Status

The PostgreSQL data foundation is implemented and validated.

| Project Component | Status |
|---|---|
| Source data import | Complete |
| Source data profiling | Complete |
| Data transformation | Complete |
| Data quality validation | Complete |
| Dimensional warehouse | Complete |
| Fact-table validation | Complete |
| Analytics reporting views | Complete |
| Power BI semantic model and dashboards | Next phase |
| Tableau dashboards | Next phase |

The project is ready to move into Power BI and Tableau development. The focus will shift from building the data foundation to defining business KPIs, developing dashboards, and communicating analytical findings.

## 12. Project Attribution

Dataset: Olist Brazilian E-Commerce Public Dataset, published on Kaggle.

This is an independent portfolio project and is not affiliated with or commissioned by Olist.
