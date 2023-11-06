/* Ecommerce Dataset: Exploratory Data Analysis (EDA) and Cohort Analysis in SQL
TheLook is an ecommerce fashion website. Its data set include information about customers, products, orders, logistics, web events, digital marketing compaigns.
Access the dataset here:
https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?q=search&referrer=search&project=sincere-torch-350709 */
-- I) Ad-hoc tasks
-- 1) Total users and total orders each month
WITH a AS (
SELECT user_id,
EXTRACT (YEAR FROM delivered_at) ||"-"|| EXTRACT (MONTH FROM delivered_at) AS time
FROM bigquery-public-data.thelook_ecommerce.orders),
b AS (
SELECT user_id,
CASE
  WHEN LENGTH (time) <7 THEN LEFT (time,5) || "0" || RIGHT (time,1)
  ELSE time
END AS month_year
FROM a),
c AS (
SELECT DISTINCT user_id,
COUNT (order_id) AS orders
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE delivered_at BETWEEN '2019-01-01' AND '2022-12-31'
  AND returned_at IS NULL
GROUP BY user_id)
SELECT b.month_year,
COUNT (c.user_id) AS total_user,
SUM (c.orders) AS total_order
FROM c JOIN b ON c.user_id = b.user_id
WHERE b.month_year IS NOT NULL
GROUP BY b.month_year
ORDER BY b.month_year
/* Insight: Both total users and total orders had a steady growth from 2019 and reached its peak at 2022-11, with 0.91k users and 1.04k orders. After that, 
  both had a significant drop at the beginning of 2023 to 0.16k users and 0.18k orders. It was stable in that range until another drop at 2023-11. */
-- 2: Average order value and total users each month
WITH a AS (
SELECT user_id,
EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS time
FROM bigquery-public-data.thelook_ecommerce.order_items),
b AS (
SELECT user_id,
CASE
  WHEN LENGTH (time) <7 THEN LEFT (time,5) || "0" || RIGHT (time,1)
  ELSE time
END AS month_year
FROM a)
SELECT
b.month_year,
COUNT (DISTINCT c.user_id) AS distinct_users,
ROUND (SUM (c.sale_price)/COUNT(DISTINCT c.order_id),2) AS average_order_value
FROM bigquery-public-data.thelook_ecommerce.order_items AS c
JOIN b ON c.user_id=b.user_id
WHERE month_year BETWEEN '2019-01' AND '2022-04'
GROUP BY b.month_year
ORDER BY b.month_year
/* Insight: */
-- 3: Customer in each age group
/* Insight: */
-- 4: Top 5 products each month
WITH d AS (
SELECT product_id, EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS time
FROM bigquery-public-data.thelook_ecommerce.order_items),
e AS (
SELECT product_id, CASE WHEN LENGTH (time) <7 THEN LEFT (time,5) || "0" || RIGHT (time,1) ELSE time END AS month_year
FROM d),
c AS
(SELECT id, retail_price-cost AS profit 
FROM bigquery-public-data.thelook_ecommerce.products),
a AS (
SELECT DISTINCT b.id, e.month_year,
COUNT (*) OVER (PARTITION BY b.id, e.month_year) AS sales
FROM bigquery-public-data.thelook_ecommerce.order_items AS b
JOIN e ON b.id=e.product_id),
i AS (
SELECT a.month_year, a.id AS product_id,
g.name AS product_name, a.sales, g.cost, c.profit*a.sales AS profit
FROM bigquery-public-data.thelook_ecommerce.products AS g
JOIN bigquery-public-data.thelook_ecommerce.order_items AS h ON g.id=h.product_id
JOIN a ON a.id=g.id
JOIN c ON c.id=a.id
WHERE h.status = "Complete"),
ranking AS (
SELECT month_year, product_id, product_name, sales, cost, profit,
DENSE_RANK () OVER (PARTITION BY month_year ORDER BY profit DESC) AS rank_per_month
FROM i)
SELECT month_year, product_id, product_name, sales, cost, profit, rank_per_month
FROM ranking
WHERE rank_per_month IN (1,2,3,4,5)
GROUP BY month_year, product_id, product_name, sales, cost, profit, rank_per_month
ORDER BY month_year, rank_per_month
-- 5: Revenue for each product category
WITH a AS (
SELECT product_id, order_id,
EXTRACT (DATE FROM delivered_at) AS time
FROM bigquery-public-data.thelook_ecommerce.order_items
WHERE status = "Complete"
AND delivered_at BETWEEN "2022-01-15" AND "2022-04-15"),
b AS (
SELECT a.time, o.product_id,
SUM (CASE
  WHEN o.status = "Complete" THEN 1
  ELSE 0 
END) AS total_sales
FROM bigquery-public-data.thelook_ecommerce.order_items AS o
JOIN a ON a.product_id=o.product_id
GROUP BY a.time, o.product_id)
SELECT b.time, b.product_id,
b.total_sales*p.retail_price AS rev
FROM bigquery-public-data.thelook_ecommerce.products AS p
JOIN b ON b.product_id=p.id
GROUP BY b.time, b.product_id, b.total_sales, p.retail_price
