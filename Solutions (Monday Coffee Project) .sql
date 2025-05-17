--Monday Coffee --Data Anaysis
SELECT * FROM city
SELECT * FROM products
SELECT * FROM customers
SELECT * FROM sales

--Reports & Data Analysis


--Q1.
--Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT
      city_name, 
      ROUND((population * 0.25)/1000000, 2) AS coffee_consumers, 
      city_rank
FROM city
ORDER BY 2 DESC;


--Q2.
--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT ct.city_name, SUM(total) AS total_revenue
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON ct.city_id = c.city_id
WHERE 
     EXTRACT(YEAR FROM s.sale_date) = 2023 
	 AND
	 EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1	 
ORDER BY 2 DESC;


--Q3.
--Sales Count for Each Product
--How many units of each coffee product have been sold?

SELECT 
      p.product_name,
	  COUNT(sale_id) AS total_orders
FROM products AS p
LEFT JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;


--Q4.
--Average Sales Amount per City
--What is the average sales amount per customer in each city?
--city and total sale
--no. of customers in each city

SELECT ct.city_name, 
       SUM(s.total) AS sales_amount,
	   COUNT(DISTINCT s.customer_id) AS total_customers,
	   ROUND(
	         SUM(s.total):: numeric/ 
			 COUNT(DISTINCT s.customer_id):: numeric 
			 ,2) AS avg_sales
	   
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON c.city_id = ct.city_id
GROUP BY 1
ORDER BY 2 DESC;


--Q5. City Population and Coffee Consumers (25%)
--Provide a list of cities along with their populations and estimated coffee consumers.
--Retun city name, total cureent customers, estimated coffee consumers (25%)

WITH city_table 
AS 
(
SELECT city_name, 
      Round
	  ((population * 0.25)/1000000, 2) AS est_coffee_consumers 
FROM city 
),

customers_table
AS 
(
SELECT ct.city_name,
       COUNT (DISTINCT c.customer_id) AS unique_customers
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON ct.city_id = c.city_id
GROUP BY ct.city_name
)

SELECT cut.city_name,  
       cut.unique_customers, 
	   cit.est_coffee_consumers
FROM city_table AS cit
JOIN customers_table AS cut
ON cit.city_name = cut.city_name;


--Q6.
--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM 
(
SELECT 
       ct.city_name,
	   p.product_name,
	   COUNT(s.sale_id) AS total_orders,
	   DENSE_RANK() OVER(PARTITION BY city_name ORDER BY COUNT(s.sale_id)DESC) AS rank
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON ct.city_id = c.city_id
GROUP BY 1, 2
) AS t1
WHERE rank <= 3;
--ORDER BY 1, 3 DESC


--Q7.
--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

SELECT ct.city_name, 
       COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city AS ct
LEFT JOIN customers AS c
ON ct.city_id = c.city_id 
JOIN sales AS s
ON c.customer_id = s.customer_id
WHERE 
      s.product_id IN (1, 2,  3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;


--Q8.
--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

WITH city_table 
AS (
SELECT ct.city_name, 
	   COUNT(DISTINCT s.customer_id) AS total_customers,
	   ROUND(
	         SUM(s.total):: numeric/ 
			 COUNT(DISTINCT s.customer_id):: numeric 
			 ,2) AS avg_sales
	   
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON c.city_id = ct.city_id
GROUP BY 1
ORDER BY 2 DESC
),

city_rent
AS
(
SELECT city_name,
       estimated_rent
FROM city
)

SELECT cr.city_name,
       cr.estimated_rent, 
	   cit.avg_sales, 
	   cit.total_customers,
	   ROUND
	   (cr.estimated_rent::numeric/
	                               cit.total_customers::numeric
	   , 2) AS avg_rent
FROM city_rent AS cr
JOIN city_table AS cit
ON cr.city_name = cit.city_name
ORDER BY 4 DESC;


--Q9.Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- by each city

WITH monthly_sales
AS 
(
SELECT ct.city_name,
       EXTRACT(MONTH FROM sale_date) AS month, 
	   EXTRACT(YEAR FROM sale_date) AS year,
	   SUM(s.total) AS total_sale 
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON c.city_id = ct.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2
),

growth_ratio
AS 
(
SELECT city_name,
       month,
	   year, 
	   total_sale AS cr_month_sale,
	   LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
FROM monthly_sales
)

SELECT city_name,  
       month, 
	   year, 
	   cr_month_sale, 
	   last_month_sale, 
	   ROUND(
            (cr_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100
			, 2
			)AS growth_ratio 

FROM growth_ratio
WHERE growth_ratio IS NOT NULL;


--Q10.
--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table 
AS (
SELECT ct.city_name, 
       SUM(s.total) AS total_revenue,
	   COUNT(DISTINCT s.customer_id) AS total_customers,
	   ROUND(
	         SUM(s.total):: numeric/ 
			 COUNT(DISTINCT s.customer_id):: numeric 
			 ,2) AS avg_sales
	   
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ct
ON c.city_id = ct.city_id
GROUP BY 1
ORDER BY 2 DESC
),

city_rent
AS
(
SELECT city_name,
       estimated_rent,
	   ROUND((population * 0.25)/1000000, 2) AS estimated_coffee_consumers 
FROM city
)

SELECT cr.city_name,
       total_revenue,
       cr.estimated_rent AS total_rent, 
	   cit.avg_sales, 
	   estimated_coffee_consumers,
	   cit.total_customers,
	   ROUND
	   (cr.estimated_rent::numeric/
	                               cit.total_customers::numeric
	   , 2) AS avg_rent
FROM city_rent AS cr
JOIN city_table AS cit
ON cr.city_name = cit.city_name
ORDER BY 2 DESC;


/*
Recommendation 
City 1: Pune
    1. Avg rent per customer is very less.
    2. Highest total revenue.
    3. Avg sale per customer is also high.

City 2: Delhi
    1. Highest estimated coffee consumers which is 7.7M.
    2. Highest total cutomers which is 68.
    3. Avg rent per customer is 330 (stil under 500).

City 3: Jaipur
    1. Highest no of customers which is 69.
    2. Avg rent per customer is very less 156.
    3. Avg sale per customer is better which is 11.6K.









 
































































