# Project Description:
The data for this analysis was taken from: https://github.com/pthom/northwind_psql/tree/master?tab=readme-ov-file 

This project is a sales dashboard for the fictional company of Northwind. The finalized dashboard contains visualizations for sales growth and insights into top customers and products. The dashboard was created in Tableau Desktop with the use of SQL queries made in PGAdmin4. The queries involve a series of joins, CTE's, window functions, and case statements, exported as views to Tableau.

## ER Diagram:
<img width="512" alt="ER" src="https://github.com/user-attachments/assets/c2e13ef6-2bc0-45ba-a22b-4c52709beacc" />


## SQL Query Breakdown:
- **Employee_Sales**: Joins Employee, Orders, and Order_Details on employee_id and order_id respectively in a CTE, then using RANK() to pull the rankings of employees with regards to sales volume
- **Sales_Growth_Per_Month**: Joins Orders and Order_Detials on order_id then calculating the monthly sales and using a LAG() function to calculate the growth in sales per month
- **Customer_Order_Tier**: Joins Orders and Order_Details on order_id to find order_value per customer (customer_id), then using a case statement to catogorize the customer as above or below average order value
  - note: can adjust the case statement to make categories based on business needs such as specific ranges in order value or quantiles
- **Percentage_Sales_Per_Category**: Joins Categories to Products and Products to Order_Details on category_id and product_id respectively then calculating total sales of the category and the percentage of total sales
  - note: could include a date attribute to visualize changes in category popularity/sales volume **done**
- **Sales_Growth_Per_Category**: Joins Orders to Order_Details and Order_Details to Products on order_id and product_id respectively, then using a LAG() function to calculate growth in sales per month per category after joining Category to CTE through category_id
- **Order_Decline_Quarterly**: First calculates quarterly sales through a join on order_id from Order and Order_Details, then finds the previous quarter's sales through a LAG() function. Afterwards, a case statement categorizes customers who have had an order value decline from a previous quarter, allowing a filter on customers with a declinging order value and using another case statement to map dates to quarter labels (Q1, Q2, ...)

## Tableau Dashboard:
![northwind_dashboard](https://github.com/user-attachments/assets/625762b1-08aa-41c6-93a2-7301d13c5d7c)

