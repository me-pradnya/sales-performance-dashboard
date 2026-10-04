# Project documentation

## Objective and business requirements
Analyze simulated e-commerce performance across revenue, profit, margin, orders, units, customers, regions, categories, products, discounts and date. Provide an explainable analyst workflow and reusable management dashboard specification.

## Dataset description and assumptions
The CSV is project-generated synthetic data using a fixed random seed, not a real-world external dataset. It has 10,210 lines, 7,000 orders, 600 customers, 16 products, four categories, four regions, years 2022–2024. An order can contain multiple products, so the line grain is order ID plus product ID. `sales` is quantity × unit price × (1 − discount), rounded to cents. `cost` is quantity × unit cost; `profit` = sales − cost − shipping cost. Reporting currency is assumed USD. There are no returns, taxes, refunds or inventory records.

## Cleaning decisions
`01_create_database.sql` stages source columns as text so parsing can be audited. `02_data_cleaning.sql` reports null identifiers, malformed date formats, invalid quantities/money, and repeated order/product pairs before building a curated view. It excludes malformed required numeric/date inputs, nonpositive quantities, discounts outside 0–100%, negative sales/cost/shipping, missing key labels, and duplicate order/product pairs (keeping the first stable source row). Missing optional subcategory/payment values are labeled `Unspecified`/`Unknown` downstream. The raw CSV is never overwritten. Review quality-audit counts and arithmetic reconciliation output before using the model. In this generated fixture, source values are complete and valid by construction; exact duplicate grain count should be zero.

## SQL transformations and model
Dialect is PostgreSQL 15+. Staging and cleaning view are followed by `dim_customer`, `dim_product`, `dim_region`, `dim_date`, and `fact_sales`. Fact grain is one order/product line. Date dimension covers the complete three-year range, including days without sales. Surrogate keys connect fact to dimensions; order ID remains a degenerate order identifier used for distinct order counting. The fact refresh truncates and reloads to avoid duplicated rows. Analysis includes aggregate KPIs, month/quarter trends, a 12-month lag for comparable monthly YoY, annual YoY, regional/category/product results, customer repeat behavior and discount-band profitability.

## DAX measures and time intelligence
Definitions are in `powerbi/measures.dax`. Orders are `DISTINCTCOUNT(order_id)` over line facts; AOV is revenue divided by distinct orders. Margin is total profit divided by total revenue (weighted), not an average of line margins. Prior-year measures use `SAMEPERIODLASTYEAR` over the marked, continuous date dimension; divide-by-zero returns blank via `DIVIDE`. Current Year measures use `DATESYTD` and obey report filter context.

## Dashboard design
See `powerbi/dashboard_specification.md` for relationships, slicers, visuals, formatting and Desktop QA. One executive page prioritizes KPI scanability, trend context, region/category comparison and top/bottom product detail.

## Analytical questions and evidence-based findings
- Revenue: $3,015,076.35; profit: $949,797.47; margin: 31.50%; orders: 7,000; AOV: $430.73; quantity: 19,389.
- Year revenue: 2022 $990,239.61; 2023 $987,205.84; 2024 $1,037,630.90; 2024 YoY: +5.11%.
- Highest revenue region: West, $871,646.14; region profit $274,084.97.
- Highest revenue product: Smartphone, $689,808.40. Lowest product margin: Smartphone, 25.70% (revenue $689,808.40, profit $177,314.28).
- Repeat customers: 600/600 = 100.00%.
- Discounted lines total margin 27.93% versus undiscounted 36.38%; descriptive association only, not evidence discounts cause margin changes.

## Limitations
Synthetic patterns are illustrative and cannot support real-world decisions. The dataset models line-level orders and estimated shipping costs; it omits returns, cancellations, tax, customer acquisition cost and stock-outs. No PBIX is generated or Desktop-validated in this environment. SQL and DAX are supplied as reproducible implementation assets; runtime validation requires PostgreSQL and Power BI Desktop.

## Setup
Follow README setup instructions and run SQL scripts sequentially. Import the five analytics tables into Power BI, create the four dimension-to-fact relationships, mark Date, add DAX measures, build visuals, compare cards with KPI SQL and test slicers and YoY before publishing.
