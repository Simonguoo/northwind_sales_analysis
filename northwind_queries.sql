-- rank employees by sales performance:
CREATE VIEW employee_sales AS
WITH sales_per_employee AS (
	SELECT E.employee_id, e.first_name, e.last_name, 
		ROUND(CAST(SUM(OD.Unit_Price * OD.Quantity * (1- OD.discount)) AS NUMERIC), 2) 
		AS Total_Sales
	FROM employees E, orders O, order_details OD
	WHERE E.employee_id = O.employee_id AND O.order_id = OD.order_id
	GROUP BY e.employee_id
)

SELECT employee_ID, first_Name, last_Name,
       RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Performance_Rank
FROM sales_per_employee;


-- sales growth per month:
CREATE VIEW monthly_sales_growth AS
WITH month_by_month_sales AS (
	select EXTRACT(YEAR FROM order_date) as order_year, 
		EXTRACT(MONTH FROM order_date) as order_month,
		ROUND(CAST(SUM(OD.Unit_Price * OD.Quantity * (1- OD.discount)) AS NUMERIC), 2) 
			AS Monthly_Sales, order_date
	from orders o, order_details od
	WHERE o.order_id = od.order_id
	group by order_month, order_year, order_date
)

SELECT order_date,
	(Monthly_Sales / LAG(Monthly_Sales) OVER 
		(ORDER BY order_year, order_month) - 1) * 100 AS Growth_Rate
FROM month_by_month_sales;


-- customers with above average order value

CREATE VIEW customer_order_tier AS
WITH order_values AS (
    SELECT O.customer_id, O.order_id,
		ROUND(CAST(SUM(OD.Unit_Price * OD.Quantity * (1- OD.discount)) AS NUMERIC), 2) 
		AS order_value
    FROM orders O, order_details OD
	WHERE O.order_id = OD.order_id
    GROUP BY O.Customer_ID, O.Order_ID
)
SELECT  C.company_name, C.contact_name, order_value, C.Customer_ID, Order_ID, 
       CASE 
	   	WHEN order_value > AVG(order_value) OVER() THEN 'Above_Average'
        ELSE 'Below_Average'
       END AS "Customer_Order_Category"
FROM order_values OV, customers C
WHERE C.customer_id = OV.customer_id
ORDER BY order_value DESC;

-- percentage of total sales per product category

CREATE VIEW percentage_sales_per_category AS
WITH sales_per_category AS (
    SELECT C.category_id, C.category_name,
           ROUND(CAST(SUM(OD.Unit_Price * OD.Quantity * (1- OD.discount)) AS NUMERIC), 2) 
		AS total_sales
    FROM categories C, products P, order_details OD
	WHERE C.category_id = P.category_id AND P.product_id = OD.product_id
    GROUP BY C.categ
SELECT category_id, category_name, total_sales,
    ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) AS sales_percentage
FROM sales_per_category
ORDER BY sales_percentage DESC;

-- sales growth per category

CREATE VIEW sales_growth_per_category AS 
WITH month_by_month_per_cat AS (
	SELECT EXTRACT(YEAR FROM order_date) as order_year, 
		EXTRACT(MONTH FROM order_date) as order_month,
		ROUND(CAST(SUM(OD.Unit_Price * OD.Quantity * (1- OD.discount)) AS NUMERIC), 2) 
			AS Monthly_Sales, p.category_id, order_date
	FROM orders o, order_details od, products p
	WHERE o.order_id = od.order_id AND p.product_id = od.product_id
	group by order_month, order_year, p.category_id, order_date
)

SELECT C.category_name, M.category_id, M.Monthly_Sales, order_date, 
	ROUND((Monthly_Sales / LAG(Monthly_Sales) OVER 
		(ORDER BY order_year, order_month) - 1),2) AS Growth_Rate
FROM month_by_month_per_cat M, Categories C
WHERE M.category_id = C.category_id
ORDER BY category_name, order_year, order_month;

-- which customers have had declining orders in a quarter

CREATE VIEW order_decline_quarterly AS 
WITH quarterly_sales AS (
    SELECT o.customer_id, DATE_TRUNC('quarter', o.order_date) AS order_quarter,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS quarterly_total
    FROM orders o, order_details od
    WHERE o.order_id = od.order_id
    GROUP BY o.customer_id, order_quarter
),
quarterly_with_lag AS (
    SELECT customer_id, order_quarter, CAST(quarterly_total AS NUMERIC),
        CAST(LAG(quarterly_total) OVER (PARTITION BY customer_id ORDER BY order_quarter) AS NUMERIC) AS prev_quarter_total
    FROM quarterly_sales
),
quarterly_declines AS (
    SELECT customer_id, order_quarter, 
		ROUND((prev_quarter_total - quarterly_total), 2) AS decline_amount,
        ROUND(
            CASE 
                WHEN prev_quarter_total > 0 THEN ((prev_quarter_total - quarterly_total) / prev_quarter_total) * 100
                ELSE NULL 
            END, 2) AS decline_percentage
    FROM quarterly_with_lag
    WHERE quarterly_total < prev_quarter_total
)

SELECT c.customer_id, c.company_name,qd.decline_amount, qd.decline_percentage,
	o.order_date,
    CASE 
        WHEN EXTRACT(MONTH FROM qd.order_quarter) = 1 THEN 'Q1'
        WHEN EXTRACT(MONTH FROM qd.order_quarter) = 4 THEN 'Q2'
        WHEN EXTRACT(MONTH FROM qd.order_quarter) = 7 THEN 'Q3'
        WHEN EXTRACT(MONTH FROM qd.order_quarter) = 10 THEN 'Q4'
    END AS quarter
FROM customers c, quarterly_declines qd, orders o
WHERE c.customer_id = qd.customer_id
ORDER BY c.customer_id, o.order_date, quarter;
