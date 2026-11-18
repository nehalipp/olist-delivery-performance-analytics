
# Data Model and Warehouse Design

## 1. Status

This document describes the intended analytical data model.

The dimensional warehouse has not yet been implemented. Final table definitions, relationships, and diagrams will be updated after transformation and fact-table validation.

## 2. Database Architecture

The planned PostgreSQL architecture contains four schemas.

| Schema | Purpose |
|---|---|
| staging | Source-aligned imported data |
| transform | Standardized fields, derived attributes, and data-quality flags |
| warehouse | Dimensional fact and dimension tables |
| analytics | Reporting views and BI-facing datasets |

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

## 3. Fact Table Design

Two primary fact tables are planned.

### 3.1 fact_orders

**Grain:** One row per order.

Intended analysis:

- Order counts and status.
- Purchase and approval timestamps.
- Carrier and customer-delivery timestamps.
- Estimated delivery date.
- Delivery duration.
- On-time and late-delivery outcomes.
- Order-level payment and review measures, where aggregation rules are defined.

### 3.2 fact_order_items

**Grain:** One row per order item, identified by (`order_id`, `order_item_id`).

Intended analysis:

- Item sales value.
- Freight value.
- Product performance.
- Seller performance.
- Product category contribution.

Order-level values must not be repeated across order-item rows and then summed.

## 4. Planned Dimensions

The initial dimension candidates are:

### dim_date

Calendar attributes for relevant business dates.

### dim_customer

Customer record attributes and customer geography.

### dim_product

Product attributes and translated product category.

### dim_seller

Seller attributes and seller geography.

Additional dimensions should be introduced only when they support a clear analytical requirement.

## 5. Source Key Considerations

### Customer Identifiers

- `customer_id` identifies the customer record associated with an order.
- `customer_unique_id` identifies the customer across potentially multiple customer records and orders.
- Do not assume `customer_unique_id` is unique in the customer source table.

### Geolocation

`geolocation_zip_code_prefix` is not unique.

Multiple geographic records can share the same ZIP prefix. It must not be treated as a unique primary key or arbitrarily reduced to one coordinate without a documented selection or aggregation rule.

### Reviews

`review_id` repeats across different orders.

It must not be treated as a unique source key, and review records must not be deduplicated solely on that field.

## 6. Grain and Fan-Out Controls

- Keep `fact_orders` at one row per order.
- Keep `fact_order_items` at one row per order item.
- Aggregate payment records to order grain before joining to an order-level fact when required.
- Define an explicit review aggregation rule before joining reviews to an order-level fact.
- Avoid joining raw payment, review, and order-item tables together without controlling their respective grains.
- Validate fact-table row counts and measure totals after joins.

## 7. Candidate Business Measures

- Order count.
- Item sales value.
- Freight value.
- Payment value.
- Delivered-order count.
- On-time delivery rate.
- Late-delivery count and rate.
- Delivery duration.
- Average review score.
- Repeat-customer order count.

Final KPI definitions, filters, and denominators will be documented separately before dashboard development.

## 8. Data Quality Integration

The transformation layer should retain data-quality indicators.

Invalid timestamp sequences should be identifiable. Delivery-duration calculations should exclude invalid or incomplete timestamp sequences rather than silently treating them as valid.

Missing product categories should be represented as `Unknown` in reporting while preserving the original source value.

## 9. Implementation Checklist

- [ ] Confirm transformation table grains and data types.
- [ ] Confirm dimension keys and relationships.
- [ ] Implement and validate `fact_orders`.
- [ ] Implement and validate `fact_order_items`.
- [ ] Validate payment aggregation logic.
- [ ] Validate review aggregation logic.
- [ ] Test for fan-out and duplicated measures.
- [ ] Update this document with implemented schema definitions.
- [ ] Add a final warehouse relationship diagram.
