/* 
Clauses and flow of writing queries in SQL:

SELECT -> FROM -> WHERE -> GROUP BY -> HAVING -> ORDER BY
*/

-- =====================================================================================
-- SELECT CLAUSE
-- =====================================================================================

SELECT * 
FROM fact_sales_monthly;

SELECT * 
FROM fact_forecast_monthly;

SELECT * 
FROM dim_customer;

SELECT * 
FROM dim_product;

SHOW TABLES;

-- Select specific columns
SELECT 
    customer_code, 
    sold_quantity
FROM fact_sales_monthly;

-- =====================================================================================
-- WHERE CLAUSE
-- =====================================================================================

SELECT 
    customer_code, 
    sold_quantity
FROM fact_sales_monthly
WHERE sold_quantity > 5000;

-- =====================================================================================
-- ORDER BY CLAUSE
-- Top 10 sold quantities
-- =====================================================================================

SELECT 
    customer_code, 
    sold_quantity
FROM fact_sales_monthly
ORDER BY sold_quantity DESC
LIMIT 10;

-- =====================================================================================
-- AGGREGATE FUNCTIONS (BUILT-IN)
-- =====================================================================================

SELECT MAX(sold_quantity) 
FROM fact_sales_monthly;

SELECT MIN(sold_quantity) 
FROM fact_sales_monthly;

SELECT AVG(sold_quantity) 
FROM fact_sales_monthly;

/*
If we add customer_code along with an aggregate function directly,
MySQL will give logically incorrect results because grouping is missing.
*/

SELECT 
    customer_code, 
    AVG(sold_quantity) 
FROM fact_sales_monthly;

-- Correct way using GROUP BY
SELECT 
    customer_code,  
    SUM(sold_quantity) AS qty
FROM fact_sales_monthly
GROUP BY customer_code
ORDER BY qty DESC;

-- =====================================================================================
-- SUBQUERIES
-- =====================================================================================

-- Highest sold quantity
SELECT MAX(sold_quantity) 
FROM fact_sales_monthly;

SELECT * 
FROM fact_sales_monthly
WHERE sold_quantity = (
    SELECT MAX(sold_quantity) 
    FROM fact_sales_monthly
);

-- Lowest sold quantity
SELECT MIN(sold_quantity) 
FROM fact_sales_monthly;

SELECT * 
FROM fact_sales_monthly
WHERE sold_quantity = (
    SELECT MIN(sold_quantity) 
    FROM fact_sales_monthly
);

-- Subquery returning a single value ( = )
SELECT * 
FROM dim_customer
WHERE customer_code = (
    SELECT customer_code
    FROM fact_sales_monthly
    WHERE sold_quantity = (
        SELECT MAX(sold_quantity) 
        FROM fact_sales_monthly
    )
);

-- Subquery returning a list of values ( IN )
SELECT * 
FROM dim_customer
WHERE customer_code IN (
    SELECT customer_code
    FROM fact_sales_monthly
    WHERE sold_quantity = (
        SELECT MIN(sold_quantity) 
        FROM fact_sales_monthly
    )
);

-- =====================================================================================
-- JOINS
-- =====================================================================================

-- INNER JOIN
SELECT * 
FROM fact_sales_monthly s
INNER JOIN dim_customer c
    ON s.customer_code = c.customer_code;

-- LEFT JOIN
SELECT * 
FROM fact_sales_monthly s
LEFT JOIN dim_customer c
    ON s.customer_code = c.customer_code;

-- RIGHT JOIN
SELECT * 
FROM fact_sales_monthly s
RIGHT JOIN dim_customer c
    ON s.customer_code = c.customer_code;

-- UNION of Left + Right Join
SELECT * 
FROM fact_sales_monthly s
LEFT JOIN dim_customer c
    ON s.customer_code = c.customer_code

UNION

SELECT * 
FROM fact_sales_monthly s
RIGHT JOIN dim_customer c
    ON s.customer_code = c.customer_code
LIMIT 10;

-- Multi-table join
SELECT * 
FROM fact_sales_monthly s
JOIN dim_customer c USING (customer_code)
JOIN dim_product p USING (product_code)
LIMIT 10;

