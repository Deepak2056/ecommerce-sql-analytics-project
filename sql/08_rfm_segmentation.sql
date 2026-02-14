/*
====================================================
RFM Segmentation
====================================================
*/

WITH customer_metrics AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.line_total) AS monetary
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
max_date AS (
    SELECT MAX(order_date) AS max_order_date
    FROM analytics.orders
)

SELECT
    cm.customer_id,
    (md.max_order_date - cm.last_purchase_date) AS recency_days,
    cm.frequency,
    ROUND(cm.monetary,2) AS monetary
FROM customer_metrics cm
CROSS JOIN max_date md
LIMIT 20;


/*
====================================================
Convert metrics in to scores(1-5 scale)
====================================================
*/

WITH customer_metrics AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.line_total) AS monetary
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
max_date AS (
    SELECT MAX(order_date) AS max_order_date
    FROM analytics.orders
),
rfm_base AS (
    SELECT
        cm.customer_id,
        EXTRACT(DAY FROM (md.max_order_date - cm.last_purchase_date)) AS recency,
        cm.frequency,
        cm.monetary
    FROM customer_metrics cm
    CROSS JOIN max_date md
)

SELECT
    customer_id,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm_base
LIMIT 20;

/*
====================================================
Creating RFM segments
====================================================
*/

WITH customer_metrics AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.line_total) AS monetary
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
max_date AS (
    SELECT MAX(order_date) AS max_order_date
    FROM analytics.orders
),
rfm_base AS (
    SELECT
        cm.customer_id,
        EXTRACT(DAY FROM (md.max_order_date - cm.last_purchase_date)) AS recency,
        cm.frequency,
        cm.monetary
    FROM customer_metrics cm
    CROSS JOIN max_date md
),
rfm_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)

SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS customer_segment
FROM rfm_scores
LIMIT 50;

/*
====================================================
Revenue contribution by segment
====================================================
*/
WITH customer_metrics AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.line_total) AS monetary
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
max_date AS (
    SELECT MAX(order_date) AS max_order_date
    FROM analytics.orders
),
rfm_base AS (
    SELECT
        cm.customer_id,
        EXTRACT(DAY FROM (md.max_order_date - cm.last_purchase_date)) AS recency,
        cm.frequency,
        cm.monetary
    FROM customer_metrics cm
    CROSS JOIN max_date md
),
rfm_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score,
        monetary
    FROM rfm_base
),
segments AS (
    SELECT
        customer_id,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            ELSE 'Lost Customers'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary),2) AS total_revenue,
    ROUND(
        SUM(monetary) * 100.0 /
        SUM(SUM(monetary)) OVER (),
        2
    ) AS revenue_pct
FROM segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;