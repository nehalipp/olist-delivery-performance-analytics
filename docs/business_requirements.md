
# Business Requirements

## 1. Project Background

Olist is a Brazilian e-commerce marketplace that connects merchants with customers. Marketplace performance depends on several connected processes, including customer orders, seller fulfillment, transportation, payment processing, and customer feedback.

This project uses Olist's historical marketplace dataset to analyze commercial and operational performance through a structured Business Intelligence solution.

## 2. Business Problem

Sales metrics alone do not provide a complete picture of marketplace performance.

Businesses also need to understand:

- Whether orders are delivered within the promised timeframe
- Which sellers and product categories contribute to marketplace activity
- Where delivery delays are concentrated
- How customer purchasing behavior changes over time
- Whether delivery outcomes are associated with customer review scores

The objective is to combine transactional and operational data to support these analyses through consistent reporting.

## 3. Business Objectives

1. Analyze order volume and revenue trends over time.
2. Measure delivery performance against estimated delivery dates.
3. Identify geographic patterns in delivery delays.
4. Evaluate seller and product performance.
5. Understand customer purchasing frequency and repeat-order behavior.
6. Analyze customer review scores alongside delivery outcomes.

## 4. Stakeholders and Analytical Requirements

| Stakeholder | Information Required |
|---|---|
| Executive Leadership | Order volume, revenue trends, and delivery performance |
| Operations Teams | Delivery delays, fulfillment timelines, and geographic bottlenecks |
| Seller Management | Seller order volume, sales contribution, and delivery performance |
| Product / Category Teams | Product and category sales contribution |
| Customer Experience Teams | Review scores and customer feedback patterns |
| BI / Data Teams | Consistent KPI definitions and reliable reporting datasets |

These are intended stakeholder perspectives for the portfolio project, not actual Olist project sponsors.

## 5. Business Questions

### 5.1 Commercial Performance

- How does order volume change over time?
- What is the total item sales value?
- Which product categories contribute the most sales?
- How do payment methods and installment patterns vary?

### 5.2 Delivery Performance

- What percentage of delivered orders arrive on or before the estimated date?
- How many days late are orders delivered?
- Which states and cities experience higher delivery delays?
- Which sellers have higher late-delivery rates?

### 5.3 Customer Behavior

- How many customers place multiple orders?
- How does customer purchasing activity change over time?
- How do review scores vary across delivery outcomes?
- Are late deliveries associated with lower customer review scores?

### 5.4 Seller and Product Performance

- Which sellers contribute the most order items and sales?
- Which product categories generate the highest sales?
- How does freight value vary across products and regions?

## 6. Scope

### Included

- Order transactions and lifecycle timestamps
- Order items, prices, and freight values
- Payment records
- Customer information
- Seller information
- Product attributes and category translations
- Customer reviews
- Geolocation information

### Excluded

- Marketing funnel analysis
- Live marketplace monitoring
- Predictive modeling
- Production deployment
- External enrichment datasets unless separately justified

## 7. Data and Modeling Requirements

- Each fact table must have a clearly defined grain.
- Order-level and order-item-level measures must remain distinct.
- Payment records must be aggregated appropriately before joining to order-level data.
- Review records must be handled using an explicit aggregation rule.
- `customer_unique_id` must be used appropriately to identify customers across orders.
- ZIP-code prefixes must not be treated as unique geographic keys.
- Source values must be preserved, with data-quality handling documented separately.
- KPI formulas and denominators must be documented before dashboard development.

## 8. Assumptions and Limitations

- The source dataset represents historical Brazilian marketplace activity.
- Some order timestamps and product attributes contain missing or inconsistent values.
- Delivery metrics must exclude invalid or incomplete timestamp sequences where appropriate.
- Review scores and delivery outcomes can be compared descriptively, but correlation does not establish causation.
- The dataset does not contain all information required to calculate complete marketplace profitability.

## 9. Expected Deliverables

1. Source-data profiling and quality assessment
2. PostgreSQL staging and transformation layers
3. Dimensional warehouse
4. Analytical SQL views
5. Documented KPI definitions
6. Power BI dashboards
7. Tableau dashboards
8. Final business findings and recommendations
