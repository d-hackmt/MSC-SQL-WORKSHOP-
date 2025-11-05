/* 
To query we write clauses 

Clauses and flow of writing clauses

SELECT -> FROM -> WHERE -> GROUPBY -> HAVING -> ORDER BY

*/


# SELECT CLAUSE 

SELECT * from fact_sales_monthly;
SELECT * from fact_forecast_monthly;
SELECT * from dim_customer;
SELECT * from dim_product;

show tables;

# select specific columns

SELECT customer_code , sold_quantity 
from fact_sales_monthly ;

# WHERE CLAUSE 

SELECT customer_code , sold_quantity 
from fact_sales_monthly 
where sold_quantity > 5000;


# top 10 sold quantities
## ORDER BY CLAUSE

SELECT customer_code , sold_quantity 
from fact_sales_monthly 
ORDER BY sold_quantity DESC
LIMIT 10;

# highest quanitiy & lowest quantity & Avg
## AGGREGATING FUCNTIONS(BUILT IN) 

SELECT max(sold_quantity) 
from fact_sales_monthly ;

SELECT min(sold_quantity) 
from fact_sales_monthly ;

SELECT avg(sold_quantity) 
from fact_sales_monthly ;

# but if we add customer code as well , it will give wrong results 

SELECT customer_code , avg(sold_quantity) 
from fact_sales_monthly ;

# so lets get right results with GROUP BY
# remember use GROUP BY always with aggregating functions

# which customer_code how many quantities 

SELECT customer_code ,  
SUM(sold_quantity) as qty
from fact_sales_monthly 
group by customer_code
order by qty DESC;

-- --------------------------------------------------------------------------


# which coutomer highest quantities

SELECT customer_code,product_code ,sold_quantity
from fact_sales_monthly
where sold_quantity=5832;

# customer name 
SELECT * from dim_customer
where customer_code = '80007195';


## SUBQUERIES

# SUBQURIES RETURNS A VALUE

SELECT max(sold_quantity) 
from fact_sales_monthly ;

SELECt * from fact_sales_monthly 
where sold_quantity = (
SELECT max(sold_quantity) 
from fact_sales_monthly 
);

SELECT min(sold_quantity) 
from fact_sales_monthly ;

SELECt * from fact_sales_monthly 
where sold_quantity = (
SELECT MIN(sold_quantity) 
from fact_sales_monthly 
);


# SUBQURIES RETURNS A LIST OF VALUES

# which coutomer HIGHESH quantities

SELECT * from dim_customer
where customer_code = (
SELECt customer_code 
from fact_sales_monthly 
where sold_quantity = (
SELECT MIN(sold_quantity) 
from fact_sales_monthly 
)
);

# which coutomer lowest quantities

SELECT * from dim_customer
where customer_code IN (
SELECt customer_code 
from fact_sales_monthly 
where sold_quantity = (
SELECT MIN(sold_quantity) 
from fact_sales_monthly 
)
);


# SUBQURIES RETURNS A TABLE


## lets LEARN JOINS FOR A CHANGE 

# single table 

# inner join by 

SELECT * from fact_sales_monthly s
JOIN dim_customer c
on s.customer_code = c.customer_code;


SELECT * from fact_sales_monthly s
INNER JOIN dim_customer c
on s.customer_code = c.customer_code;

# left join 

SELECT * from fact_sales_monthly s
LEFT JOIN dim_customer c
on s.customer_code = c.customer_code;

# right join 

SELECT * from fact_sales_monthly s
RIGHT JOIN dim_customer c
on s.customer_code = c.customer_code;

## UNION 

SELECT * from fact_sales_monthly s
LEFT JOIN dim_customer c
on s.customer_code = c.customer_code
UNION
SELECT * from fact_sales_monthly s
RIGHT JOIN dim_customer c
on s.customer_code = c.customer_code
LIMIT 10;


# multi table

SELECT * from fact_sales_monthly s
JOIN dim_customer c
on s.customer_code = c.customer_code
JOIN dim_product p 
on s.product_code = p.product_code
LIMIT 10;

