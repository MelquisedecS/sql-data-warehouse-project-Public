# 📘 Gold Layer — Data Catalog

## 🏆 Overview
The **Gold Layer** is the curated, business-ready data model used for analytics, dashboards, KPIs, and advanced reporting.  
It represents **clean, enriched, and conformed data** organized into:

- **Dimension Tables** → business entities (customers, products, etc.)
- **Fact Tables** → business events and measurable metrics (sales, orders, etc.)

This layer is optimized for BI tools, data modeling, and semantic layer consumption.

## 🎯 Objectives of the Gold Layer
- Provide **consistent business definitions** across the organization  
- Enable **self-service analytics** in tools like Power BI, Tableau, Looker  
- Improve performance with **pre-aggregated, clean structures**  
- Establish a **star-schema model** to support analytical workloads  
- Ensure a **single source of truth** for core business metrics  

## 🗺️ Data Flow Overview
```
         Raw Layer (Raw Data)
                 │
                 ▼
      Silver Layer (Validated, Cleaned,
        Standardized Operational Data)
                 │
                 ▼
     Gold Layer (Business-Ready, Modeled,
        Aggregated & Enriched Tables)
```

## 📐 Entity-Relationship Diagram (ASCII ERD)
```
 ┌──────────────────────┐        ┌─────────────────────┐
 │ gold.dim_customers   │        │   gold.dim_products │
 │──────────────────────│        │─────────────────────│
 │ customer_key (PK)    │        │ product_key (PK)    │
 │ customer_id          │        │ product_id          │
 │ customer_number      │        │ product_number      │
 │ first_name           │        │ product_name        │
 │ last_name            │        │ category_id         │
 │ country              │        │ category            │
 │ marital_status       │        │ subcategory         │
 │ gender               │        │ maintenance         │
 │ birthdate            │        │ cost                │
 │                      │        │ product_line        │
 └───────────┬──────────┘        │ start_date          │
             │                   └─────────┬───────────┘
             │                             │
             ▼                             ▼
                 ┌──────────────────────────┐
                 │     gold.fact_sales      │
                 │──────────────────────────│
                 │ order_number             │
                 │ product_key (FK)         │
                 │ customer_key (FK)        │
                 │ order_date               │
                 │ shipping_date            │
                 │ due_date                 │
                 │ sales_amount             │
                 │ quantity                 │
                 │ price                    │
                 └──────────────────────────┘

```

## 🧱 Dimension Tables

### 🔹 gold.dim_customers
Contains enriched customer demographics and identification attributes.

### 🔹 gold.dim_products
Stores detailed product metadata including classification, pricing, and lifecycle information.

## 💰 Fact Table

### 🔸 gold.fact_sales
Contains transactional sales events linked to products and customers.

## 🧠 How to Use This Layer

### 📊 Business Intelligence
- Build dashboards and KPIs  
- Analyze customer behavior, product performance, and sales trends  
- Create time-series metrics (daily, monthly, quarterly)

### 🔎 Data Analysis
- Run segmentation, cohort analysis, churn models  
- Study product profitability  
- Understand demand and sales distribution

### 🧩 Data Modeling
- Join fact and dimension tables using surrogate keys (`*_key`)  
- Use in semantic layers (DAX models, LookML, dbt exposures)

### ⚙️ Engineering
- Ideal source for data marts or downstream ML features  
- Supports incremental refresh strategies
