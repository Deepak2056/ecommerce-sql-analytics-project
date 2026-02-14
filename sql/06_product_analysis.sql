/*
====================================================
Revenue by category
====================================================
*/

SELECT
    c.category_name,
    ROUND(SUM(oi.line_total),2) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM analytics.order_items oi
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue DESC
LIMIT 10;

/*
====================================================
Top Products Contribution (Pareto within Products)
====================================================
*/

WITH product_revenue AS (
    SELECT
        p.product_id,
        SUM(oi.line_total) AS revenue
    FROM analytics.order_items oi
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    GROUP BY p.product_id
),
ranked AS (
    SELECT
        product_id,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
)

SELECT
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM product_revenue),
        2
    ) AS pct_products_for_80pct_revenue
FROM ranked
WHERE cumulative_revenue <= 0.8 * total_revenue;


/*
====================================================
Basket Size Analysis
====================================================
*/

SELECT
    AVG(items_per_order) AS avg_items_per_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS items_per_order
    FROM analytics.order_items
    GROUP BY order_id
) t;

/*
====================================================
Time Between Purchases (Repeat Customers Only)
====================================================
*/

WITH ordered_purchases AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM analytics.orders
)

SELECT
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (order_date - previous_order_date))
            / 86400
        ),
        2
    ) AS avg_days_between_orders
FROM ordered_purchases
WHERE previous_order_date IS NOT NULL;

