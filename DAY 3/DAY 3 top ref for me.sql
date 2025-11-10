USE gdb00420;

SELECT * from fact_sales_monthly
LIMIT 1500000;

-- topmarkets , products , customers by net sales mln 


SELECT s.date , s.fiscal_year,
s.customer_code, c.customer,c.market,
s.product_code ,  p.product, p.variant,
s.sold_quantity , g.gross_price,
ROUND((s.sold_quantity*g.gross_price),2) as gross_total
from fact_sales_monthly s
JOIN dim_customer c 
	on c.customer_code = s.customer_code
JOIN dim_product p 
	on p.product_code = s.product_code 
JOIN fact_gross_price g 
	on g.fiscal_year = s.fiscal_year
	and g.product_code = s.product_code
where s.fiscal_year = 2021
LIMIT 1500000;


-- total_gross_sales table ready 

-- lets calculate pre-invoice-discount

with cte1 as (
SELECT s.date , s.fiscal_year,
s.customer_code, c.customer,c.market, 
s.product_code , p.product, p.variant , p.division,
s.sold_quantity , g.gross_price,
ROUND((s.sold_quantity*g.gross_price),2) as gross_total,
pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_customer c 
	on c.customer_code = s.customer_code
JOIN dim_product p 
	on p.product_code = s.product_code 
JOIN fact_gross_price g 
	on g.fiscal_year = s.fiscal_year
	and g.product_code = s.product_code
JOIN fact_pre_invoice_deductions pre 
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = s.fiscal_year
LIMIT 1500000)
SELECT *,
ROUND((gross_total - pre_invoice_discount_pct*gross_total),2) as net_invoice_sales
from cte1
where fiscal_year = 2021;



SELECT * 
from sales_preinv_discount
where fiscal_year = 2021
LIMIT 1500000;


SELECT * ,
ROUND((1- pre_invoice_discount_pct)* gross_total,2) as net_invoice_sales
from sales_preinv_discount
where fiscal_year = 2021
LIMIT 1500000;


-- now we have net invoice sales 
-- lets calc pos inv sales 


SELECT s.date , s.fiscal_year,
s.customer_code, s.customer,s.market, 
s.product_code , s.product, s.variant , s.division,
s.sold_quantity , s.gross_price,
s.gross_total, s.pre_invoice_discount_pct,
ROUND((1- pre_invoice_discount_pct)* gross_total,2) as net_invoice_sales,
(pos.discounts_pct + pos.other_deductions_pct ) as post_invoice_discount_pct
from sales_preinv_discount s
JOIN fact_post_invoice_deductions pos
	on pos.customer_code = s.customer_code
    and pos.product_code = s.product_code
    and pos.date = s.date
where fiscal_year = 2021
LIMIT 1500000;

-- lets create a view 

SELECT *,
ROUND((net_invoice_sales - post_invoice_discount_pct*net_invoice_sales),2) as net_sales
from sales_postinv_discount
where fiscal_year = 2021
LIMIT 1500000;

-- or 

SELECT *,
ROUND((1 - post_invoice_discount_pct)*net_invoice_sales,2) as net_sales
from sales_postinv_discount
where fiscal_year = 2021
LIMIT 1500000;

-- create a view for net sales 

SELECT * from net_sales
where fiscal_year = 2021
LIMIT 1500000;


/*

EXERCISE 

Exercise: Database Views
Create a view for gross sales. It should have the following columns,

date, fiscal_year, customer_code, customer, market, product_code, product, variant,
sold_quantity, gross_price_per_item, gross_price_total

*/

SELECT 
s.date, s.fiscal_year, 
s.customer_code, c.customer, c.market, 
s.product_code, p.product, p.variant,
s.sold_quantity, g.gross_price as gross_price_per_item, 
ROUND((s.sold_quantity * g.gross_price),2) as gross_price_total
from fact_sales_monthly s
JOIN dim_customer c
	on c.customer_code = s.customer_code
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g
	on g.product_code = s.product_code
    and g.fiscal_year = s.fiscal_year;


-- lets get the top markets , products , customers

-- top markets 

SELECT market ,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year=2021
group by market
order by net_sales_mln DESC
LIMIT 3;

-- create a stored procedure for that 

-- top customers 


SELECT customer ,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year=2021
and market = 'india'
group by customer
order by net_sales_mln DESC
LIMIT 3;


-- top products 

SELECT product ,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year=2021
group by product
order by net_sales_mln DESC
LIMIT 3;



--  ============================================
--             WINDOW FUNCTIONS
--  ============================================



USE random_tables;

SELECT *
from expenses;


SELECT *
from expenses
order by category;

SELECT SUM(amount)
from expenses;

-- 65800

SELECT *,
amount*100/SUM(amount) as pct
from expenses
order by category;

-- ever if we try to add group by , wont work
-- + wrong results 

SELECT *,
amount*100/SUM(amount) as pct
from expenses
group by category
order by category;


-- lets try window functions

SELECT *,
amount*100/SUM(amount) over() as pct 
from expenses
order by category;


-- lets try for individual categories

SELECT category,
SUM(amount) as sum
from expenses
group by category;

-- 

SELECT *,
amount*100/SUM(amount) over(partition by category) as pct 
from expenses
order by category;

-- cumilateive types

SELECT *,
SUM(amount) over(partition by category order by date) as cumilative
from expenses
order by category , date ;


-- lets go back to atliq hardware and solve the thing

use gdb00420;



SELECT * from net_sales;

-- find out customer wise net sales percentage contribution 

SELECT customer ,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year=2021
group by customer
order by net_sales_mln DESC;

-- now we have to calculate percentage of
-- net sales mln 
-- so lets cte for that

with cte1 as 
(
SELECT customer ,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year=2021
group by customer
)
SELECT customer ,
net_sales_mln*100/SUM(net_sales_mln) over() net_sales_mln_pct
from cte1
order by net_sales_mln DESC;


-- Find customer wise net sales distibution per region for FY 2021



SELECT c.customer , c.region,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
JOIN dim_customer c
using (customer_code) 
where fiscal_year=2021
group by c.customer , c.region;


with cte1 as (
SELECT c.customer , c.region,
ROUND(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
JOIN dim_customer c
using (customer_code) 
where fiscal_year=2021
group by c.customer , c.region
)
SELECT *,
net_sales_mln*100/sum(net_sales_mln) over (partition by region) as pct_share_region
from cte1
order by region , pct_share_region DESC;








