/*==============================================================
 Query 1 — Time Series Issuance Trend + YoY Change
 (CTE + Cumulative Metrics)
==============================================================*/

WITH base AS (
    SELECT
        EXTRACT(YEAR FROM b.issue_date) AS year,
        i.state,
        bp.purpose_category
    FROM bonds b
    JOIN issuers i  ON b.issuer_id = i.issuer_id
    JOIN bond_purposes bp ON b.purpose_id = bp.purpose_id
    WHERE b.issue_date IS NOT NULL
),
summary AS (
    SELECT
        year,
        purpose_category,
        COUNT(*) AS issuance_count
    FROM base
    GROUP BY year, purpose_category
)
SELECT
    year,
    purpose_category,
    issuance_count,
    issuance_count
        - LAG(issuance_count) OVER (
            PARTITION BY purpose_category
            ORDER BY year
        ) AS yoy_change
FROM summary
ORDER BY year, purpose_category;

/*==============================================================
 Query 2 — Yield Moving Average (Window Function)
 (OVER, PARTITION BY, ORDER BY)
==============================================================*/

SELECT
    b.bond_id,
    b.duration,
    t.yield,
    DATE_TRUNC('month', t.trade_date) AS month,
    AVG(t.yield) OVER (
        PARTITION BY b.bond_id
        ORDER BY DATE_TRUNC('month', t.trade_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_yield
FROM trades t
JOIN bonds b ON t.bond_id = b.bond_id
WHERE t.yield IS NOT NULL;


/*==============================================================
 Query 3 — Rating Distribution + Ranking
 (DENSE_RANK)
==============================================================*/

SELECT
    b.bond_id,
    cr.rating,
    cr.rating_agency,
    DENSE_RANK() OVER (
        PARTITION BY cr.rating_agency
        ORDER BY cr.rating
    ) AS rating_rank
FROM credit_ratings cr
JOIN bonds b ON cr.bond_id = b.bond_id;


/*==============================================================
 Query 4 — State-level Yield Comparison (CTE)
==============================================================*/

WITH state_yields AS (
    SELECT
        i.state,
        AVG(t.yield) AS avg_yield,
        STDDEV(t.yield) AS sd_yield
    FROM trades t
    JOIN bonds b ON t.bond_id = b.bond_id
    JOIN issuers i ON b.issuer_id = i.issuer_id
    GROUP BY i.state
)
SELECT *
FROM state_yields
ORDER BY avg_yield DESC;

/*==============================================================
 Query 5 — Sector Performance for Tax-Exempt Bonds
==============================================================*/

WITH base AS (
    SELECT
        bp.purpose_category,
        COUNT(*) AS total_bonds
    FROM bonds b
    JOIN bond_purposes bp ON b.purpose_id = bp.purpose_id
    WHERE b.tax_status = 'Tax-Exempt'
    GROUP BY bp.purpose_category
)
SELECT *
FROM base
ORDER BY total_bonds DESC;