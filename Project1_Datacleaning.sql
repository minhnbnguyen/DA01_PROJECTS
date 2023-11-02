/* In this project, I performed data cleaning for the file sales_data_clea_rfm */
-- Step 1: The raw data are all in VARCHAR. Convert each field into suitable data type
ALTER TABLE sales_dataset_rfm_prj 
  ALTER COLUMN ordernumber TYPE numeric
  USING (ordernumber::numeric);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN quantityordered TYPE smallint
  USING (quantityordered::smallint);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN priceeach TYPE decimal
  USING (priceeach::decimal);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN orderlinenumber TYPE numeric
  USING (quantityordered::numeric);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN sales TYPE decimal
  USING (sales::decimal);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN orderdate TYPE timestamp
  USING (orderdate::timestamp);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN productline TYPE text
  USING (orderdate::text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN status TYPE text
  USING (status::text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN msrp TYPE numeric
  USING (msrp::numeric);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN productcode TYPE char(8)
  USING (productcode::char(8));

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN customername TYPE text
  USING (customername:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN addressline1 TYPE text
  USING (addressline1:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN addressline2 TYPE text
  USING (addressline2:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN city TYPE text
  USING (city:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN state TYPE text
  USING (state:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN country TYPE text
  USING (country:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN territory TYPE text
  USING (territory:: text);

ALTER TABLE sales_dataset_rfm_prj
  ALTER COLUMN contactfullname TYPE text
  USING (contactfullname:: text);

ALTER TABLE sales_dataset_rfm_prj 
  ALTER COLUMN dealsize TYPE text
  USING (dealsize:: text);
-- Step 2: Check NULL/BLANK
SELECT ordernumber, quantityordered, priceeach, orderlinenumber, sales, orderdate
FROM sales_dataset_rfm_prj 
WHERE ordernumber IS NULL
  OR quantityordered IS NULL 
  OR priceeach IS NULL 
  OR orderlinenumber IS NULL
  OR sales IS NULL 
  OR orderdate IS NULL;
-- Step 3: Add contactlastname, contactfirstname from contactfullname. 
ALTER TABLE sales_dataset_rfm_prj
ADD contactfirstname text;

ALTER TABLE sales_dataset_rfm_prj
ADD contactlastname text;

UPDATE sales_dataset_rfm_prj
SET contactfirstname = SUBSTRING (contactfullname FROM POSITION ('-' IN contactfullname)+1);

UPDATE sales_dataset_rfm_prj
SET contactlastname = (contactfullname FROM 1 FOR POSITION ('-' IN contactfullname)-1);

UPDATE sales_dataset_rfm_prj
SET contactfirstname= CONCAT (UPPER (LEFT (contactfirstname,1)),LOWER (RIGHT (contactfirstname,(LENGTH (contactfirstname)-1))));

UPDATE sales_dataset_rfm_prj
SET contactlastname= CONCAT (UPPER (LEFT (contactlastname,1)),LOWER (RIGHT (contactlastname,(LENGTH (contactlastname)-1))));
-- Step 4: Add qtr_id, month_id, year_id from orderdate
ALTER TABLE sales_dataset_rfm_prj
ADD qtr_id numeric;

ALTER TABLE sales_dataset_rfm_prj
ADD month_id numeric;

ALTER TABLE sales_dataset_rfm_prj
ADD year_id numeric;

UPDATE sales_dataset_rfm_prj
SET year_id = EXTRACT (year FROM orderdate);

UPDATE sales_dataset_rfm_prj
SET month_id = EXTRACT (month FROM orderdate);

UPDATE sales_dataset_rfm_prj
SET qtr_id = EXTRACT (quarter FROM orderdate);
-- Step 5: Find the outlier from quantityordered
WITH a AS (
SELECT
percentile_cont (0.25) WITHIN GROUP (ORDER BY quantityordered) AS Q1,
percentile_cont (0.75) WITHIN GROUP (ORDER BY quantityordered) AS Q3,
percentile_cont (0.75) WITHIN GROUP (ORDER BY quantityordered) - percentile_cont (0.25) WITHIN GROUP (ORDER BY quantityordered) AS IQR
FROM sales_dataset_rfm_prj)
SELECT
*
FROM sales_dataset_rfm_prj
WHERE quantityordered < (SELECT MIN (Q1 - 1.5*IQR) FROM a)
OR quantityordered > (SELECT MAX (Q3 + 1.5*IQR) FROM a)
-- Step 6: Clean the outlier
-- Option 1: Delete
DELETE FROM TABLE sales_dataset_rfm_prj
WHERE quantityordered IN (SELECT quantityordered FROM outlier);
-- Option 2: Update with the average quantity
UPDATE sales_dataset_rfm_prj
SET quantityordered = AVG (quantityordered)
WHERE quantityordered IN (SELECT quantityordered FROM outlier);
