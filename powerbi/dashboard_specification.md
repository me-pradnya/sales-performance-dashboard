# Power BI build specification

## Model
Import these PostgreSQL objects from `analytics`: `fact_sales`, `dim_date`, `dim_product`, `dim_customer`, `dim_region`. Rename the imported tables in Power BI to `FactSales`, `Date`, `Product`, `Customer`, and `Region` respectively; rename `Date[full_date]` to `Date[Date]` so the supplied DAX references resolve. Keep the other source column names unchanged. Create one-to-many, single-direction relationships from each dimension to fact: Date[full_date] → FactSales[order_date], Product[product_key] → fact, Customer[customer_key] → fact, Region[region_key] → fact. Use dimension columns in slicers/axes. Mark `dim_date[full_date]` as the date table. Hide surrogate keys and fact foreign keys from report view. Keep order ID as a distinct-count measure, since facts are order lines.

## Measures
Use `powerbi/measures.dax`. Format money measures in the chosen reporting currency (synthetic prices are USD), margin/growth/discount as percentages, and orders/quantity as whole numbers. `SAMEPERIODLASTYEAR` relies on a complete, marked date table. For selected partial-year periods, PY and YoY compare the same selected calendar dates.

## Page: Executive overview
Canvas 16:9, light neutral background, dark navy titles, teal revenue accent, green positive and red negative conditional colors. Header title and last refresh date. Top row: Total Revenue, Total Profit, Profit Margin %, Total Orders, Average Order Value, Revenue YoY Growth %. Middle: monthly revenue line with prior-year comparison; monthly profit line. Bottom left: region revenue and profit clustered bars; bottom center: category revenue/profit horizontal bars; bottom right: top 10 products by revenue and bottom 10 by profit table with margin conditional formatting.

Slicers: Year, Region, Category, Sub-category, Product. Use dropdowns for the long lists and year as a horizontal tile. Enable interactions across visuals. Tooltips should include revenue, profit, margin, orders and quantity. Sort month chronologically by month number/year; use Year-Month for x-axis. Avoid pie charts and maps because the region-level aggregation is better compared with bars.

## Validation in Desktop
Compare total revenue/profit/orders/quantity/AOV/margin to `05_kpi_queries.sql`; select 2023 and 2024 to verify YoY against SQL. Confirm every slicer filters the cards/charts and test a single product/category and multiple years. Verify the Date table relationship is active and no ambiguous or many-to-many relationships exist. Save as `powerbi/Sales_Performance_Dashboard.pbix`.
