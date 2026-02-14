/*
====================================================
Executive KPIs
How many orders
How many customers
How much revenue
What is average order value
====================================================
*/

SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(oi.line_total),2) AS total_revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id;

/*
====================================================
What is monthly order
What is revenue trend
====================================================
*/

SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.line_total),2) AS total_revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_date >= '2016-10-01'
  AND o.order_date <  '2018-09-01'
GROUP BY 1
ORDER BY 1;

/*
====================================================
Identifying valid data window
====================================================
*/

select
    min(order_date) as first_order,
    max(order_date) as last_order
from analytics.orders;


/*
====================================================
Measuring month on month growth
====================================================
*/

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= '2016-10-01'
      AND o.order_date <  '2018-09-01'
    GROUP BY 1
)

SELECT
    month,
    ROUND(revenue,2) AS revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

/*
=============================================================================
Since this shows drops and peaks very sharply, 3 month rolling is recommended
=============================================================================s
*/


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= '2016-10-01'
      AND o.order_date <  '2018-09-01'
    GROUP BY 1
)

SELECT
    month,
    ROUND(revenue,2) AS revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3m_avg
FROM monthly_revenue
ORDER BY month;





































