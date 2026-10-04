-- Core business KPIs.
SELECT SUM(sales) revenue,SUM(profit) profit,COUNT(DISTINCT order_id) orders,SUM(quantity) quantity,
 SUM(sales)/NULLIF(COUNT(DISTINCT order_id),0) average_order_value, SUM(profit)/NULLIF(SUM(sales),0) profit_margin
FROM analytics.fact_sales;
-- Monthly and quarterly revenue/profit trends.
SELECT d.year,d.month,d.month_name,SUM(f.sales) revenue,SUM(f.profit) profit FROM analytics.fact_sales f JOIN analytics.dim_date d ON d.full_date=f.order_date GROUP BY d.year,d.month,d.month_name ORDER BY d.year,d.month;
SELECT d.year,d.quarter,SUM(f.sales) revenue,SUM(f.profit) profit FROM analytics.fact_sales f JOIN analytics.dim_date d ON d.full_date=f.order_date GROUP BY d.year,d.quarter ORDER BY d.year,d.quarter;
-- Year-over-year revenue; compare same calendar month with prior year.
WITH m AS (SELECT date_trunc('month',order_date)::date month_start,SUM(sales) revenue FROM analytics.fact_sales GROUP BY 1)
SELECT month_start,revenue,LAG(revenue,12) OVER(ORDER BY month_start) prior_year_revenue,
 (revenue/NULLIF(LAG(revenue,12) OVER(ORDER BY month_start),0))-1 yoy_growth FROM m ORDER BY month_start;
-- Revenue/profit by region, category, and subcategory.
SELECT r.region,SUM(f.sales) revenue,SUM(f.profit) profit,SUM(f.profit)/NULLIF(SUM(f.sales),0) margin FROM analytics.fact_sales f JOIN analytics.dim_region r USING(region_key) GROUP BY r.region ORDER BY revenue DESC;
SELECT p.category,p.sub_category,SUM(f.sales) revenue,SUM(f.profit) profit FROM analytics.fact_sales f JOIN analytics.dim_product p USING(product_key) GROUP BY p.category,p.sub_category ORDER BY revenue DESC;
-- Product leaders and low-margin products.
SELECT p.product_id,p.product_name,SUM(f.sales) revenue,SUM(f.profit) profit,SUM(f.profit)/NULLIF(SUM(f.sales),0) margin FROM analytics.fact_sales f JOIN analytics.dim_product p USING(product_key) GROUP BY p.product_id,p.product_name ORDER BY revenue DESC LIMIT 10;
SELECT p.product_id,p.product_name,SUM(f.sales) revenue,SUM(f.profit) profit,SUM(f.profit)/NULLIF(SUM(f.sales),0) margin FROM analytics.fact_sales f JOIN analytics.dim_product p USING(product_key) GROUP BY p.product_id,p.product_name ORDER BY profit ASC LIMIT 10;
-- Customer value and repeat customers (orders are distinct header IDs).
WITH c AS (SELECT customer_key,COUNT(DISTINCT order_id) orders,SUM(sales) revenue FROM analytics.fact_sales GROUP BY customer_key) SELECT d.customer_id,d.customer_name,c.orders,c.revenue FROM c JOIN analytics.dim_customer d USING(customer_key) ORDER BY revenue DESC;
SELECT COUNT(*) FILTER(WHERE orders>1) repeat_customers,COUNT(*) total_customers,COUNT(*) FILTER(WHERE orders>1)::numeric/NULLIF(COUNT(*),0) repeat_rate FROM (SELECT customer_key,COUNT(DISTINCT order_id) orders FROM analytics.fact_sales GROUP BY customer_key) c;
-- Discount bands; association is descriptive and not causal.
SELECT CASE WHEN discount_pct=0 THEN '0%' WHEN discount_pct<=.05 THEN '1-5%' WHEN discount_pct<=.10 THEN '6-10%' WHEN discount_pct<=.20 THEN '11-20%' ELSE '>20%' END discount_band,COUNT(*) lines,SUM(sales) revenue,SUM(profit) profit,SUM(profit)/NULLIF(SUM(sales),0) margin FROM analytics.fact_sales GROUP BY 1 ORDER BY 1;
