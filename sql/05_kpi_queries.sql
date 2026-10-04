-- Single-row KPI extract for reconciliation to Power BI cards.
SELECT SUM(sales) AS total_revenue,SUM(profit) AS total_profit,
 COUNT(DISTINCT order_id) AS total_orders,SUM(quantity) AS total_quantity,
 SUM(sales)/NULLIF(COUNT(DISTINCT order_id),0) AS average_order_value,
 SUM(profit)/NULLIF(SUM(sales),0) AS profit_margin,COUNT(DISTINCT customer_key) AS customer_count,
 AVG(discount_pct) AS average_discount FROM analytics.fact_sales;
-- Annual comparison with safe zero handling.
WITH y AS (SELECT extract(year FROM order_date)::int year,SUM(sales) revenue,SUM(profit) profit FROM analytics.fact_sales GROUP BY 1), z AS (SELECT *,LAG(revenue) OVER(ORDER BY year) prev_revenue,LAG(profit) OVER(ORDER BY year) prev_profit FROM y) SELECT *,revenue/NULLIF(prev_revenue,0)-1 yoy_revenue_growth,profit/NULLIF(prev_profit,0)-1 yoy_profit_growth FROM z ORDER BY year;
