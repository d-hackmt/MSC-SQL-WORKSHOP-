-- DETAILED BASICS

-- ===========================================================================
--                            WINDOW FUNCTIONS 						
-- ===========================================================================

-- what if i want to apply aggregation and also get the rows 
-- at the same time and also not use group by 
-- because use cases like that exist

show tables;

SELECT * from expenses;


SELECT * from expenses
order by category;

/*
 in a month you are spending on food
shoppin and various categories , and you wanna know
 
what is the percentage expense for a given item,
Compared to total expenses


*/

-- so what is my total expense

SELECT SUM(amount) from expenses;

/*

 65800

 now i want to know the percentage contribution of each of these expenses

 6000 to  65800 

 you may think you can , yea we can make a calculated column 

*/

SELECT * ,
(amount*100/SUM(amount)) as pct
from expenses
order by category;

-- and see we get 1 row , because thats the nature of group by or aggregating function 
-- they give you 1 aggregation  
-- even if you use group by you will get 1 value per category

SELECT * ,
(amount*100/SUM(amount)) as pct
from expenses
group by category
order by category;

-- see 

-- here i want to see the percentage of all the expenses 
-- we can do that with window functions

-- ====================================================================
--                   Window Functions: OVER
-- ====================================================================

SELECT * ,
amount*100/SUM(amount) over() as pct
from expenses
order by category;


/*

 now you can see what results we got , so 

 over() clause is a window function 
 and here the window is all the rows


 lets say you want to get this pct but not with respect to each row but per category 
 how much im spending on food , shopping etc

 lets say food 

*/


-- we can definitely check the total

SELECT category , SUM(amount) 
from expenses
group by category;


SELECT sum(amount) from expenses
where category = "food";


-- 11800  (sum for food category)

SELECT * ,
amount*100/SUM(amount) 
over(partition by category) as pct
from expenses
order by category;

/*

 so in this scenario category becomes our window 
 so you are taking all rows and partitioning them by windows
 you are just creating windows and whatever formuala 
 you are computing will be computed with respect to that window only
 and when you dont have any partition by , you default window is all the rows




-- ====================================================================

-- lets look at one more use csae where you want to display cumilative expenses


-- first category and then dates , else wrong results 
*/

SELECT * from expenses
order by category,date ;

/*
 i want to find from the 1st day till the 10th , 
 how much  i spent on food

 group - aggregate 
 partition - sperate 
 order -- arrange

*/

SELECT * ,
	SUM(amount) over(partition by category order by date) as total_epense_till_date
from expenses
order by category , date;


-- ====================================================================
--         Window Functions: ROW_NUMBER, RANK, DENSE_RANK
-- ====================================================================

/*
LETs say : 
in expenses table 

You want to find out top 2 expenses in each category

*/

SELECT * from expenses
order by category ;

-- lets use row number 


SELECT * ,
row_number() 
over(partition by category order by amount DESC) as rn
from expenses
order by category ;

/*

so you can see we have ordered and also acquired the results by category DESC
now we can use CTE 
having doesnt work on a window function

*/

with cte1 as (
SELECT * ,
row_number() 
over(partition by category order by amount DESC) as rn
from expenses
order by category)
SELECT * from cte1
where rn <=2 ;  -- top 2 


-- but you can see the problem , we have 2700 ub food section which was rank 2 as well 


with cte1 as (
SELECT * ,
row_number() over(partition by category order by amount DESC) as rn , 
rank() over(partition by category order by amount DESC) as rnk
from expenses
order by category)
SELECT * from cte1
where rnk <=2 ;

/*

in rank 2700 got 2 rank and it got 3 in row number and 
row number never repeast , its unique for each row
but bow the problem is pani puri should be 3rd rank not 2 , so the true rank is 3 
 so you will use dense rank
 
*/
 
with cte1 as (
SELECT * ,
row_number() over(partition by category order by amount DESC) as rn , 
rank() over(partition by category order by amount DESC) as rnk , 
dense_rank() over(partition by category order by amount DESC) as drnk
from expenses
order by category)
SELECT * from cte1
where drnk <=2 ;



/*

so that how we get these 

whenever you want to top things by category , like top 2 products sold etc

================================
-- LEts go to another data set
 ================================

lets say i want to give a gift to first 5 students and they can be any number of students 4,,5,,6 when i have unilimited books ,

but if i have limit books - i will use rank maybe 

SELECT * from student_marks;

*/

SELECT * ,
row_number() over(order by marks DESC) as rn , 
rank() over(order by marks DESC) as rnk , 
dense_rank() over(order by marks DESC) as drnk
from student_marks;

-- check out these results 

-- ------------------------------------------------------------


-- JUST WINDOWS FUCNTIONS without comments



-- ----------------------------------------------------------


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
