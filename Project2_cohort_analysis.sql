WITH rev_order AS (
SELECT
FORMAT_DATE('%Y-%m', DATE (a.created_at)) AS month_year,
(SUM (b.sale_price) - SUM (c.cost)) AS TPV,
COUNT (a.order_id) AS TPO,
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
100*(revenue - LAG (revenue) OVER (ORDER BY month_year ASC))/(revenue + LAG (revenue) OVER (ORDER BY month_year ASC)) ||'%' AS revenue_growth,
100*(orders - LAG (orders) OVER (ORDER BY month_year ASC))/((orders + LAG (orders) OVER (ORDER BY month_year ASC))) ||'%' AS order_growth
FROM rev_order),
-- Calculate total profit
profit AS (
SELECT revenue,
(revenue - total_cost) AS total_profit
FROM rev_order),
-- Calculate profit to cost ratio
ptc AS (
SELECT revenue/total_profit AS profit_to_cost_ratio
FROM profit)
-- create dataset
SELECT rev_order.month_year, EXTRACT (YEAR FROM a.created_at), c.category AS product_category, rev_order.TPV, rev_order.TPO,
growth.revenue_growth, growth.order_growth, profit.total_profit, ptc.profit_to_cost_ratio
