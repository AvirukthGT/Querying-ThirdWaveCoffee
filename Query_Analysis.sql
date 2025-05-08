-- Monday Coffee - Data Analysis Dashboard
-- Dataset Tables: city, products, customers, sales

-- ======================================
-- Q1: Estimated Coffee Consumers by City
-- Assume 25% of the population consumes coffee
-- ======================================

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

-- ======================================
-- Q2: Total Revenue from Coffee Sales (Q4 2023)
-- ======================================

-- National-level total revenue
SELECT 
    SUM(total) AS total_revenue
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
  AND EXTRACT(QUARTER FROM sale_date) = 4;

-- City-wise total revenue
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2023
  AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- ======================================
-- Q3: Sales Count for Each Product
-- ======================================

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- ======================================
-- Q4: Average Sales Amount per Customer by City
-- ======================================

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS avg_sale_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- ======================================
-- Q5: City Population and Coffee Consumers
-- ======================================

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT 
    ct.city_name,
    cft.coffee_consumers AS coffee_consumer_in_millions,
    ct.unique_customers
FROM customers_table ct
JOIN city_table cft ON cft.city_name = ct.city_name;

-- ======================================
-- Q6: Top 3 Selling Products by City
-- ======================================

SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) ranked_products
WHERE rank <= 3;

-- ======================================
-- Q7: Customer Segmentation by Coffee Product Sales
-- ======================================

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_coffee_customers
FROM city ci
LEFT JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id
WHERE s.product_id BETWEEN 1 AND 14  -- Assuming coffee products have IDs 1 to 14
GROUP BY ci.city_name;

-- ======================================
-- Q8: Average Sale vs Rent per Customer by City
-- ======================================

WITH city_sales AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    cs.total_customers,
    cs.avg_sale_per_customer,
    ROUND(cr.estimated_rent::numeric / cs.total_customers::numeric, 2) AS avg_rent_per_customer
FROM city_rent cr
JOIN city_sales cs ON cr.city_name = cs.city_name
ORDER BY avg_sale_per_customer DESC;

-- ======================================
-- Q9: Monthly Sales Growth by City
-- ======================================

WITH monthly_sales AS (
    SELECT 
        c.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS total_sales
    FROM customers cu
    JOIN city c USING(city_id)
    JOIN sales s USING(customer_id)
    GROUP BY c.city_name, year, month
),
growth_ratio AS (
    SELECT 
        city_name,
        month,
        year,
        total_sales AS current_month_sales,
        LAG(total_sales) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sales
    FROM monthly_sales
)
SELECT 
    city_name,
    month,
    year,
    current_month_sales,
    last_month_sales,
    ROUND((current_month_sales - last_month_sales)::numeric / last_month_sales::numeric * 100, 2) AS growth_percentage
FROM growth_ratio;

-- ======================================
-- Q10: Market Potential Analysis - Top 3 Cities
-- ======================================

WITH city_sales AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_info AS (
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumers_in_millions
    FROM city
)
SELECT 
    ci.city_name,
    cs.total_revenue,
    ci.estimated_rent AS total_rent,
    cs.total_customers,
    ci.estimated_coffee_consumers_in_millions,
    cs.avg_sale_per_customer,
    ROUND(ci.estimated_rent::numeric / cs.total_customers::numeric, 2) AS avg_rent_per_customer
FROM city_info ci
JOIN city_sales cs ON ci.city_name = cs.city_name
ORDER BY cs.total_revenue DESC
LIMIT 3;

-- ======================================
-- Final Recommendation Summary (based on output)
-- ======================================
/*
City 1: Pune
    - Highest total revenue
    - Low average rent per customer
    - High average sales per customer

City 2: Delhi
    - Highest estimated coffee consumers (7.7 million)
    - Largest customer base (68 customers)
    - Reasonable rent per customer (~330)

City 3: Jaipur
    - Highest number of customers (69)
    - Very low average rent per customer (~156)
    - Good average sales per customer (~11.6k)
*/
