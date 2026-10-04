# Sales Performance Dashboard

## Project overview
Portfolio project for an e-commerce analyst workflow: synthetic raw transaction lines, quality checks, PostgreSQL transformations, star-schema data, KPI analysis, and a Power BI build specification.

## Business problem and objectives
Management needs a consistent view of revenue, profit, margin, demand, customer, product, regional, and time performance. The project answers total and period-over-period sales questions, identifies leading/weak categories and products, and describes discount/margin patterns.

## Dataset
Original synthetic dataset generated deterministically for this project (seed `20261003`); it is not sourced from a real company or external data. It contains 10,210 order-product lines, 7,000 distinct orders and 600 customers from 2022-01-01 through 2024-12-31. There are 16 products across four categories, four US sales regions, and four payment methods. Raw CSV: `data/raw/ecommerce_sales.csv`. Order ID repeats across lines; the analytic fact grain is one order/product line. Sales are line revenue after discount; profit equals sales minus product cost minus shipping cost.

## Technologies
PostgreSQL 15+, SQL, Power BI Desktop, DAX, CSV, Git. No external Python runtime is needed to use the supplied dataset.

## Workflow
Raw CSV → staging table → quality audit and curated view → customer/product/region/date dimensions and sales fact → SQL analysis → Power BI model and measures → dashboard and business findings.

## SQL analysis
Scripts create the database/staging table, audit and clean rows, build a star schema, and query core KPIs, month/quarter/year trends, YoY growth, regional/category/product performance, customer repeat behavior, and discount bands. Cleaning excludes malformed/impossible required values and deduplicates the order/product grain; raw source is retained. Details are documented in `documentation/project_documentation.md`.

## Power BI dashboard
The proposed one-page executive dashboard contains six KPI cards, monthly revenue/profit trend, regional revenue/profit, category performance, top/bottom product tables, and slicers for year, region, category, subcategory, and product. Exact field mapping and build steps are in `powerbi/dashboard_specification.md`. This package does not include a `.pbix`: Power BI Desktop was not available in this environment.

## KPIs
Total Revenue, Total Profit, Profit Margin %, Total Orders, Total Quantity, Average Order Value, Revenue YoY Growth %, Profit YoY Growth %, Customer Count, and Average Discount %. DAX definitions are in `powerbi/measures.dax`.

## Key findings (computed from the generated raw dataset)
- Total revenue is **$3,015,076.35** and total profit is **$949,797.47**, at **31.5%** profit margin across **7,000** orders; AOV is **$430.73**.
- 2024 revenue was **$1,037,630.90**, **+5.1%** versus 2023.
- **West** is the highest-revenue region (**$871,646.14**).
- **Smartphone** is the highest-revenue product (**$689,808.40**); **Smartphone** has the weakest product margin (**25.7%**).
- **600 of 600** customers placed more than one order (**100.0%** repeat rate).

These are descriptive synthetic-data findings, not claims about a real business; full figures and limitations are in the documentation.

## Project structure
```text
data/raw/ecommerce_sales.csv
data/processed/dataset_profile.txt
sql/01_create_database.sql ... 05_kpi_queries.sql
powerbi/measures.dax
powerbi/dashboard_specification.md
documentation/project_documentation.md
README.md
```

## Setup and run
1. Install PostgreSQL 15+ and create/load a database using scripts in numeric order. From the project root, use `psql -U <user> -f outputs/sql/01_create_database.sql`; load CSV into staging using the documented `\copy` command with `outputs/data/raw/ecommerce_sales.csv` (relative to repository root), then run `02_data_cleaning.sql`, `03_data_transformation.sql`, `04_analysis_queries.sql`, and `05_kpi_queries.sql` in the `sales_performance` database.
2. In Power BI Desktop, connect to PostgreSQL database `sales_performance`, schema `analytics`. Import `fact_sales`, `dim_date`, `dim_product`, `dim_customer`, `dim_region`; follow model instructions and create measures from `powerbi/measures.dax`.
3. Build visuals using `powerbi/dashboard_specification.md`, save as `powerbi/Sales_Performance_Dashboard.pbix`, then refresh to update.
4. Reconcile cards with the KPI query and confirm date slicer interactions.

For CSV-only exploration, Power BI can import the raw file, but the star-schema workflow is reproduced through PostgreSQL.

## Future improvements
Add order-level header data, returns, inventory, channel and acquisition costs, currency handling, a larger/customer-cohort history, automated data-quality logging, and a published, tested PBIX connected to a managed database.
