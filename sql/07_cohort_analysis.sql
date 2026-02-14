/*
====================================================
Lets label customers by their first purchase month
====================================================
*/


SELECT
    customer_id,
    DATE_TRUNC('month', MIN(order_date)) AS cohort_month
FROM analytics.orders
GROUP BY customer_id
ORDER BY cohort_month
LIMIT 20;
------Customers who joined in the same month — how long did they stay active?-------
WITH cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM analytics.orders
    GROUP BY customer_id
)

SELECT
    c.cohort_month,
    DATE_TRUNC('month', o.order_date) AS order_month,
    COUNT(DISTINCT o.customer_id) AS active_customers
FROM analytics.orders o
JOIN cohort c
    ON o.customer_id = c.customer_id
GROUP BY 1, 2
ORDER BY 1, 2;

/*
====================================================
calculating months since first purchase
====================================================
*/

WITH cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM analytics.orders
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM analytics.orders o
    JOIN cohort c
        ON o.customer_id = c.customer_id
    GROUP BY 1, 2
)

SELECT
    cohort_month,
    order_month,
    (
        EXTRACT(YEAR FROM age(order_month, cohort_month)) * 12 +
        EXTRACT(MONTH FROM age(order_month, cohort_month))
    ) AS months_since_first_purchase,
    active_customers
FROM cohort_activity
ORDER BY cohort_month, months_since_first_purchase;

/*
====================================================
Building retention percentages
====================================================
*/


WITH cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM analytics.orders
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM analytics.orders o
    JOIN cohort c
        ON o.customer_id = c.customer_id
    GROUP BY 1, 2
),
cohort_size AS (
    SELECT
        cohort_month,
        active_customers AS cohort_customers
    FROM cohort_activity
    WHERE cohort_month = order_month
)

SELECT
    ca.cohort_month,
    (
        EXTRACT(YEAR FROM age(ca.order_month, ca.cohort_month)) * 12 +
        EXTRACT(MONTH FROM age(ca.order_month, ca.cohort_month))
    ) AS month_number,
    ROUND(
        ca.active_customers * 100.0 / cs.cohort_customers,
        2
    ) AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs
    ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, month_number;

/*
====================================================
ordering by cohort month
====================================================
*/

SELECT *
FROM (
    -- your previous cohort matrix query
    WITH cohort AS (
        SELECT
            customer_id,
            DATE_TRUNC('month', MIN(order_date)) AS cohort_month
        FROM analytics.orders
        GROUP BY customer_id
    ),
    cohort_activity AS (
        SELECT
            c.cohort_month,
            DATE_TRUNC('month', o.order_date) AS order_month,
            COUNT(DISTINCT o.customer_id) AS active_customers
        FROM analytics.orders o
        JOIN cohort c
            ON o.customer_id = c.customer_id
        GROUP BY 1, 2
    ),
    cohort_size AS (
        SELECT
            cohort_month,
            active_customers AS cohort_customers
        FROM cohort_activity
        WHERE cohort_month = order_month
    )
    SELECT
        ca.cohort_month,
        (
            EXTRACT(YEAR FROM age(ca.order_month, ca.cohort_month)) * 12 +
            EXTRACT(MONTH FROM age(ca.order_month, ca.cohort_month))
        ) AS month_number,
        ROUND(
            ca.active_customers * 100.0 / cs.cohort_customers,
            2
        ) AS retention_pct
    FROM cohort_activity ca
    JOIN cohort_size cs
        ON ca.cohort_month = cs.cohort_month
) t
WHERE cohort_month = '2017-01-01'
ORDER BY month_number;