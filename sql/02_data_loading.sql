/*
====================================================
Imported CSV files in raw tables
Checked if proper imports happened
====================================================
*/


SELECT COUNT(*) 
FROM raw_olist.category_translation;
SELECT COUNT(*) 
FROM raw_olist.products;
SELECT COUNT(*) 
FROM raw_olist.customers;
SELECT COUNT(*)
FROM raw_olist.orders;
SELECT COUNT(*)
FROM raw_olist.order_items;
SELECT COUNT(*)
FROM raw_olist.payments;


/*
====================================================
Tables created - Categories
Inserted data - Categories
====================================================
*/

CREATE TABLE analytics.categories (
    category_id TEXT PRIMARY KEY,
    category_name VARCHAR(120) UNIQUE
);

CREATE TABLE analytics.categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(120) UNIQUE
);

INSERT INTO analytics.categories (category_name)
SELECT DISTINCT
    product_category_name_english
FROM raw_olist.category_translation
WHERE product_category_name_english IS NOT NULL;

SELECT COUNT(*)
FROM analytics.categories;


/*
====================================================
Tables created - products
Inserted data - products
====================================================
*/

CREATE TABLE analytics.products (
    product_id TEXT PRIMARY KEY,
    category_id INT REFERENCES analytics.categories(category_id),
    weight_g INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO analytics.products (product_id, category_id, weight_g)
SELECT
    rp.product_id,
    c.category_id,
    rp.product_weight_g
FROM raw_olist.products rp
LEFT JOIN raw_olist.category_translation ct
    ON rp.product_category_name = ct.product_category_name
LEFT JOIN analytics.categories c
    ON ct.product_category_name_english = c.category_name;

SELECT COUNT(*)
FROM analytics.products;


/*
====================================================
Tables created - customers
Inserted data - customers
====================================================
*/
INSERT INTO analytics.customers (
    customer_unique_id,
    city,
    state,
    signup_date
)
SELECT
    rc.customer_unique_id,
    MIN(rc.customer_city) AS city,
    MIN(rc.customer_state) AS state,
    MIN(DATE(ro.order_purchase_timestamp)) AS signup_date
FROM raw_olist.customers rc
JOIN raw_olist.orders ro
    ON rc.customer_id = ro.customer_id
GROUP BY rc.customer_unique_id;


SELECT customer_unique_id, COUNT(*)
FROM analytics.customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) FROM analytics.customers;

/*
====================================================
Tables created - Orders
Inserted data - Orders
====================================================
*/

CREATE TABLE analytics.orders (
    order_id TEXT PRIMARY KEY,
    customer_id INT REFERENCES analytics.customers(customer_id),
    order_status VARCHAR(30),
    order_date TIMESTAMP,
    delivered_date TIMESTAMP,
    estimated_delivery TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO analytics.orders (
    order_id,
    customer_id,
    order_status,
    order_date,
    delivered_date,
    estimated_delivery
)
SELECT
    ro.order_id,
    ac.customer_id,
    ro.order_status,
    ro.order_purchase_timestamp,
    ro.order_delivered_customer_date,
    ro.order_estimated_delivery_date
FROM raw_olist.orders ro
JOIN raw_olist.customers rc
    ON ro.customer_id = rc.customer_id
JOIN analytics.customers ac
    ON rc.customer_unique_id = ac.customer_unique_id;


SELECT COUNT(*) FROM analytics.orders;

SELECT
    customer_unique_id,
    COUNT(*)
FROM analytics.customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
LIMIT 10;

/*
====================================================
Tables created - Order items
Inserted data - Order items
====================================================
*/


CREATE TABLE analytics.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id TEXT REFERENCES analytics.orders(order_id),
    product_id TEXT REFERENCES analytics.products(product_id),
    quantity INT DEFAULT 1,
    unit_price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    line_total NUMERIC(12,2)
);

INSERT INTO analytics.order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    freight_value,
    line_total
)
SELECT
    roi.order_id,
    roi.product_id,
    1 AS quantity,
    roi.price,
    roi.freight_value,
    (roi.price + roi.freight_value) AS line_total
FROM raw_olist.order_items roi
JOIN analytics.orders ao
    ON roi.order_id = ao.order_id;


/*
====================================================
Tables created - payments
Inserted data - payments
====================================================
*/

create table analytics.payments (
    payment_id SERIAL PRIMARY KEY,
    order_id text references analytics.orders(order_id),
    payment_method varchar(50),
    installments int,
    amount numeric(12,2)
);

insert into analytics.payments (
    order_id,
    payment_method,
    installments,
    amount
)
select
    rp.order_id,
    rp.payment_type,
    rp.payment_installments,
    rp.payment_value
from raw_olist.payments rp
join analytics.orders ao
    on rp.order_id=ao.order_id;

SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.line_total), 2) AS monthly_revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;