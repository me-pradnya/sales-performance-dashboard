-- Quality audit: review these before loading curated data. No raw row is silently changed.
SELECT COUNT(*) AS raw_rows, COUNT(*) FILTER (WHERE order_id IS NULL OR btrim(order_id)='') AS missing_order_id,
 COUNT(*) FILTER (WHERE order_date_text !~ '^\d{4}-\d{2}-\d{2}$') AS malformed_dates,
 COUNT(*) FILTER (WHERE quantity_text !~ '^\d+$' OR quantity_text::integer <= 0) AS invalid_quantity,
 COUNT(*) FILTER (WHERE sales_text !~ '^\d+(\.\d{1,2})?$' OR profit_text !~ '^-?\d+(\.\d{1,2})?$') AS invalid_money,
 COUNT(*) - COUNT(DISTINCT (order_id, product_id)) AS duplicate_order_product_rows
FROM analytics.stg_sales_raw;
-- Reject malformed core values and impossible quantity/discount/amount inputs from curated model.
-- Duplicate grain is order_id + product_id; exact duplicate rows are excluded by DISTINCT ON.
CREATE OR REPLACE VIEW analytics.vw_sales_clean AS
WITH parsed AS (SELECT *, to_date(order_date_text,'YYYY-MM-DD') AS order_date,
 NULLIF(btrim(region),'') AS region_clean, NULLIF(btrim(category),'') AS category_clean,
 NULLIF(btrim(sub_category),'') AS sub_category_clean,
 NULLIF(btrim(product_name),'') AS product_name_clean,
 quantity_text::integer AS quantity, unit_price_text::numeric(12,2) AS unit_price,
 discount_pct_text::numeric(5,4) AS discount_pct, sales_text::numeric(14,2) AS sales,
 unit_cost_text::numeric(12,2) AS unit_cost, cost_text::numeric(14,2) AS cost,
 profit_text::numeric(14,2) AS profit, shipping_cost_text::numeric(12,2) AS shipping_cost
FROM analytics.stg_sales_raw
WHERE order_id IS NOT NULL AND order_date_text ~ '^\d{4}-\d{2}-\d{2}$'
 AND quantity_text ~ '^\d+$' AND unit_price_text ~ '^\d+(\.\d{1,2})?$'
 AND discount_pct_text ~ '^\d+(\.\d{1,4})?$' AND sales_text ~ '^\d+(\.\d{1,2})?$'
 AND unit_cost_text ~ '^\d+(\.\d{1,2})?$' AND cost_text ~ '^\d+(\.\d{1,2})?$'
 AND profit_text ~ '^-?\d+(\.\d{1,2})?$' AND shipping_cost_text ~ '^\d+(\.\d{1,2})?$'),
 dedup AS (SELECT DISTINCT ON(order_id,product_id) * FROM parsed
 ORDER BY order_id,product_id,ctid)
SELECT * FROM dedup WHERE order_date IS NOT NULL AND order_date::text=order_date_text AND quantity>0
 AND discount_pct BETWEEN 0 AND 1 AND sales>=0 AND cost>=0 AND shipping_cost>=0
 AND region_clean IS NOT NULL AND category_clean IS NOT NULL AND product_name_clean IS NOT NULL;
-- Reconciliation checks: raw eligible lines, curated lines, and recalculated arithmetic variance.
SELECT COUNT(*) AS curated_rows, SUM(sales) AS revenue, SUM(profit) AS profit,
 COUNT(DISTINCT order_id) AS orders, SUM(quantity) AS units,
 COUNT(*) FILTER (WHERE abs(sales - round(unit_price*quantity*(1-discount_pct),2)) > .02) AS sales_variance_rows,
 COUNT(*) FILTER (WHERE abs(profit - (sales-cost-shipping_cost)) > .02) AS profit_variance_rows
FROM analytics.vw_sales_clean;
