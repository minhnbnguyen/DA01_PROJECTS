/* Ecommerce Dataset: Exploratory Data Analysis (EDA) and Cohort Analysis in SQL
TheLook is an ecommerce fashion website. Its data set include information about*/
-- I) Ad-hoc tasks
-- 1) Total users and total orders each month
WITH a AS (
SELECT user_id,
EXTRACT (YEAR FROM shipped_at) ||"-"|| EXTRACT (MONTH FROM shipped_at) AS time
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
GROUP BY user_id)
SELECT b.month_year,
COUNT (c.user_id) AS total_user,
SUM (c.orders) AS total_order
FROM c JOIN b ON c.user_id = b.user_id
WHERE b.month_year IS NOT NULL
GROUP BY b.month_year
ORDER BY b.month_year
/* Conclusion: Both total users and total orders had a steady growth from 2019
and reached its peak at 2022-11, with 1.36k users and 1.64k orders. After that,
both had a significant drop at the beginning of 2023 to 0.34k users and 0.45k orders.
It was stable in that range until another drop at 2023-11. */