-- =====================================================================================
-- GROUP BY with Joins
-- =====================================================================================

-- Names of customers with aggregated quantities
SELECT
    customer_code,
    SUM(sold_quantity) AS qty,
    c.customer
FROM fact_sales_monthly s
JOIN dim_customer c USING (customer_code)
GROUP BY customer_code
ORDER BY qty DESC;

-- Specific year filter
SELECT
    s.date,
    customer_code,
    SUM(sold_quantity) AS qty,
    c.customer
FROM fact_sales_monthly s
JOIN dim_customer c USING (customer_code)
WHERE YEAR(date) = 2021
GROUP BY customer_code
ORDER BY qty DESC;

-- =====================================================================================
-- HAVING CLAUSE (used for aggregated filter)
-- =====================================================================================

/*
WHERE cannot be applied to aggregated values.
So we use HAVING for conditions on aggregated results.
*/

SELECT
    s.date,
    customer_code,
    SUM(sold_quantity) AS qty,
    c.customer
FROM fact_sales_monthly s
JOIN dim_customer c USING (customer_code)
WHERE YEAR(date) = 2020
GROUP BY customer_code
HAVING qty > 500000   -- 5 lakhs
ORDER BY qty DESC;



-- =====================================================================================
-- But this looks too complex 
-- we need some simple readable query 

-- =====================================================================================

-- COMMON TABLE EXPRESSIONS (CTE) , scope - 1 query
-- Temporary result usable only in the same query 
-- =====================================================================================

WITH abc AS (
    SELECT
        s.date,
        c.customer,
        customer_code,
        SUM(sold_quantity) AS qty
    FROM fact_sales_monthly s
    JOIN dim_customer c USING (customer_code)
    WHERE YEAR(date) = 2020
    GROUP BY customer_code
)
SELECT * 
FROM abc
WHERE qty > 500000; -- 5 lakhs

-- =====================================================================================
-- STORED PROCEDURE (Returns a result table)

-- now if we want to have a UI type of functionality , where we want 

-- lets create a stored procedure
-- stored procedure return a table 
-- =====================================================================================

/*
CREATE DEFINER=`root`@`localhost` PROCEDURE `yearandqty`(
    IN yearr YEAR,
    IN qtyy INT
)
BEGIN
    WITH abc AS (
        SELECT
            s.date,
            c.customer,
            customer_code,
            SUM(sold_quantity) AS qty
        FROM fact_sales_monthly s
        JOIN dim_customer c USING (customer_code)
        WHERE YEAR(date) = yearr
        GROUP BY customer_code
    )
    SELECT * 
    FROM abc
    WHERE qty > qtyy;
END;
*/

-- =====================================================================================
-- VIEW + SALES vs FORECAST DIFFERENCE

-- if we want to use this table for future purposes
-- and add it as a temp table in our db
-- we can make a VIEW


# we want to see the difference between our forecasted sales and actual sales
-- =====================================================================================

SELECT * 
FROM fact_sales_monthly;

SELECT * 
FROM fact_forecast_monthly;

SELECT * 
FROM fact_sales_monthly s
JOIN fact_forecast_monthly f
USING (date, product_code, customer_code);

-- After creating a view named fact_sales_forecast_monthly:
SELECT *, 
       (CAST(sold_quantity AS SIGNED) - CAST(forecast_quantity AS SIGNED)) AS diff
FROM fact_sales_forecast_monthly;

-- =====================================================================================
-- FUNCTIONS (Built-in vs User-Defined)

-- dont you think it will be great if we 
-- have a own function like get fiscal year

-- so we have 2 type of functions 
-- 1) Built in and 
-- 2) user defined or custome

-- lets make one 

-- =====================================================================================

SELECT * 
FROM fact_forecast_monthly
WHERE fiscal_year = 2021;

SELECT * 
FROM fact_sales_monthly
WHERE YEAR(date) = 2021;

SELECT DATE_ADD('2021-09-01', INTERVAL 4 MONTH);

SELECT YEAR(DATE_ADD('2021-09-01', INTERVAL 4 MONTH));

-- Custom function example usage:
SELECT * 
FROM fact_sales_monthly
WHERE get_fy(date) = 2021;
