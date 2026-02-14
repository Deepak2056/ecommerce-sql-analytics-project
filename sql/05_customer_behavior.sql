/*
====================================================
Understanding customer behavior - new vs returning
====================================================
*/

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM analytics.orders
    GROUP BY customer_id
)

SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('month', o.order_date)
             = DATE_TRUNC('month', fp.first_order_date)
        THEN o.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('month', o.order_date)
             > DATE_TRUNC('month', fp.first_order_date)
        THEN o.customer_id END) AS returning_customers
FROM analytics.orders o
JOIN first_purchase fp
    ON o.customer_id = fp.customer_id
GROUP BY 1
ORDER BY 1;

/*
====================================================
Measuring repeat purchase rate
====================================================
*/

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM analytics.orders
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    ROUND(
        COUNT(CASE WHEN total_orders > 1 THEN 1 END) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_pct
FROM customer_orders;

/*
====================================================
distributions of orders per customer
====================================================
*/

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM analytics.orders
    GROUP BY customer_id
)

SELECT
    total_orders,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;

/*
====================================================
Distribution as percentages
====================================================
*/
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM analytics.orders
    GROUP BY customer_id
),
distribution AS (
    SELECT
        total_orders,
        COUNT(*) AS customer_count
    FROM customer_orders
    GROUP BY total_orders
),
totals AS (
    SELECT SUM(customer_count) AS total_customers
    FROM distribution
)

SELECT
    d.total_orders,
    d.customer_count,
    ROUND(d.customer_count * 100.0 / t.total_customers, 2) AS pct_of_customers
FROM distribution d
CROSS JOIN totals t
ORDER BY d.total_orders;

/*
====================================================
Distribution as percentages
====================================================
*/

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM customer_revenue
)

SELECT
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_revenue),
        2
    ) AS pct_customers_needed_for_80pct_revenue
FROM ranked
WHERE cumulative_revenue <= 0.8 * total_revenue;



