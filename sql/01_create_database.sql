-- PostgreSQL 15+; execute in a database where you have CREATE DATABASE privileges.
CREATE DATABASE sales_performance;
\connect sales_performance
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE TABLE IF NOT EXISTS analytics.stg_sales_raw (
 order_id text, order_date_text text, customer_id text, customer_name text,
 region text, state text, city text, category text, sub_category text,
 product_id text, product_name text, quantity_text text, unit_price_text text,
 discount_pct_text text, sales_text text, unit_cost_text text, cost_text text,
 profit_text text, shipping_cost_text text, payment_method text
);
-- Load data/raw/ecommerce_sales.csv (header present) with psql\copy:
-- \copy analytics.stg_sales_raw FROM 'data/raw/ecommerce_sales.csv' WITH (FORMAT csv, HEADER true);
