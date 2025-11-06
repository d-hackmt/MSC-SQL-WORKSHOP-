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

