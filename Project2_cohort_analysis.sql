-- Calculate total revenue & total order & total cost each month
WITH rev_order AS (
SELECT
FORMAT_DATE('%Y-%m', DATE (a.created_at)) AS month_year,
SUM (b.sale_price) - SUM (c.cost) AS revenue,
COUNT (a.order_id) AS orders,
SUM (c.cost) AS total_cost
FROM bigquery-public-data.thelook_ecommerce.orders AS a 
JOIN bigquery-public-data.thelook_ecommerce.order_items AS b
ON a.order_id=b.order_id
JOIN bigquery-public-data.thelook_ecommerce.products AS c
ON b.product_id=c.id
GROUP BY FORMAT_DATE('%Y-%m', DATE (a.created_at))),
-- Calculate revenue growth and order growth
growth AS (
SELECT month_year,
revenue - LAG (revenue) OVER (ORDER BY month_year ASC) AS revenue_growth,
orders - LAG (orders) OVER (ORDER BY month_year ASC) AS order_growth
FROM rev_order),
-- Calculate total profit
total_profit AS (
SELECT revenue,
revenue - total_cost AS total_profit
FROM rev_order)
-- Calculate profit to cost ratio
SELECT revenue/total_profit AS profit_to_cost_ratio
FROM total_profit
