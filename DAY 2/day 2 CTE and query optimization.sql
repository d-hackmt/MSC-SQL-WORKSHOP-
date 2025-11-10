-- ===========================================================================
--                               CTE's						
-- ===========================================================================

## lets learn CTEs first 

-- get all the total_qty_sales and the customer for year 2020 and qty > 500000

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





-- we handled it using stored procedure , and having 

-- but the query doesnt look too readable 
-- let increase the readiblity 


with abc as 
(
SELECT s.date , customer_code ,  
SUM(sold_quantity) as qty,
c.customer
from fact_sales_monthly s
join dim_customer c
using (customer_code)
where YEAR(date) = 2020
group by customer_code
)
SELECT * from abc
where qty >500000
order by qty DESC; # 5 lakhs ;

-- this can also be converted to a stored procedure 

-- ===========================================================================

--
-- lets solve a task

-- -------------------------------------------------------------------------------
-- 									   TASK 2 
/*
As a product owner, I need an aggregate monthly gross sales report 
for Croma India customer so that I can track how much sales this 
particular customer is generating for AtliQ and manage our relationships accordingly.

The report should have the following fields

1. Month
2. Total gross sales amount to Croma India in this month

-- -------------------------------------------------------------------------------

*/


SELECT customer_code 
from dim_customer
where customer = "croma"
and market = "india";


SELECT date , SUM(s.sold_quantity * g.gross_price) as gross_total
from fact_sales_monthly s
JOIN fact_gross_price g
on s.product_code = g.product_code
and g.fiscal_year = get_fy(s.date)
where customer_code = 90002002
group by date;


-- ===========================================================================
--                             QUERY OPTIMIZATION 							
-- ===========================================================================


## we want to calculate net sales of products

--  LOGIC :  
--  gross price - pre invoice - post invoice = net sales
			
-- ===========================================================================

SELECT 
s.date , p.product , p.variant , sold_quantity 
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code;

-- now we will add gross price

SELECT 
	s.date , p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
on g.product_code = s.product_code
and g.fiscal_year = get_fy(s.date);

-- now lets go for pre invoice deductions and specific columns

SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = get_fy(s.date)
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = get_fy(s.date)
where get_fy(s.date) = 2021
LIMIT 1000000;

-- now you can see it took alot of time 

-- LETS analyze it 

EXPLAIN ANALYZE
SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = get_fy(s.date)
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = get_fy(s.date)
where get_fy(s.date) = 2021
LIMIT 1000000;


-- we just feel that fiscal year took a lot of time 
-- so lets optimize that     
       				
-- ===========================================================================



/*  # QUERY PERFORMANCE

1st trick to make it better , add a dim date table with 2 columns 

1) calender date of type date           -- Here you will make an excel sheets with 
											unique date like fact_sales_monthly
                                            
										-- to check : SELECT distinct date from fact_sales_monthly
                                            
2) Fiscal_year of type YEAR             -- this will be a generated column 
										-- YEAR(date_add(date,INTERVAL 4 MONTH));
                                        
                                        
                                        LETS Create a date seed

*/



SELECT min(date) from fact_sales_monthly;

SELECT max(date) from fact_sales_monthly;

-- to get all unique date , and we can export that 

SELECT distinct date from fact_sales_monthly;


SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_date d
	on d.calender_date = s.date
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = d.fiscal_year
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = d.fiscal_year
where d.fiscal_year = 2021
LIMIT 1000000;


EXPLAIN ANALYZE
SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_date d
	on d.calender_date = s.date
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = d.fiscal_year
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = d.fiscal_year
where d.fiscal_year = 2021
LIMIT 1000000;

-- ===========================================================================

/*  # QUERY PERFORMANCE

2nd trick to make it better , add generated column in fact_sales_monthly 

                                            
1) Fiscal_year of type YEAR             -- this will be a generated column 
										-- YEAR(date_add(date,INTERVAL 4 MONTH));

*/


SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = s.fiscal_year
where s.fiscal_year = 2021
LIMIT 1000000;


-- lets check performance

EXPLAIN ANALYZE
SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = s.fiscal_year
where s.fiscal_year = 2021
LIMIT 1000000;


-- ===========================================================================




