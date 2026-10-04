-- Build a simple star schema; this script can be rerun. IDs remain stable source keys.
CREATE TABLE IF NOT EXISTS analytics.dim_customer (customer_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, customer_id text UNIQUE NOT NULL, customer_name text NOT NULL);
CREATE TABLE IF NOT EXISTS analytics.dim_product (product_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, product_id text UNIQUE NOT NULL, product_name text NOT NULL, category text NOT NULL, sub_category text NOT NULL);
CREATE TABLE IF NOT EXISTS analytics.dim_region (region_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, region text NOT NULL, state text NOT NULL, city text NOT NULL, UNIQUE(region,state,city));
CREATE TABLE IF NOT EXISTS analytics.dim_date (date_key integer PRIMARY KEY, full_date date UNIQUE NOT NULL, year integer NOT NULL, quarter integer NOT NULL, month integer NOT NULL, month_name text NOT NULL, year_month text NOT NULL);
CREATE TABLE IF NOT EXISTS analytics.fact_sales (sales_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, order_id text NOT NULL, order_date date NOT NULL REFERENCES analytics.dim_date(full_date), customer_key bigint NOT NULL REFERENCES analytics.dim_customer, product_key bigint NOT NULL REFERENCES analytics.dim_product, region_key bigint NOT NULL REFERENCES analytics.dim_region, quantity integer NOT NULL CHECK(quantity>0), unit_price numeric(12,2) NOT NULL, discount_pct numeric(5,4) NOT NULL, sales numeric(14,2) NOT NULL, cost numeric(14,2) NOT NULL, profit numeric(14,2) NOT NULL, shipping_cost numeric(12,2) NOT NULL, payment_method text NOT NULL);
INSERT INTO analytics.dim_customer(customer_id,customer_name) SELECT DISTINCT customer_id,customer_name FROM analytics.vw_sales_clean WHERE customer_id IS NOT NULL ON CONFLICT(customer_id) DO UPDATE SET customer_name=excluded.customer_name;
INSERT INTO analytics.dim_product(product_id,product_name,category,sub_category) SELECT DISTINCT product_id,product_name_clean,category_clean,COALESCE(sub_category_clean,'Unspecified') FROM analytics.vw_sales_clean ON CONFLICT(product_id) DO UPDATE SET product_name=excluded.product_name,category=excluded.category,sub_category=excluded.sub_category;
INSERT INTO analytics.dim_region(region,state,city) SELECT DISTINCT region_clean,state,city FROM analytics.vw_sales_clean ON CONFLICT(region,state,city) DO NOTHING;
INSERT INTO analytics.dim_date(date_key,full_date,year,quarter,month,month_name,year_month) SELECT to_char(d,'YYYYMMDD')::integer,d,extract(year from d)::integer,extract(quarter from d)::integer,extract(month from d)::integer,to_char(d,'FMMonth'),to_char(d,'YYYY-MM') FROM generate_series('2022-01-01'::date,'2024-12-31'::date,'1 day') d ON CONFLICT(full_date) DO NOTHING;
-- Fact insert idempotency: remove then reload to avoid duplicating rows on refresh.
TRUNCATE analytics.fact_sales RESTART IDENTITY;
INSERT INTO analytics.fact_sales(order_id,order_date,customer_key,product_key,region_key,quantity,unit_price,discount_pct,sales,cost,profit,shipping_cost,payment_method)
SELECT s.order_id,s.order_date,c.customer_key,p.product_key,r.region_key,s.quantity,s.unit_price,s.discount_pct,s.sales,s.cost,s.profit,s.shipping_cost,COALESCE(s.payment_method,'Unknown')
FROM analytics.vw_sales_clean s JOIN analytics.dim_customer c USING(customer_id) JOIN analytics.dim_product p USING(product_id)
JOIN analytics.dim_region r ON r.region=s.region_clean AND r.state=s.state AND r.city=s.city;
CREATE INDEX IF NOT EXISTS ix_fact_sales_date ON analytics.fact_sales(order_date);
CREATE INDEX IF NOT EXISTS ix_fact_sales_order ON analytics.fact_sales(order_id);
