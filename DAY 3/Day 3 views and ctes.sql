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

# now to get net invoice sales 


SELECT 
	s.date , 
    p.product , p.variant , s.sold_quantity ,
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct,
    
    -- but we cant make another calculated column on a calculated colum
    -- so what are our options
    
    -- CTEs, subqueries , views
    (gross_total - gross_total*pre_invoice_discount_pct) as net_invoice_sales
    
    
    
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

-- i like CTE's more personally so 
-- lets try CTE's 

with cte1 as(
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
LIMIT 1000000)
SELECT *,
(gross_total - gross_total*pre_invoice_discount_pct) as net_invoice_sales
from cte1;


-- but again can we have something simple ? 
-- and something we can use again if needed 
-- anyways ctes scope was for 1 query only

-- views 

/*
Views are not actual physical tables , view are virtual tables which 
area create on ther fly by running querires ,
unlike physical tables which are stored on the db
*/


-- lets first add a customer code and product_code for joining
-- and a market column , coz its asked to us 
-- and also remove the FY coz we dont want to restrict it to that FY
-- add the FY column 

SELECT 
	s.date, s.fiscal_year,
	s.customer_code,c.market,
	s.product_code, p.product, 
	p.variant, s.sold_quantity, 
    g.gross_price , (s.sold_quantity * g.gross_price) as gross_total , 
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
JOIN dim_product p
	on p.product_code = s.product_code
JOIN dim_customer c 
	on c.customer_code = s.customer_code
JOIN fact_gross_price g 
	on g.product_code = s.product_code
	and g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code
    and pre.fiscal_year = s.fiscal_year
LIMIT 1500000;


-- sales_preinv_discount VIEW created 


SELECT *,
(gross_total - gross_total*pre_invoice_discount_pct) as net_invoice_sales
FROM sales_preinv_discount
LIMIT 1000000;


-- let simplify the logic , same resutls same logic

SELECT *,
(1 - pre_invoice_discount_pct)*gross_total as net_invoice_sales
FROM sales_preinv_discount
LIMIT 1000000;

-- now lets get post invoic discount 
-- we have to make a join with post invoice discount 

-- customer_code , product_code and date


SELECT *,
(1 - pre_invoice_discount_pct)*gross_total as net_invoice_sales
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
	on s.date = po.date
    and s.product_code = po.product_code
	and s.customer_code = po.customer_code
LIMIT 10;

-- now lets add post_invoice discount 

SELECT *,
(1 - pre_invoice_discount_pct)*gross_total as net_invoice_sales,
(po.discounts_pct + po.other_deductions_pct) as post_invoice_discount_pct
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
	on s.date = po.date
    and s.product_code = po.product_code
	and s.customer_code = po.customer_code
LIMIT 10;


-- and we have post discount pct , 
-- we can subtract the post dicount from net invoice sales 

-- again we cant make a new calculated column on a calculated col 

-- so our option 
-- subquery == complex queery
-- cte1 - scope for 1 query 
-- view - virtual table for future use


-- let make a view sales_postinv_discount

-- and lets keep the relevant columns 


SELECT 
s.date, s.fiscal_year,
s.customer_code, s.market,
s.product_code, s.product, s.variant,
s.sold_quantity, s.gross_total,
s.pre_invoice_discount_pct,
(1 - pre_invoice_discount_pct)*gross_total as net_invoice_sales,
(po.discounts_pct + po.other_deductions_pct) as post_invoice_discount_pct
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
	on s.date = po.date
    and s.product_code = po.product_code
	and s.customer_code = po.customer_code;


-- view created 

SELECT * from sales_postinv_discount;


SELECT *,
(1-post_invoice_discount_pct)*net_invoice_sales as net_sales
from sales_postinv_discount;

-- so just for my convinience i will also created a view for net sales 

-- view created 

SELECT * from net_sales;

-- now i can do any aggregation on this 
-- top customer 
-- top product anything

-- now raw material is ready now lets build a building



/* 
Exercise: Database Views
Create a view for gross sales. It should have the following columns,

date, fiscal_year, customer_code, customer, market, product_code, product, variant,
sold_quantity, gross_price_per_item, gross_price_total

*/

-- SOLUTION 

SELECT 
s.date, s.fiscal_year, 
s.customer_code, c.customer, c.market, 
s.product_code, p.product, p.variant,
s.sold_quantity, g.gross_price as gross_price_per_item, 
(s.sold_quantity * g.gross_price) as gross_price_total
from fact_sales_monthly s
JOIN dim_customer c
	on c.customer_code = s.customer_code
JOIN dim_product p
	on p.product_code = s.product_code
JOIN fact_gross_price g
	on g.product_code = s.product_code
    and g.fiscal_year = s.fiscal_year;
    
