WITH MonthRevenue AS (
    SELECT
        EXTRACT(YEAR FROM orders.order_date) AS YEAR,
        EXTRACT(MONTH FROM orders.order_date) AS MONTH,
        SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS Month_Revenue
	FROM
        orders
    INNER JOIN
        order_details ON orders.order_id = order_details.order_id
    GROUP BY
        EXTRACT(YEAR FROM orders.order_date),
        EXTRACT(MONTH FROM orders.order_date)
),
AcumulatedRevenue AS (
    SELECT
        YEAR,
        MONTH,
        Month_Revenue,
        SUM(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) AS Revenue_YTD
    FROM
        MonthRevenue
)
SELECT
    YEAR,
    MONTH,
    Month_Revenue,
	Month_Revenue - LAG(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) AS Month_Diference,
	Revenue_YTD,
    (Month_Revenue - LAG(Month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH)) / LAG(month_Revenue) OVER (PARTITION BY YEAR ORDER BY MONTH) * 100 AS Month_Change_Percent
FROM
    AcumulatedRevenue
ORDER BY
    YEAR, MONTH;
