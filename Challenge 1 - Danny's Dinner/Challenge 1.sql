-- database: Danny's Dinner.db

/*Database creation*/

-- menu --
CREATE TABLE menu (
  "product_id" INTEGER PRIMARY KEY,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

-- members --
CREATE TABLE members (
  "customer_id" VARCHAR(1) PRIMARY KEY,
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- sales --
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER,
  FOREIGN KEY("product_id") REFERENCES menu("product_id")
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


/*Querying*/
/*1. What is the total amount each customer spent at the restaurant?*/
SELECT
  customer_id,
  SUM(menu.price) as spending
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY spending DESC;

/*2. How many days has each customer visited the restaurant?*/
SELECT
  customer_id,
  COUNT(DISTINCT order_date) as number_of_days
FROM sales
GROUP BY customer_id
ORDER BY number_of_days_ DESC;

/*3. What was the first item from the menu purchased by each customer?*/
SELECT
  customer_id,
  product_id
FROM (
  SELECT
    customer_id,
    product_id,
    RANK() OVER (PARTITION BY customer_id
                ORDER BY order_date ASC) AS ranking
  FROM sales) AS A
WHERE ranking = 1;

/*4. What is the most purchased item on the menu and how many times was it purchased by all customers?*/
SELECT
  menu.product_name,
  COUNT(sales.product_id) as times_purchased
FROM menu
  JOIN sales ON menu.product_id = sales.product_id
GROUP BY menu.product_name
ORDER BY times_purchased DESC
LIMIT 1;

/*5. Which item was the most popular for each customer?*/
SELECT
  customer_id,
  product_id,
  total_orders
FROM (
  SELECT 
    customer_id,
    product_id,
    COUNT(*) AS total_orders,
    RANK() OVER (PARTITION BY customer_id
                 ORDER BY COUNT(*) DESC) AS rnk
  FROM sales
  GROUP BY customer_id, product_id
) ranked
WHERE rnk = 1;

/*6. Which item was purchased first by the customer after they became a member?*/
SELECT customer_id, product_id
FROM (
  SELECT
    s.customer_id,
    order_date,
    product_id,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date ASC) AS rnk
  FROM sales AS s
  JOIN members AS m ON s.customer_id = m.customer_id
  WHERE s.order_date >= m.join_date)
WHERE rnk = 1;

/*7. Which item was purchased just before the customer became a member?*/
SELECT customer_id, product_id
FROM (
  SELECT
    s.customer_id,
    order_date,
    product_id,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS rnk
  FROM sales AS s
  JOIN members AS m ON s.customer_id = m.customer_id
  WHERE s.order_date < m.join_date)
WHERE rnk = 1;

/*8. What is the total items and amount spent for each member before they became a member?*/
SELECT
  s.customer_id,
  COUNT(m.price) AS qty,
  SUM(m.price) AS amount
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
WHERE s.order_date < me.join_date OR me.join_date IS NULL
GROUP BY s.customer_id;

/*9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier
- how many points would each customer have?*/
SELECT customer_id, SUM(points) AS points
FROM (
  SELECT
    s.customer_id,
    CASE
      WHEN m.product_name = 'sushi' THEN price * 10 * 2
      ELSE price * 10
    END AS points
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id) AS sub
GROUP BY customer_id;

/*10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
- how many points do customer A and B have at the end of January?*/
SELECT
  customer_id,
  SUM(points) AS points
FROM (
  SELECT
    s.customer_id,
    m.price,
    CASE
      WHEN (s.order_date < me.join_date
            OR s.order_date > DATE(me.join_date, '+7 days')) THEN
        CASE
          WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
          ELSE m.price * 10
        END
      ELSE m.price * 10 * 2
    END AS points
  FROM sales s
  LEFT JOIN members me ON s.customer_id = me.customer_id
  JOIN menu m ON s.product_id = m.product_id
  WHERE s.customer_id IN ('A', 'B')
  AND s.order_date < '2021-02-01') AS sub
GROUP BY customer_id;

/* Bonus. Recreating the table */
SELECT
  s.customer_id,
  s.order_date,
  m.product_name,
  m.price,
  CASE
    WHEN (me.join_date IS NOT NULL
          AND s.order_date >= me.join_date) THEN 'Y'
    ELSE 'N'
  END AS member 
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members me ON s.customer_id = me.customer_id
ORDER BY s.customer_id, s.order_date, m.product_name;

/*Ranking*/
WITH RECREATED AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
      WHEN (me.join_date IS NOT NULL AND s.order_date >= me.join_date) THEN 'Y'
      ELSE 'N'
    END AS member,
    ROW_NUMBER() OVER (ORDER BY s.customer_id, s.order_date, m.product_name) AS row_id
  FROM sales s
  LEFT JOIN menu m ON s.product_id = m.product_id
  LEFT JOIN members me ON s.customer_id = me.customer_id),
RANKED AS (
  SELECT
    row_id,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS ranking
  FROM RECREATED
  WHERE member = 'Y')
SELECT
  r.customer_id,
  r.order_date,
  r.product_name,
  r.price,
  r.member,
  rk.ranking
FROM RECREATED r
LEFT JOIN RANKED rk ON r.row_id = rk.row_id;