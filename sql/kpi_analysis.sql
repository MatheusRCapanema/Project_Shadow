WITH max_date_cte AS (
    SELECT MAX(date) AS max_date FROM ads_spend
),

last_30 AS (
    SELECT 
        SUM(spend) AS spend_last,
        SUM(conversions) AS conv_last
    FROM ads_spend, max_date_cte
    WHERE date BETWEEN max_date - INTERVAL '29 days' AND max_date
),

prior_30 AS (
    SELECT 
        SUM(spend) AS spend_prior,
        SUM(conversions) AS conv_prior
    FROM ads_spend, max_date_cte
    WHERE date BETWEEN max_date - INTERVAL '59 days' AND max_date - INTERVAL '30 days'
)

SELECT 
    'Last 30 Days' AS period,
    ROUND(spend_last / NULLIF(conv_last, 0), 2) AS cac,
    ROUND((conv_last * 100) / NULLIF(spend_last, 0), 2) AS roas,
    '-' AS cac_change,
    '-' AS roas_change
FROM last_30
UNION ALL
SELECT 
    'Prior 30 Days' AS period,
    ROUND(spend_prior / NULLIF(conv_prior, 0), 2) AS cac,
    ROUND((conv_prior * 100) / NULLIF(spend_prior, 0), 2) AS roas,
    ROUND(100 * ((spend_last / NULLIF(conv_last, 0) - spend_prior / NULLIF(conv_prior, 0)) / NULLIF(spend_prior / NULLIF(conv_prior, 0), 0)), 2) || '%' AS cac_change,
    ROUND(100 * (((conv_last * 100) / NULLIF(spend_last, 0) - (conv_prior * 100) / NULLIF(spend_prior, 0)) / NULLIF((conv_prior * 100) / NULLIF(spend_prior, 0), 0)), 2) || '%' AS roas_change
FROM last_30, prior_30;