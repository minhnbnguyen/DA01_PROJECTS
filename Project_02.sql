/* Ecommerce Dataset: Exploratory Data Analysis (EDA) and Cohort Analysis in SQL
TheLook is an ecommerce fashion website. Its data set include information about customers, products, orders, logistics, web events, digital marketing compaigns.
Access the dataset here:
https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?q=search&referrer=search&project=sincere-torch-350709 */
-- I) Ad-hoc tasks
-- 1) Total users and total orders each month
SELECT
EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS month_year,
COUNT (order_id) AS total_order,
COUNT (DISTINCT user_id) As total_user
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE created_at BETWEEN '2019-01-01' AND '2022-04-30'
AND status = "Complete"
GROUP BY 1
ORDER BY 1
/* Insight: Both total users and total orders had a steady growth over the months and soared over the last months of the year and then plummeted in the first months --> High demand at the year end */
-- 2) Average Order Value and total users each month
-- Total orders and customers each month
WITH a AS (
SELECT
EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS month_year,
COUNT (DISTINCT user_id) AS total_user,
COUNT (order_id) AS total_order
FROM bigquery-public-data.thelook_ecommerce.orders
WHERE DATE (created_at) BETWEEN '2019-01-01' AND '2022-04-30'
GROUP BY 1
ORDER BY 1),
-- Total or sale per month
b AS (
SELECT
EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS month_year,
SUM (sale_price) AS sum
FROM bigquery-public-data.thelook_ecommerce.order_items
WHERE DATE (created_at) BETWEEN '2019-01-01' AND '2022-04-30'
GROUP BY 1)
-- AOV and total user each month
SELECT a.month_year,
b.sum/a.total_order AS average_order_value,
a.total_user AS distinct_users
FROM a JOIN b ON a.month_year=b.month_year
ORDER BY 1
/* Insight: Both AOV had a steady growth over the months and soared over the last months of the year and then plummeted in the first months --> High demand at the year end*/
-- 3: Customer in each age group
-- Find the smallest age and largest age for ech gender
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
/* Insight: The youngest customer age is 12 with 1175 users. The oldest age is 70 with 1129 users*/
-- 4: Top 5 products each month
WITH d AS (
SELECT product_id, EXTRACT (YEAR FROM created_at) ||"-"|| EXTRACT (MONTH FROM created_at) AS time
FROM bigquery-public-data.thelook_ecommerce.order_items),
e AS (
SELECT product_id, CASE WHEN LENGTH (time) <7 THEN LEFT (time,5) || "0" || RIGHT (time,1) ELSE time END AS month_year
FROM d),
c AS
(SELECT p.id, o.sale_price-p.cost AS profit 
FROM bigquery-public-data.thelook_ecommerce.products AS p
JOIN bigquery-public-data.thelook_ecommerce.order_items AS o
ON p.id=o.product_id
GROUP BY p.id,o.sale_price, p.cost),
a AS (
SELECT DISTINCT b.id, e.month_year,
COUNT (b.order_id) OVER (PARTITION BY b.id, e.month_year) AS total_order
FROM bigquery-public-data.thelook_ecommerce.order_items AS b
JOIN e ON b.id=e.product_id),
i AS (
SELECT a.month_year, a.id AS product_id,
g.name AS product_name, h.sale_price AS sale, g.cost, c.profit*a.total_order AS profit
FROM bigquery-public-data.thelook_ecommerce.products AS g
JOIN bigquery-public-data.thelook_ecommerce.order_items AS h ON g.id=h.product_id
JOIN a ON a.id=g.id
JOIN c ON c.id=a.id
WHERE h.status = "Complete"),
ranking AS (
SELECT month_year, product_id, product_name, sale, cost, profit,
DENSE_RANK () OVER (PARTITION BY month_year ORDER BY profit DESC) AS rank_per_month
FROM i)
SELECT month_year, product_id, product_name, sale, cost, profit, rank_per_month
FROM ranking
WHERE rank_per_month IN (1,2,3,4,5)
GROUP BY month_year, product_id, product_name, sale, cost, profit, rank_per_month
ORDER BY month_year, rank_per_month
-- 5: Revenue for each product category (haven't finished)
SELECT *
FROM (
SELECT 
DATE(a.created_at) as dates ,
b.category as product_categories,
SUM(a.sale_price) OVER (PARTITION BY b.category ORDER BY DATE(a.created_at)) AS revenue
FROM bigquery-public-data.thelook_ecommerce.order_items a
LEFT JOIN bigquery-public-data.thelook_ecommerce.products b
ON a.product_id = b.id
)
WHERE DATE_DIFF(DATE '2022-04-15',dates, DAY) BETWEEN 0 AND 90
GROUP BY dates,product_categories, revenue
ORDER BY dates
