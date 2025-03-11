--Retrieve the names and email addresses of all customers.
SELECT product_name, category_name
FROM production.products as pr
INNER JOIN
production.categories as cr ON pr.category_id=cr.category_id


--Retrieve the names and email addresses of all customers.
SELECT CONCAT(first_name,' ',last_name) as name, email
FROM sales.customers

--Show the total number of orders placed.
SELECT COUNT(order_id) as total_order, order_status
FROM sales.orders
GROUP BY order_status
ORDER BY order_status ASC

--Find the customers who have spent more than $30000 in total.
WITH order_prices as(
SELECT order_id, SUM(list_price*(1-discount)*quantity) AS order_price
FROM sales.order_items
GROUP BY order_id
)

SELECT o.customer_id, SUM(order_price) total_spending
FROM order_prices as op
INNER JOIN 
sales.orders as o ON op.order_id=o.order_id
INNER JOIN sales.customers as c ON o.customer_id=c.customer_id
GROUP BY o.customer_id
HAVING SUM(order_price)>=30000

--List the top 3 best-selling products in terms of quantity.
SELECT TOP(3) o.product_id, p.product_name, SUM(quantity) as total_quantity
FROM sales.order_items as o
INNER JOIN 
production.products as p ON o.product_id=p.product_id
GROUP BY o.product_id,p.product_name
ORDER BY total_quantity DESC

--Show the number of orders shipped after than the required date each month between 2016-2018
WITH delayed_orders as (
	SELECT order_id,order_date,MONTH(order_date) month, YEAR(order_date) year,
	CASE 
		WHEN shipped_date>required_date THEN 1
		ELSE 0
	END AS delayed
	FROM sales.orders
	WHERE order_date BETWEEN '2016-01-01' AND '2018-12-31')

SELECT month,year, SUM(delayed) as number_of_delays
FROM delayed_orders
GROUP BY month, year
ORDER BY year, month

--Display the products that have yet to be sold.
SELECT product_name
FROM production.products
WHERE product_id NOT IN (
	SELECT product_id
	FROM sales.order_items)

--Calculate the total revenue generated top 5 product category.
SELECT category_name, FORMAT(SUM(o.list_price*quantity*(1-discount)),'C', 'en-US') as revenue
FROM sales.order_items o
INNER JOIN
production.products p ON o.product_id=p.product_id
INNER JOIN
production.categories c ON c.category_id=p.category_id
GROUP BY category_name

--Segment customers based on their purchase history (e.g., frequent buyers, one-time purchasers, etc.):

--High Profile Customers are customers who generate significant revenue through large (spending > $5,000) or frequent purchases (orders > 2).
--Low Profile Customers: Customers who contribute less revenue, making occasional (spending < $4,999) or low-priced purchases (orders < 3).

WITH customer_orders as (

	SELECT o.order_id,c.customer_id, SUM(list_price*quantity*(1-discount)) AS order_price
	FROM sales.order_items oi
	INNER JOIN
	sales.orders o ON oi.order_id=o.order_id
	INNER JOIN
	sales.customers c ON c.customer_id=o.customer_id
	GROUP BY o.order_id,c.customer_id
	),

summary as (
SELECT customer_id, SUM(order_price) as total_purchase, COUNT(customer_id) as order_count,
CASE
	WHEN SUM(order_price)>5000 OR COUNT(customer_id)>2 THEN 'High Profile'
	ELSE 'Low Profile'
	END as segment
FROM customer_orders
GROUP BY customer_id
)

SELECT segment, COUNT(*) as number_of_customers
FROM summary
GROUP BY segment


--Find stores that increased their revenue by more than 20% over the previous year, with store name, current year revenue and percentage of revenue increase.
WITH store_revenue as(
	SELECT YEAR(order_date)as date, s.store_name, SUM(list_price*quantity*(1-discount)) as revenue
	FROM sales.order_items oi
	INNER JOIN 
	sales.orders o ON o.order_id=oi.order_id
	INNER JOIN
	sales.stores s ON s.store_id=o.store_id
	GROUP BY YEAR(order_date), store_name
	),

change_data as(
SELECT *, CAST(100*ROUND((revenue-LAG(revenue) OVER(PARTITION BY store_name ORDER BY date))/LAG(revenue) OVER(PARTITION BY store_name ORDER BY date),3) AS DECIMAL(10,2)) as change
FROM store_revenue)

SELECT date,store_name, FORMAT(revenue,'C', 'en-US') as revenue, CONCAT(change,'%') as change_pct
FROM change_data
WHERE change IS NOT NULL
AND change>0.20






