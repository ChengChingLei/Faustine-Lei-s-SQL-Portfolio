#--Dataset: Bike Store Relational Database
#--Source: Kaggle https://www.kaggle.com/datasets/dillonmyrick/bike-store-sample-database
#--Queried using: MYSQL
#--Tools of Choice: Aggregate functions, Subqueries, CASE WHEN, PIVOT and CTEs
#--Key findings: 
#---Bike sales peaked in April 2018 during the period from 2016 to 2018, however dropped drastically afterward.
#---Electric bikes are a growing trend, especially popular in California compared to New York and Texas.
#---Road bikes show potential as a category that is reflecting a sports trend since 2017.
#---The average number of items per order is 4.4, having increased from 4.2 in 2016 to 4.5 in 2018, despite an overall drop in sales.
#--Recommendations:
#---Stocks should be reallocated from Rowlette Bikes to other stores, especially Santa Cruz Bikes.


CREATE SCHEMA bikes;

USE bikes;

CREATE TABLE brands(
	brand_id INTEGER PRIMARY KEY,
    brand_name text
    );
CREATE TABLE categories(
	category_id INTEGER PRIMARY KEY,
    category_name text
    );
CREATE TABLE customers (
	customer_id INTEGER PRIMARY KEY,
    first_name varchar(45), 
    last_name varchar(45),
    phone varchar(45),
    email varchar(45),
    street varchar(45),
    city varchar(45),
    state varchar(20),
    zip_code int
    );
CREATE TABLE products(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(45),
    brand_id INT,
    category_id int,
    model_year INT,
    list_price NUMERIC(10,2),
    CONSTRAINT fr_brandid FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
    CONSTRAINT fr_categoryid FOREIGN KEY (category_id) REFERENCES categories(category_id)
    );
ALTER TABLE products
MODIFY product_name text;
CREATE TABLE stores(
	store_id INTEGER PRIMARY KEY,
    store_name varchar(45), 
    phone varchar(45),
    email varchar(45),
    street varchar(45),
    city varchar(20),
    state varchar(5),
    zip_code int
    );
CREATE TABLE staffs(
	staff_id INTEGER PRIMARY KEY,
    first_name varchar(45), 
    last_name varchar(45), 
    email varchar(45),
	phone varchar(45),
    active INT,
    store_id INT,
    manager_id INT,
    CONSTRAINT fr_storeid FOREIGN KEY (store_id) REFERENCES stores(store_id)
    );
CREATE TABLE stocks(
	store_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (store_id, product_id),
    CONSTRAINT fr_stocks_storeid FOREIGN KEY (store_id) REFERENCES stores(store_id),
    CONSTRAINT fr_stocks_productid FOREIGN KEY (product_id) REFERENCES products(product_id)
    );
CREATE TABLE orders(
	order_id INT PRIMARY KEY,
    customer_id INT,
    order_status INT,
    orer_date DATE,
    required_date DATE,
    shipped_date DATE,
    store_id INT,
	staff_id INT,
    CONSTRAINT fr_orders_customerid FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fr_orders_storeid FOREIGN KEY (store_id) REFERENCES stores(store_id),
    CONSTRAINT fr_orders_staffid FOREIGN KEY (staff_id) REFERENCES staffs(staff_id)
    );
ALTER TABLE orders
RENAME COLUMN orer_date TO order_date;
CREATE TABLE order_items(
	order_id INT,
    item_id INT,
    product_id INT,
    quantity INT,
    list_price NUMERIC(10,2),
    discount NUMERIC(3,2),
    PRIMARY KEY (order_id, item_id),
    CONSTRAINT fr_orderitems_orderid FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fr_orderitems_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
    );

#--The sales data covers the period from January 2016 to December 2018.

SELECT EXTRACT(year FROM order_date) AS order_year, EXTRACT(month FROM order_date) AS order_month
FROM orders
GROUP BY order_year, order_month;

#--The 3 bike stores operate in three states respectively: New York, California, and Texas. The customer base is also concentrated in these states. Additionally, the majority of customers, over 70%, are from New York.

SELECT store_id, city, state
FROM stores;
SELECT COUNT(*) AS number_of_customers, state, CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM customers) * 100), '%')  AS percentage 
FROM customers
GROUP BY state;

#--Over these three years, bike sales peaked in 2017. Overall, the sales figures fluctuated, reaching their highest point in April, 2018, after which the figures dropped significantly.

SELECT SUM(oi.quantity) AS units_sold, ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS total_sales, EXTRACT(year FROM o.order_date) AS year
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY year;
SELECT SUM(oi.quantity) AS units_sold, ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS total_sales, EXTRACT(year FROM o.order_date) AS year, EXTRACT(month FROM o.order_date) AS month
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY year, month;

#--Analyzing the sales by store reveals that Baldwin Bikes contributes the majority of sales. Bike sales declined across all three stores in 2018. This decline was particularly significant at Baldwin Bikes in New York, where the sales volume decreased from 2,159 in 2017 to 809 in 2018.

