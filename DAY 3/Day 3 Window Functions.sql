## WINDOW FUNCTIONS

USE random_tables;

SELECT * 
from expenses
order by category;

SELECT 
SUM(amount)
from expenses
order by category;

-- 65800

SELECT *,
amount*100/SUM(amount) as amt_pct 
from expenses
order by category;



SELECT *,
amount*100/SUM(amount) over() as amt_pct  
from expenses
order by category;

SELECT SUM(amount) from expenses 
where category ="Food" ;

SELECT *,
amount*100/SUM(amount) over(partition by category) as amt_pct  
from expenses
order by category;


# cumilative 

SELECT *,
SUM(amount) over(partition by category order by date) as amt_pct  
from expenses
order by category , date;




## lets see the same in Atliq hardware 



-- percentage contri on global net sales by customer 

-- currently for 2021 
-- but can be for any year


-- so we will write query here and make the chart in excel



SELECT c.customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by customer
order by net_sales_mln DESC;


## we can sum these up and find percentage and its cool 
## we will do using window funciton





SELECT c.customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln,
SUM(net_sales_mln)  -- but we cant use a calc col for calc col
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by customer
order by net_sales_mln DESC;

-- so again we have 2 option 

-- view , cte 

-- lets do cte

with cte1 as(
SELECT c.customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by customer
)
SELECT *,
net_sales_mln*100/SUM(net_sales_mln) over() as net_mln_pct
from cte1
order by net_sales_mln DESC;

-- so it willl take whole thing as window if over()




-- exercise time

-- now it was global , 
-- but now it will be region based

SELECT c.customer,
c.region,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by c.customer , c.region -- coz you have to find total sales for per region 
order by net_sales_mln DESC;

-- see earlier amazon had 109 share but now because of region it has got divided 


with cte1 as(
SELECT c.customer,
c.region,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by c.customer , c.region -- coz you have to find total sales for per region 
)
SELECT *,
net_sales_mln*100/SUM(net_sales_mln) 
over(partition by region) as pct_share_region
-- in that region how much is the pct market share by that customer
from cte1
order by region , pct_share_region DESC;



-- if i want to verify these numbers are correct or not
-- lets export it 


-- check total of APAC = 99.99  -- check if distribution is proper

-- cross verify 

# make pie charts 



-- lets learn more 

# window functions rank , dense_rank , row_number 


## show 2 top category 

USE random_tables;

SELECt 
* 
from expenses
order by category;


SELECt 
* ,
row_number() over(partition by category order by amount DESC) as rn
from expenses
order by category;

with cte1 as (SELECt 
* ,
row_number() over(partition by category order by amount DESC) as rn,
rank() over(partition by category order by amount DESC) as rnk,
dense_rank() over(partition by category order by amount DESC) as drnk
from expenses
order by category)
SELECT * from cte1
where drnk <= 2;


SELECT * ,
row_number() over(order by marks DESC) as rn,
rank() over(order by marks DESC) as rnk,
dense_rank() over(order by marks DESC) as drnk
from student_marks;



# lets solve our task 

USE gdb0041;

SELECT p.division , p.product ,
SUM(s.sold_quantity) as total_qty
from fact_sales_monthly s 
JOIN dim_product p
	on p.product_code = s.product_code
where fiscal_year = 2021
group by p.product;


SELECT p.division , p.product ,
SUM(s.sold_quantity)as total_qty, 
dense_rank() over()  -- but we cant use this here , coz its a calculated column
from fact_sales_monthly s 
JOIN dim_product p
	on p.product_code = s.product_code
where fiscal_year = 2021
group by p.product;


-- lets write a cte
with cte1 as (
SELECT p.division , p.product ,
SUM(s.sold_quantity) as total_qty
from fact_sales_monthly s 
JOIN dim_product p
	on p.product_code = s.product_code
where fiscal_year = 2021
group by p.product)
SELECT *,
dense_rank() over(partition by division order by total_qty DESC) as drnk
from cte1;


# but we want top 3 , but again we cant use 

-- so either we can make a view , or we can make a cte 2 
-- lets see that 

with cte1 as (
SELECT p.division , p.product ,
SUM(s.sold_quantity) as total_qty
from fact_sales_monthly s 
JOIN dim_product p
	on p.product_code = s.product_code
where fiscal_year = 2021
group by p.product),
-- you can use cte1 in cte2

cte2 as (
SELECT *,
dense_rank() over(partition by division order by total_qty DESC) as drnk
from cte1)
SELECT * from cte2
where drnk <= 3;


-- so i got my top 3 products by divison
-- so business manager can make decisions on this

-- lets make a stored procedure 
-- it will also be beneficial for backend python developers etc


/*


CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_product_per_divison_by_qty_sold`(
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN

with cte1 as (
SELECT p.division , p.product ,
SUM(s.sold_quantity) as total_qty
from fact_sales_monthly s 
JOIN dim_product p
	on p.product_code = s.product_code
where fiscal_year = in_fiscal_year
group by p.product),
-- you can use cte1 in cte2

cte2 as (
SELECT *,
dense_rank() over(partition by division order by total_qty DESC) as drnk
from cte1)
SELECT * from cte2
where drnk <= in_top_n;

END

*/


## exercise 


SELECT s.market , c.region,
ROUND(SUM(gross_price_total)/1000000,2) as gross_sales_mln
from gross_sales s 
JOIN dim_customer c
using (customer_code)
where s.fiscal_year = 2021
group by s.market
order by gross_sales_mln DESC;


with cte1 as
(SELECT s.market , c.region,
ROUND(SUM(gross_price_total)/1000000,2) as gross_sales_mln
from gross_sales s 
JOIN dim_customer c
using (customer_code)
where s.fiscal_year = 2021
group by s.market
order by gross_sales_mln DESC),
cte2 as (
select *,
			dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
			from cte1
)
SELECT * from cte2
where drnk<=2;



with cte1 as
(SELECT s.market , c.region,
ROUND(SUM(gross_price_total)/1000000,2) as gross_sales_mln
from gross_sales s 
JOIN dim_customer c
using (customer_code)
where s.fiscal_year = 2021
group by s.market
order by gross_sales_mln DESC),
cte2 as (
SELECT *,
dense_rank() over(partition by region order by gross_sales_mln desc ) as drnk
from cte1)
SELECT * from cte2
where drnk <=2 ;