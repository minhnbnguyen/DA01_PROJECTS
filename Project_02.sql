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
/* Conclusion: Both total users and total orders had a steady growth from 2019
and reached its peak at 2022-11, with 0.91k users and 1.04k orders. After that,
both had a significant drop at the beginning of 2023 to 0.16k users and 0.18k orders.
It was stable in that range until another drop at 2023-11. */
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
/* Conclusion: total distinct users and AOV experienced steady growth and reached 
its peak at 2023-10 (9.21k distinct users and 0.18k AOV), then plummeted
*/
-- 3: Customer in each age group
WITH a AS (
SELECT first_name, last_name, gender, age,
CASE
  WHEN age = (SELECT MAX (age) FROM bigquery-public-data.thelook_ecommerce.users)
  THEN "oldest"
  WHEN age = (SELECT MIN (age) FROM bigquery-public-data.thelook_ecommerce.users)
  THEN "youngest"
  ELSE NULL
END AS tag
FROM bigquery-public-data.thelook_ecommerce.users
WHERE created_at BETWEEN "2019-01-01" AND "2022-04-30"),
oldest AS (
SELECT age,
SUM (CASE WHEN tag = "oldest" THEN 1 ELSE 0 END) AS total
FROM a
WHERE tag = "oldest"
GROUP BY age),
youngest AS (
SELECT age,
SUM (CASE WHEN tag = "youngest" THEN 1 ELSE 0 END) AS total
FROM a
WHERE tag = "youngest"
GROUP BY age)
SELECT age, total FROM oldest
UNION ALL
SELECT age, total FROM youngest
-- 4: Top 5 items each month
WITH d AS (
SELECT product_id, EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS time
FROM bigquery-public-data.thelook_ecommerce.order_items),
e AS (
SELECT product_id, CASE WHEN LENGTH (time) <7 THEN LEFT (time,5) || "0" || RIGHT (time,1) ELSE time END AS month_year
FROM d),
c AS
(SELECT id, retail_price-cost AS profit 
FROM bigquery-public-data.thelook_ecommerce.products)
SELECT e.month_year, b.product_id, a.name AS product_name,
COUNT (b.inventory_item_id) AS sales,
a.cost, c.profit
FROM bigquery-public-data.thelook_ecommerce.products AS a
JOIN bigquery-public-data.thelook_ecommerce.order_items AS b ON a.id=b.product_id
JOIN c ON a.id=c.id
JOIN e ON a.id=e.product_id
WHERE b.status = "Complete"
GROUP BY b.product_id, a.name, a.cost, c.profit, e.month_year),
i AS (
SELECT product_id, profit*sales OVER (PARTITION BY product_id) AS total_profit
FROM h)
SELECT h.month_year, h.product_id, h.product_name, h.sales, h.cost, i.total_profit,
DENSE_RANK () OVER (PARTITION BY h.month_year ORDER BY i.total_profit DESC) AS rank_per_month
FROM i JOIN h ON i.product_id=h.product_id
GROUP BY h.month_year, h.product_id, h.product_name, h.sales, h.cost, i.total_profit
ORDER BY DENSE_RANK () OVER (PARTITION BY h.month_year ORDER BY i.total_profit DESC)
-- 5: Doanh thu tinh toi hien tai tren moi danh muc
