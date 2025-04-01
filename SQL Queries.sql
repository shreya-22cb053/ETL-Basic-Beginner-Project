-- Find top 10 highest revenue generating products
SELECT product_id, SUM(sales_price * quantity) AS revenue
FROM df_orders
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;

-- Find top 5 highest selling products in each region
WITH CTE1 AS (
    SELECT region, product_id, SUM(sales_price * quantity) AS revenue
    FROM df_orders
    GROUP BY region, product_id
)
SELECT region, product_id, revenue FROM 
(
    SELECT region, product_id, revenue, ROW_NUMBER() OVER(PARTITION BY region ORDER BY revenue DESC) AS rn
    FROM cte1
) sq1
WHERE rn <= 5;

-- Find month over month comparison for 2022 and 2023 sales
WITH CTE1 AS (
    SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS month_num, SUM(sales_price * quantity) AS revenue
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
),
CTE2 AS (
    SELECT month_num, 
           SUM(CASE WHEN order_year = 2022 THEN revenue ELSE 0 END) AS revenue_2022,
           SUM(CASE WHEN order_year = 2023 THEN revenue ELSE 0 END) AS revenue_2023
    FROM CTE1
    GROUP BY month_num
)
SELECT *, ROUND((revenue_2023 - revenue_2022) * 100 / revenue_2022, 2) AS YoY_change
FROM CTE2
ORDER BY month_num;

-- For each category which month had highest sales
WITH CTE1 AS (
    SELECT category, DATE_FORMAT(order_date, '%Y-%m') AS order_year_month, SUM(sales_price * quantity) AS category_sales 
    FROM df_orders
    GROUP BY category, DATE_FORMAT(order_date, '%Y-%m')
),
CTE2 AS (
    SELECT category, order_year_month, DENSE_RANK() OVER (PARTITION BY category ORDER BY category_sales DESC) AS category_sales_rank
    FROM CTE1
)
SELECT category, order_year_month
FROM CTE2
WHERE category_sales_rank = 1;

-- Which sub-category had highest growth by profit in 2023 compared to 2022?
WITH CTE1 AS (
    SELECT sub_category, YEAR(order_date) AS order_year, SUM(profit * quantity) AS total_profit
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
),
CTE2 AS (
    SELECT sub_category,
           SUM(CASE WHEN order_year = 2022 THEN total_profit ELSE 0 END) AS profit_2022,
           SUM(CASE WHEN order_year = 2023 THEN total_profit ELSE 0 END) AS profit_2023
    FROM CTE1
    GROUP BY sub_category
)
SELECT *, ROUND((profit_2023 - profit_2022) * 100 / profit_2022, 2) AS YoY_change
FROM CTE2
ORDER BY YoY_change DESC
LIMIT 1;
