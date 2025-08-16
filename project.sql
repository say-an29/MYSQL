CREATE DATABASE E_COMMERS_SALE;
USE E_COMMERS_SALE;

-- Customers
CREATE TABLE customers (
  customer_id VARCHAR(20) PRIMARY KEY,
  customer_city VARCHAR(20),
  customer_state VARCHAR(35)
);

-- Products
CREATE TABLE products (
  product_id VARCHAR(20) PRIMARY KEY,
  category VARCHAR(65)
);

-- Orders
CREATE TABLE orders (
  order_id VARCHAR(24) PRIMARY KEY,
  customer_id VARCHAR(20) REFERENCES customers(customer_id),
  order_date DATE
);

-- Order Items
CREATE TABLE order_items (
  order_id VARCHAR(24) REFERENCES orders(order_id),
  product_id VARCHAR(20) REFERENCES products(product_id),
  price DECIMAL,
  quantity INT
);

-- Promotions
CREATE TABLE promotions (
  promo_id VARCHAR(25) PRIMARY KEY,
  category VARCHAR(35),
  start_date DATE,
  end_date DATE,
  discount_pct DECIMAL
);
-- Customers
INSERT INTO customers (customer_id, customer_city, customer_state) VALUES
  ('C001', 'New York', 'NY'),
  ('C002', 'San Francisco', 'CA'),
  ('C003', 'Austin', 'TX');

-- Products
INSERT INTO products (product_id, category) VALUES
  ('P001', 'Electronics'),
  ('P002', 'Electronics'),
  ('P003', 'Clothing'),
  ('P004', 'Books');

-- Orders
INSERT INTO orders (order_id, customer_id, order_date) VALUES
  ('O1001', 'C001', '2025-06-10'),
  ('O1002', 'C002', '2025-06-12'),
  ('O1003', 'C001', '2025-07-05'),
  ('O1004', 'C003', '2025-07-07');

-- Order Items
INSERT INTO order_items (order_id, product_id, price, quantity) VALUES
  ('O1001', 'P001', 199.99, 1),
  ('O1001', 'P004', 15.00, 2),
  ('O1002', 'P003', 25.00, 3),
  ('O1003', 'P002', 299.99, 1),
  ('O1003', 'P003', 25.00, 2),
  ('O1004', 'P004', 10.00, 4);

-- Promotions
INSERT INTO promotions (promo_id, category, start_date, end_date, discount_pct) VALUES
  ('PRM01', 'Electronics', '2025-07-01', '2025-07-10', 10),
  ('PRM02', 'Books',       '2025-06-05', '2025-06-15', 20);
  
  WITH monthly_rev AS (
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    p.category,
    c.customer_state,
    SUM(oi.price * oi.quantity) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.product_id
  JOIN customers c ON o.customer_id = c.customer_id
  GROUP BY month, p.category, c.customer_state
)
SELECT
  month,
  category,
  customer_state,
  revenue,
  ROUND((revenue - LAG(revenue) OVER (PARTITION BY category, customer_state ORDER BY month)) / LAG(revenue) OVER (PARTITION BY category, customer_state ORDER BY month) * 100, 2) AS pct_change
FROM monthly_rev
ORDER BY month, category, customer_state;

SELECT cohort_month, purchase_month, revenue
FROM (
  SELECT
    DATE_FORMAT(f.first_date, '%Y-%m') AS cohort_month,
    DATE_FORMAT(o.order_date, '%Y-%m') AS purchase_month,
    SUM(oi.price * oi.quantity) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM orders
    GROUP BY customer_id
  ) f ON o.customer_id = f.customer_id
  GROUP BY cohort_month, purchase_month
) AS cohort_data
ORDER BY cohort_month, purchase_month;

WITH sales_promo AS (
  SELECT
    pr.promo_id,
    SUM(CASE WHEN o.order_date BETWEEN pr.start_date AND pr.end_date THEN oi.price * oi.quantity ELSE 0 END) AS revenue_during,
    SUM(CASE WHEN o.order_date NOT BETWEEN pr.start_date AND pr.end_date THEN oi.price * oi.quantity ELSE 0 END) AS revenue_outside
  FROM promotions pr
  LEFT JOIN products p ON pr.category = p.category
  LEFT JOIN order_items oi ON p.product_id = oi.product_id
  LEFT JOIN orders o ON oi.order_id = o.order_id
  GROUP BY pr.promo_id
)
SELECT
  promo_id,
  revenue_during,
  revenue_outside,
  ROUND((revenue_during - revenue_outside) / revenue_outside * 100, 2) AS pct_change
FROM sales_promo;


