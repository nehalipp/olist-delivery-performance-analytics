
# Olist E-Commerce Analytics

An end-to-end Business Intelligence project analyzing e-commerce sales, delivery performance, seller operations, product performance, and customer experience using the Olist Brazilian E-Commerce Public Dataset.

## Project Overview

E-commerce marketplace performance extends beyond sales. Businesses need visibility into order fulfillment, delivery reliability, seller performance, customer purchasing behavior, and customer satisfaction to understand overall marketplace operations.

This project uses the Olist Brazilian E-Commerce Public Dataset to develop an analytical solution that integrates transactional and operational data into a structured reporting environment.

The solution follows an end-to-end Business Intelligence workflow, covering data preparation, data quality assessment, SQL-based transformation, dimensional modeling, KPI development, and interactive reporting.

## Business Objectives

- Analyze order volume and sales performance over time
- Evaluate delivery performance against estimated delivery dates
- Identify geographic patterns in delivery delays
- Assess seller and product category performance
- Understand customer purchasing and repeat-order behavior
- Examine customer review patterns alongside delivery outcomes
- Develop consistent business metrics for operational and executive reporting

## Analytical Scope

The project covers the following business areas:

| Business Area | Analytical Focus |
|---|---|
| Sales Performance | Order trends, sales value, and product contribution |
| Delivery Operations | Fulfillment timelines, on-time delivery, and delays |
| Geographic Analysis | Customer and seller distribution, regional performance |
| Seller Performance | Seller contribution and delivery outcomes |
| Product Performance | Product and category sales contribution |
| Customer Analytics | Repeat purchasing and customer activity |
| Customer Experience | Review scores and delivery outcomes |
| Payments | Payment methods, installments, and transaction values |

## Technology Stack

| Technology | Purpose |
|---|---|
| PostgreSQL | Data storage and analytical warehouse |
| SQL | Data profiling, transformation, modeling, and analysis |
| Python | Supporting data preparation and quality checks |
| Power BI | Interactive business intelligence reporting |
| Tableau | Data visualization and analytical reporting |
| Git and GitHub | Version control and project documentation |

## Data Architecture

The project follows a layered analytical architecture.

```text
Olist Source Datasets
        |
        v
PostgreSQL Staging
        |
        v
Data Transformation
        |
        v
Dimensional Warehouse
        |
        v
Analytical Views
        |
        +-------------+
        |             |
        v             v
     Power BI      Tableau
```

The architecture separates source ingestion, transformation, dimensional modeling, and reporting to support consistent metrics and reliable analytical outputs.

## Repository Structure

```text
olist-delivery-performance-analytics/
|
|-- data/
|   |-- raw/
|   |-- processed/
|
|-- docs/
|   |-- business_requirements.md
|   |-- data_sources.md
|   |-- data_model.md
|   |-- data_quality_report.md
|   |-- executive_summary.md
|
|-- sql/
|   |-- 01_create_schemas.sql
|   |-- 02_create_staging.sql
|   |-- 03_create_dimensions.sql
|   |-- 04_create_facts.sql
|   |-- 05_analytical_views.sql
|   |-- 06_validation_queries.sql
|
|-- src/
|-- notebooks/
|-- powerbi/
|-- tableau/
|
|-- README.md
|-- requirements.txt
|-- .gitignore
```

## Project Documentation

| Document | Description |
|---|---|
| [Business Requirements](docs/business_requirements.md) | Business objectives, analytical questions, and project scope |
| [Data Sources](docs/data_sources.md) | Dataset inventory, source characteristics, and data grain |
| [Data Model](docs/data_model.md) | Database architecture, dimensional model, and modeling decisions |
| [Data Quality Report](docs/data_quality_report.md) | Data profiling findings, validation results, and quality treatments |
| [Executive Summary](docs/executive_summary.md) | Business context, analytical approach, and key findings |

## Dataset

**Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains historical Brazilian marketplace data, including orders, customers, sellers, products, payments, reviews, and geolocation information.

The project uses the publicly available source datasets for independent analytical and educational purposes.

Original source CSV files are excluded from this repository. Users wishing to reproduce the project should obtain the dataset from its original publisher and comply with its applicable licensing and usage terms.

## Project Considerations and Limitations

- The analysis is based on historical marketplace data and does not represent current business performance.
- Source data may contain missing values, inconsistent timestamps, and incomplete product attributes.
- Analytical metrics must account for the grain of the underlying data to avoid duplicated measures.
- Geographic ZIP-code prefixes are not necessarily unique geographic identifiers.
- Observed relationships between operational performance and customer reviews do not establish causation.
- The dataset does not provide all information required to calculate complete marketplace profitability.

## Attribution

Dataset: Olist Brazilian E-Commerce Public Dataset, published by Olist on Kaggle.

This is an independent portfolio project and is not affiliated with or commissioned by Olist.
