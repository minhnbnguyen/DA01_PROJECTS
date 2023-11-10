-- Part 2 of project 2. In this part, I performed cohort analysis to give further insights into the company's business. 
CREATE VIEW bigquery-public-data.thelook_ecommerce.vw_ecommerce_analyst AS
-- Calculate Total order, total revenue, total profit and total cost
WITH cte1 AS (
SELECT
FORMAT_DATE('%Y-%m', DATE (a.created_at)) AS month_year, EXTRACT (YEAR FROM a.created_at) AS year,
c.category AS product_category, (SUM (b.sale_price) - SUM (c.cost)) AS TPV,
COUNT (a.order_id) AS TPO, SUM (c.cost) AS total_cost,
((SUM (b.sale_price) - SUM (c.cost)) - SUM (c.cost)) AS total_profit
FROM bigquery-public-data.thelook_ecommerce.orders AS a 
JOIN bigquery-public-data.thelook_ecommerce.order_items AS b
ON a.order_id=b.order_id
JOIN bigquery-public-data.thelook_ecommerce.products AS c
ON b.product_id=c.id
GROUP BY FORMAT_DATE('%Y-%m', DATE (a.created_at)), c.category, EXTRACT (YEAR FROM a.created_at))
-- CREATE view table with revenue growth, order growth, profit to cost ratio
SELECT month_year, year, product_category, TPV, TPO,
100*(TPV - LAG (TPV) OVER (PARTITION BY product_category ORDER BY month_year ASC))/(TPV + LAG (TPV) OVER (PARTITION BY product_category ORDER BY month_year ASC)) ||'%' AS revenue_growth,
100*(TPO - LAG (TPO) OVER (PARTITION BY product_category ORDER BY month_year ASC))/(TPO + LAG (TPO) OVER (PARTITION BY product_category ORDER BY month_year ASC)) ||'%' AS order_growth,
total_cost, total_profit, total_profit/cte1.total_cost AS profit_to_cost_ratio
FROM cte1
-- Cohort Chart 
WITH thelook_index AS (
SELECT user_id, first_purchase_date, day,
(EXTRACT (YEAR FROM day) - EXTRACT (YEAR FROM first_purchase_date))*12+(EXTRACT (MONTH FROM day) - EXTRACT (MONTH FROM first_purchase_date)) + 1 AS index
FROM (
SELECT user_id, FIRST_VALUE (created_at) OVER (PARTITION BY user_id ORDER BY created_at) AS first_purchase_date,
LEAD (created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS day
FROM bigquery-public-data.thelook_ecommerce.orders)c)
SELECT FORMAT_DATE('%Y-%m-%d', DATE (first_purchase_date)) AS cohort_date, index, COUNT (DISTINCT user_id) AS cnt,
FROM thelook_index
GROUP BY first_purchase_date, index
HAVING index <=3