SELECT s.store_name AS store, s.state, ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS total_sales, SUM(oi.quantity) AS units_sold,
    CONCAT(ROUND(SUM(oi.quantity) * 100 / (SELECT SUM(quantity) FROM order_items)), '%') AS percentage,
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS units_sold_2016,
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS units_sold_2017,
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS units_sold_2018
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN stores AS s ON o.store_id = s.store_id
GROUP BY s.store_name, s.state
ORDER BY units_sold DESC;

#--Breaking down the sales by category, we can see that all categories experienced sales drops except for electric bikes, indicating a potential future trend. Another interesting point is that road bikes had no sales in 2016 but quickly became the second largest sales source. It is also noteworthy that the two bikes are the two most expensive categories compared to others.

SELECT c.category_name,
	SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS units_sold_2016,
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS units_sold_2017,
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS units_sold_2018,
    SUM(oi.quantity) AS TTL_units_sold,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount))) AS TTL_sales,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount))/ SUM(oi.quantity)) AS average_price
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY TTL_sales DESC;

#--Zooming in on the sales volume percentage by store in each category, most categories align with the market size. However, Santa Cruz accounts for 26% of electric bike sales volume, and Cyclocross bikes are evidently more popular in New York than in Texas.

SELECT 
    c.category_name,
    CONCAT(ROUND(SUM(CASE WHEN s.store_name = 'Baldwin Bikes' THEN oi.quantity ELSE 0 END) * 100 / SUM(oi.quantity)), '%') AS 'Baldwin Bikes',
    CONCAT(ROUND(SUM(CASE WHEN s.store_name = 'Santa Cruz Bikes' THEN oi.quantity ELSE 0 END) * 100 / SUM(oi.quantity)), '%') AS 'Santa Cruz Bikes',
    CONCAT(ROUND(SUM(CASE WHEN s.store_name = 'Rowlett Bikes' THEN oi.quantity ELSE 0 END) * 100 / SUM(oi.quantity)), '%') AS 'Rowlett Bikes',
    SUM(oi.quantity) AS TTL_units_sold
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
LEFT JOIN stores AS s ON o.store_id = s.store_id
GROUP BY c.category_name;


#--Breaking down the sales by category in each store reveals their primary categories and respective sales trends. Cruisers bikes and Mountain bikes are the most popular categories across all three stores. When all the categories experienced sales drops, Electric bikes showed positive growth across all three stores, while Road bikes sales volume was also increasing in Santa Cruz.

SELECT c.category_name,
	SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS '2016',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS '2017',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS '2018',
    SUM(oi.quantity) AS TTL_units_sold
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
LEFT JOIN stores AS s ON o.store_id = s.store_id
WHERE s.store_name = 'Baldwin Bikes'
GROUP BY c.category_name
ORDER BY TTL_units_sold DESC;

SELECT c.category_name,
	SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS '2016',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS '2017',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS '2018',
    SUM(oi.quantity) AS TTL_units_sold
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
LEFT JOIN stores AS s ON o.store_id = s.store_id
WHERE s.store_name = 'Santa Cruz Bikes'
GROUP BY c.category_name
ORDER BY TTL_units_sold DESC;

SELECT c.category_name,
	SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS '2016',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS '2017',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS '2018',
    SUM(oi.quantity) AS TTL_units_sold
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
LEFT JOIN stores AS s ON o.store_id = s.store_id
WHERE s.store_name = 'Rowlett Bikes'
GROUP BY c.category_name
ORDER BY TTL_units_sold DESC;

#--Electra and Trek are the top-selling brands. Although Electra sold the most bikes overall, Trek led in sales for 2017 and 2018. It is also noteworthy that Sun Bicycles caused a sensation in 2017 but lost attraction quickly in 2018.

SELECT b.brand_name AS brand, 
	SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2016 THEN oi.quantity ELSE 0 END) AS '2016',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2017 THEN oi.quantity ELSE 0 END) AS '2017',
    SUM(CASE WHEN EXTRACT(year FROM o.order_date) = 2018 THEN oi.quantity ELSE 0 END) AS '2018',
    SUM(oi.quantity) AS TTL_units_sold
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN brands AS b ON p.brand_id = b.brand_id
GROUP BY brand
ORDER BY TTL_units_sold DESC;

#--Comparing the main products offered by each brand, Trek focuses on Mountain/Road bikes and leads in electric bikes, whereas Electra specializes in Cruisers and Children's bikes.

SELECT b.brand_name AS brand, 
	SUM(CASE WHEN c.category_name = 'Children Bicycles' THEN oi.quantity ELSE 0 END) AS 'Children Bicycles',
    SUM(CASE WHEN c.category_name = 'Comfort Bicycles' THEN oi.quantity ELSE 0 END) AS 'Comfort Bicycles',
    SUM(CASE WHEN c.category_name = 'Cruisers Bicycles' THEN oi.quantity ELSE 0 END) AS 'Cruisers Bicycles',
    SUM(CASE WHEN c.category_name = 'Cyclocross Bicycles' THEN oi.quantity ELSE 0 END) AS 'Cyclocross Bicycles',
    SUM(CASE WHEN c.category_name = 'Electric Bikes' THEN oi.quantity ELSE 0 END) AS 'Electric Bikes',
    SUM(CASE WHEN c.category_name = 'Mountain Bikes' THEN oi.quantity ELSE 0 END) AS 'Mountain Bikes',
    SUM(CASE WHEN c.category_name = 'Road Bikes' THEN oi.quantity ELSE 0 END) AS 'Road Bikes'
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN brands AS b ON p.brand_id = b.brand_id
LEFT JOIN categories AS c ON p.category_id = c.category_id
GROUP BY brand;

