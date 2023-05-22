
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'), ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'), ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'), ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'), ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 -- CASE STUDY QUESTIONS --
  
  
## 1. What is the total amount each customer spent at the restaurant?

SELECT 
    customer_id, SUM(price) AS 'Total Amount'
FROM
    sales,
    menu
WHERE
    sales.product_id = menu.product_id
GROUP BY customer_id;

## 2.How many days has each customer visited the restaurant?

SELECT 
    customer_id,
    COUNT(DISTINCT (order_date)) AS 'Number of days visited'
FROM
    sales
GROUP BY customer_id;

## 3. What was the first item from the menu purchased by each customer?

WITH ordered_sales_cte AS
(
   SELECT customer_id, order_date, product_name,
      ROW_NUMBER() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date) AS ranking
   FROM sales AS s
   JOIN menu AS m
      ON s.product_id = m.product_id
)

SELECT customer_id, product_name
FROM ordered_sales_cte
WHERE ranking = 1
GROUP BY customer_id, product_name;

## 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT 
    product_name, COUNT(sales.product_id) AS 'Most_Purchased'
FROM
    sales,
    menu
WHERE
    sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY Most_Purchased DESC
LIMIT 1;


## 5.Which item was the most popular for each customer?

WITH fav_item_cte AS
(
   SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS order_count,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY COUNT(s.customer_id) DESC) AS ranking
   FROM menu AS m
   JOIN sales AS s
      ON m.product_id = s.product_id
   GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name, order_count
FROM fav_item_cte 
WHERE ranking = 1;

##  6.Which item was purchased first by the customer after they became a member?


WITH member_sales_cte AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date) AS ranking
   FROM sales AS s
   JOIN members AS m
      ON s.customer_id = m.customer_id
   WHERE s.order_date >= m.join_date
)

SELECT s.customer_id, s.order_date, m2.product_name 
FROM member_sales_cte AS s
JOIN menu AS m2
   ON s.product_id = m2.product_id
WHERE ranking = 1;


## 7.Which item was purchased just before the customer became a member?

WITH prior_member_purchased_cte AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
         DENSE_RANK() OVER(PARTITION BY s.customer_id
         ORDER BY s.order_date DESC) AS ranking
   FROM sales AS s
   JOIN members AS m
      ON s.customer_id = m.customer_id
   WHERE s.order_date < m.join_date
)

SELECT s.customer_id, s.order_date, m2.product_name 
FROM prior_member_purchased_cte AS s
JOIN menu AS m2
   ON s.product_id = m2.product_id
WHERE ranking = 1;

## 8.What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_menu_item, 
   SUM(mm.price) AS total_sales
FROM sales AS s
JOIN members AS m
   ON s.customer_id = m.customer_id
JOIN menu AS mm
   ON s.product_id = mm.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

## 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

WITH price_points AS
(
   SELECT *, 
      CASE
         WHEN product_id = 1 THEN price * 20
         ELSE price * 10
      END AS points
   FROM menu
)

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points  p
JOIN sales AS s
   ON p.product_id = s.product_id
GROUP BY s.customer_id;