# for more join we will need fiscal year
# we will check that later

-- ---------------------------------------------------------------------------------------

# now there are many with lowest quantities
# how to get the names and sold quantities of all the customers
# with 0 sales

SELECT customer_code , product_code , sold_quantity,
customer
from fact_sales_monthly
JOIN dim_customer c 
using (customer_code)
where sold_quantity=0;

-- yea entrie will repeat due to obvious reasons 
--  we are not grouping or aggregating etc

## GROUP BY

# lets get the name of the customers and their top sold qtys 

SELECT customer_code ,  
SUM(sold_quantity) as qty,
c.customer
from fact_sales_monthly s
join dim_customer c
using (customer_code)
group by customer_code
order by qty DESC;


# for specific year

SELECT s.date , customer_code ,  
SUM(sold_quantity) as qty,
c.customer
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = 2021
group by customer_code
order by qty DESC;

# but i only want to see the quantities >  5 lakhs

## HAVING CLAUSE

# but we cant do something like this
# where clause doesnt work on a aggregated or calculated column

SELECT s.date , customer_code ,  
SUM(sold_quantity) as qty,
c.customer
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = 2021
and SUM(sold_quantity) > 500000
group by customer_code
order by qty DESC;

# so we use having when 
# where has already been used once 
# or we want to apply a conditon on aggregated or calculated column


SELECT s.date , customer_code ,  
SUM(sold_quantity) as qty,
c.customer
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = 2020
group by customer_code
having qty >500000 # 5 lakhs 
order by qty DESC;


# But this looks too complex 
## we need some simple readable query 

## COMMON TABLE EXPRESSIONS 
# temp table , scope - 1 query

with abc as 
(
SELECT s.date , c.customer ,
customer_code ,  
SUM(sold_quantity) as qty
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = 2020
group by customer_code
order by qty DESC
)
SELECT * From abc
where qty >500000; # 5 lakhs 

# now if we want to have a UI type of functionality , where we want 

# lets create a stored procedure
# stored procedure return a table 


/*

CREATE DEFINER=`root`@`localhost` PROCEDURE `yearandqty`(
	IN yearr year,
    IN qtyy INT
)
BEGIN

with abc as 
(
SELECT s.date , c.customer ,
customer_code ,  
SUM(sold_quantity) as qty
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = yearr
group by customer_code
order by qty DESC
)
SELECT * From abc
where qty > qtyy;

END

*/

# function returns a calculated column 



-- ---------------------------------------------------------------------------------

# lets look at other tables 

SELECT * from fact_sales_monthly;
SELECT * from fact_forecast_monthly;

# we want to see the difference between our forecasted sales and actual sales

SELECt * from fact_sales_monthly s
JOIN fact_forecast_monthly f
USING (date,product_code,customer_code);


-- if we want to use this table for future purposes
-- and add it as a temp table in our db
-- we can make a VIEW


# view is a temp table which we can access

SELECT * from fact_sales_forecast_monthly;

# now we can get the difference like this 

SELECt *, (CAST(sold_quantity AS SIGNED) - 
CAST(forecast_quantity AS SIGNED))  as diff
from fact_sales_forecast_monthly;


## lets learn functions 

# get the forecasted sales for the FY = 2021

SELECT * from fact_forecast_monthly
where fiscal_year = 2021;


# get the actual sales for the FY = 2021

# lets get for normal year

SELECT * from fact_sales_monthly
where YEAR(date) = 2021;

## atliq has a FY of 1st sept 
# so atliq is 4 months ahead of us 

SELECT date_add("2021-09-01" , INTERVAL 4 month);

# lets get the FY
SELECT YEAR(date_add("2021-09-01" , INTERVAL 4 month));

# dont you think it will be great if we 
# have a own function like get fiscal year

# so we have 2 type of functions 
-- 1) Built in and 
-- 2) user defined or custome

# lets make one 

SELECT * from fact_sales_monthly
where get_fy(date) = 2021;