#--Analyzing the ratio of units sold to stock levels, we recommend reallocating more stock from Rowlett Bikes to other stores, particularly Santa Cruz.

WITH order_quantities AS (
    SELECT 
        c.category_name,
        ROUND(SUM(CASE WHEN o.store_id = 1 THEN oi.quantity ELSE 0 END) / 3) AS Baldwin_order_qty,
        ROUND(SUM(CASE WHEN o.store_id = 2 THEN oi.quantity ELSE 0 END) / 3) AS Santa_Cruz_order_qty,
        ROUND(SUM(CASE WHEN o.store_id = 3 THEN oi.quantity ELSE 0 END) / 3) AS Rowlett_order_qty
    FROM order_items AS oi
    LEFT JOIN orders AS o ON oi.order_id = o.order_id
    LEFT JOIN products AS p ON oi.product_id = p.product_id
    LEFT JOIN categories AS c ON p.category_id = c.category_id
    GROUP BY 
        c.category_name),

stock_quantities AS (
    SELECT 
        c.category_name,
        SUM(CASE WHEN st.store_id = 1 THEN st.quantity ELSE 0 END) AS Baldwin_stock_qty,
        SUM(CASE WHEN st.store_id = 2 THEN st.quantity ELSE 0 END) AS Santa_Cruz_stock_qty,
        SUM(CASE WHEN st.store_id = 3 THEN st.quantity ELSE 0 END) AS Rowlett_stock_qty
    FROM stocks AS st
    LEFT JOIN products AS p ON st.product_id = p.product_id
    LEFT JOIN categories AS c ON p.category_id = c.category_id
    GROUP BY 
        c.category_name)
SELECT 
    o.category_name AS category,
    COALESCE(o.baldwin_order_qty, 0) AS 'Baldwin Bikes Order Quantity',
    COALESCE(s.baldwin_stock_qty, 0) AS 'Baldwin Bikes Stock',
    ROUND(s.baldwin_stock_qty / o.baldwin_order_qty) AS 'Baldwin Bikes years of supply',
    COALESCE(o.santa_cruz_order_qty, 0) AS 'Santa Cruz Bikes Order Quantity',
    COALESCE(s.santa_cruz_stock_qty, 0) AS 'Santa Cruz Bikes Stock',
    ROUND(s.santa_cruz_stock_qty / o.santa_cruz_order_qty) AS 'Santa Cruz Bikes years of supply',
    COALESCE(o.rowlett_order_qty, 0) AS 'Rowlett Bikes Order Quantity',
    COALESCE(s.rowlett_stock_qty, 0) AS 'Rowlett Bikes Stock',
    ROUND(s.rowlett_stock_qty / o.rowlett_order_qty) AS 'Rowlett Bikes years of supply'
FROM order_quantities o
LEFT JOIN stock_quantities s ON o.category_name = s.category_name;

#--The average number of units per order is 4.4 in both Santa Cruz and Baldwin Bikes, and 4.5 in Rowlett Bikes. Over the years, this average increased from 4.2 in 2016 to 4.5 in 2018, indicating a growing trend in the number of units purchased per order despise an overall drop in sales.

SELECT 
CASE WHEN store_id = 1 THEN 'Santa Cruz Bikes'
	 WHEN store_id = 2 THEN 'Baldwin Bikes'
     WHEN store_id = 3 THEN 'Rowlett Bikes' END AS stores, ROUND(AVG(count),1) AS avg_items_per_order
FROM (
SELECT oi.order_id, o.store_id AS store_id, SUM(oi.quantity) AS count
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY oi.order_id, o.store_id) AS items_count
GROUP BY store_id;

SELECT 
ROUND(AVG(count),1) AS avg_items_per_order, year
FROM (
SELECT o.store_id AS store_id, SUM(oi.quantity)  AS count, EXTRACT(year FROM o.order_date) AS year
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY oi.order_id, o.store_id, EXTRACT(year FROM o.order_date)) AS items_count
GROUP BY year;

SELECT 
CASE WHEN store_id = 1 THEN 'Santa Cruz Bikes'
	 WHEN store_id = 2 THEN 'Baldwin Bikes'
     WHEN store_id = 3 THEN 'Rowlett Bikes' END AS stores, ROUND(AVG(count),1) AS avg_items_per_order, year
FROM (
SELECT o.store_id AS store_id, SUM(oi.quantity) AS count, EXTRACT(year FROM o.order_date) AS year
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY oi.order_id, o.store_id, EXTRACT(year FROM o.order_date)) AS items_count
GROUP BY store_id, year
ORDER BY stores ASC;











