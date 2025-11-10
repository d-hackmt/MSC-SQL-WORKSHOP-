-- which are my top markets by net sales 


SELECT market,
SUM(net_sales) as net_sales_total
from net_sales
group by market
order by net_sales_total;

-- we want to do this per Fiscal_year
-- its going to take alot of timw to run 
-- coz it jumps from views to views and tables 

SELECT market,
SUM(net_sales) as net_sales_total
from net_sales
where fiscal_year = 2021
group by market
order by net_sales_total;

-- they need it in mls 

-- lets get top 5 markets

SELECT market,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales
where fiscal_year = 2021
group by market
order by net_sales_mln DESC
LIMIT 5;

-- look at the results , they exactly look like mentioned in requiremnts , for real

## so now looking at the requirement feels the poeple would need something like this 
-- better create this into a stored procedure 
-- and the requirement clearly states that


/*


CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_markets_by_net_sales`(
	in_fiscal_year INT,        -- keep this to int to avoid typecasting from year to INT
    in_top_n INT
)
BEGIN

SELECT market,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales
where fiscal_year = in_fiscal_year
group by market
order by net_sales_mln DESC
LIMIT in_top_n;

END


*/


-- so this is done
-- my 1st deliverable is done


-- now top customers 
-- lets seee the easiest way to do it

SELECT customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales
where fiscal_year = 2021
group by customer
order by net_sales_mln DESC
LIMIT 5;


-- but we forgot to add customers 

-- lets join customer table then

SELECT c.customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where fiscal_year = 2021
group by customer
order by net_sales_mln DESC
LIMIT 5;


-- and we have top 5 customers as welll 

-- lets create a stored procedure 
-- lets add market as well just in case 



/*

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_customers_by_net_sales`(
	in_top_n INT,
    in_market varchar(50),
    in_fiscal_year INT
)
BEGIN

SELECT c.customer,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales s 
JOIN dim_customer c
on c.customer_code = s.customer_code
where s.fiscal_year = in_fiscal_year and s.market = in_market 
group by customer
order by net_sales_mln DESC
LIMIT in_top_n;

END

*/


-- now lets get top products 
-- we dont have to join coz we have prodcuts

SELECT product,
ROUND(SUM(net_sales)/1000000 , 2) as net_sales_mln
from net_sales
where fiscal_year = 2021
group by product
order by net_sales_mln DESC
LIMIT 5;
