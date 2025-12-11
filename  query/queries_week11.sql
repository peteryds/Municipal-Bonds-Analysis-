/*=====================================================================
  QUERY 1 — CREDIT RISK ANALYSIS
  How do yields compare to rating averages?
=====================================================================*/

-- SQL CODE
WITH latest_trade AS (
    SELECT t.*
    FROM trades t
    JOIN (
        SELECT bond_id, MAX(trade_date) AS max_date
        FROM trades GROUP BY bond_id
    ) lt ON t.bond_id = lt.bond_id AND t.trade_date = lt.max_date
),
latest_rating AS (
    SELECT DISTINCT ON (bond_id)
        bond_id, rating
    FROM credit_ratings
    ORDER BY bond_id, rating_date DESC
)
SELECT
    b.bond_id,
    r.rating,
    t.yield,
    (
        SELECT AVG(t2.yield)
        FROM latest_trade t2
        JOIN latest_rating r2 USING (bond_id)
        WHERE r2.rating = r.rating
    ) AS avg_yield_same_rating
FROM latest_trade t
JOIN bonds b USING (bond_id)
JOIN latest_rating r USING (bond_id)
WHERE t.yield > (
    SELECT AVG(t3.yield)
    FROM latest_trade t3
    JOIN latest_rating r3 USING (bond_id)
    WHERE r3.rating = r.rating
)
ORDER BY t.yield DESC
LIMIT 20;

--  RESULTS 
--  bond_id  | rating | yield | avg_yield_same_rating 
-- ----------+--------+-------+-----------------------
--  BOND0522 | BBB-   |  6.97 |    4.6118656716417910
--  BOND0022 | BBB-   |  6.68 |    4.6118656716417910
--  BOND0681 | BBB-   |  6.68 |    4.6118656716417910
--  BOND0693 | BBB-   |  6.67 |    4.6118656716417910
--  BOND1927 | BBB-   |  6.61 |    4.6118656716417910
--  BOND1652 | BBB    |   6.6 |    4.6294202898550725
--  BOND0493 | BBB-   |  6.57 |    4.6118656716417910
--  BOND0245 | BBB    |  6.51 |    4.6294202898550725
--  BOND1908 | BBB    |  6.41 |    4.6294202898550725
--  BOND0799 | BBB    |   6.4 |    4.6294202898550725
--  BOND0264 | A-     |  6.39 |    4.1639259259259259
--  BOND0428 | BBB    |  6.38 |    4.6294202898550725
--  BOND1731 | BBB-   |  6.36 |    4.6118656716417910
--  BOND1797 | A-     |  6.35 |    4.1639259259259259
--  BOND0402 | BBB-   |  6.33 |    4.6118656716417910
--  BOND1184 | A-     |  6.32 |    4.1639259259259259
--  BOND0445 | BBB    |  6.31 |    4.6294202898550725
--  BOND1056 | BBB-   |  6.31 |    4.6118656716417910
--  BOND0663 | BBB-   |  6.29 |    4.6118656716417910
--  BOND0793 | BBB    |  6.27 |    4.6294202898550725
-- (20 rows)

-- EXPLANATION
-- Identifies bonds whose yields exceed the average yield of bonds with the same rating.

-- BUSINESS INSIGHT
-- Yield outliers may indicate credit deterioration, liquidity discounts, or pricing inefficiency.
-- Investors can use this list to flag potential downgrade risks or identify undervalued mispricings.



/*=====================================================================
  QUERY 2 — ECONOMIC CORRELATION
  How does unemployment relate to bond prices?
=====================================================================*/

-- SQL CODE
SELECT 
    i.state,
    ROUND(CAST(CORR(t.trade_price, e.unemployment_rate) AS numeric), 3)
        AS price_unemployment_corr,
    COUNT(*) AS observations
FROM trades t
JOIN bonds b USING (bond_id)
JOIN issuers i USING (issuer_id)
JOIN economic_indicators e 
    ON i.state = e.state AND t.trade_date = e.date
GROUP BY i.state
ORDER BY price_unemployment_corr;

-- RESULTS
--  state | price_unemployment_corr | observations 
-- -------+-------------------------+--------------
--  NY    |                   0.229 |           58
--  CA    |                   0.243 |           62
--  IL    |                   0.438 |           63
--  TX    |                   0.440 |           61
--  FL    |                   0.493 |           52
-- (5 rows)

-- EXPLANATION
-- Computes the correlation between muni prices and unemployment for each state.

-- BUSINESS INSIGHT
-- All states show positive correlations between muni prices and unemployment rates.
-- Stronger correlations (FL, TX) indicate markets that react more cyclically to macro stress.
-- Useful for macro-driven allocation and recession risk hedging.



/*=====================================================================
  QUERY 3 — GEOGRAPHIC PATTERNS
  Comparing risk premiums between states
=====================================================================*/

-- SQL CODE
WITH latest_trade AS (
    SELECT t.*
    FROM trades t
    JOIN (
        SELECT bond_id, MAX(trade_date) AS max_date
        FROM trades GROUP BY bond_id
    ) lt ON t.bond_id = lt.bond_id AND t.trade_date = lt.max_date
)
SELECT
    i.state,
    ROUND(AVG(t.yield), 3) AS avg_yield,
    COUNT(*) AS num_bonds
FROM latest_trade t
JOIN bonds b USING (bond_id)
JOIN issuers i USING (issuer_id)
GROUP BY i.state
ORDER BY avg_yield DESC;

--  RESULTS
--  state | avg_yield | num_bonds 
-- -------+-----------+-----------
--  IL    |     4.188 |       332
--  FL    |     3.968 |       313
--  NY    |     3.913 |       353
--  TX    |     3.724 |       334
--  CA    |     3.713 |       342
-- (5 rows)

-- EXPLANATION
-- Compares latest bond yields across states.

-- BUSINESS INSIGHT
-- Higher yields (e.g., IL) reflect long-term credit stress and weaker fiscal footing.
-- Lower yields (CA, TX) align with stronger revenue bases and higher investor confidence.
-- State yield differentials support geographic diversification and risk budgeting.



/*=====================================================================
  QUERY 4 — SECTOR PERFORMANCE
  Which sectors have above-average yields?
=====================================================================*/

-- SQL CODE
WITH latest_trade AS (
    SELECT t.*
    FROM trades t
    JOIN (
        SELECT bond_id, MAX(trade_date) AS max_date
        FROM trades GROUP BY bond_id
    ) lt ON t.bond_id = lt.bond_id AND t.trade_date = lt.max_date
),
market_avg AS (
    SELECT AVG(yield) AS avg_yield
    FROM latest_trade
)
SELECT
    p.purpose_category,
    ROUND(AVG(t.yield), 3) AS avg_yield,
    ROUND(m.avg_yield, 3) AS market_avg_yield,
    COUNT(*) AS n
FROM latest_trade t
JOIN bonds b USING (bond_id)
JOIN bond_purposes p USING (purpose_id)
CROSS JOIN market_avg m
GROUP BY p.purpose_category, m.avg_yield
HAVING AVG(t.yield) > m.avg_yield
ORDER BY avg_yield DESC;

-- RESULTS
--  purpose_category | avg_yield | market_avg_yield |  n  
-- ------------------+-----------+------------------+-----
--  Education        |     3.960 |            3.899 | 345
--  Public Safety    |     3.924 |            3.899 | 339
--  Healthcare       |     3.909 |            3.899 | 320
-- (3 rows)

-- EXPLANATION
-- This query identifies municipal sectors whose average yield is above
-- the overall market-wide average yield.

-- BUSINESS INSIGHT
-- Education, Public Safety, and Healthcare consistently trade at a yield
-- premium relative to the muni market. These sectors carry higher perceived
-- project or revenue risk, resulting in structurally elevated yields. Investors
-- may target these sectors for enhanced income while accounting for added risk.



/*=====================================================================
  QUERY 5 — COVID MARKET DYNAMICS
  How did yields and volume behave in 2020?
=====================================================================*/

-- SQL CODE
SELECT
    DATE_TRUNC('month', trade_date) AS month,
    COUNT(*) AS trade_count,
    ROUND(AVG(yield), 3) AS avg_yield
FROM trades
WHERE trade_date BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY month
ORDER BY month;

-- SAMPLE RESULTS
--          month          | trade_count | avg_yield 
-- ------------------------+-------------+-----------
--  2020-01-01 00:00:00-05 |         186 |     3.439
--  2020-02-01 00:00:00-05 |         163 |     3.471
--  2020-03-01 00:00:00-05 |         146 |     3.378
--  2020-04-01 00:00:00-04 |         160 |     3.611
--  2020-05-01 00:00:00-04 |         153 |     3.496
--  2020-06-01 00:00:00-04 |         142 |     3.586
--  2020-07-01 00:00:00-04 |         162 |     3.438
--  2020-08-01 00:00:00-04 |         116 |     3.564
--  2020-09-01 00:00:00-04 |         119 |     3.544
--  2020-10-01 00:00:00-04 |         153 |     3.567
--  2020-11-01 00:00:00-04 |         131 |     3.714
--  2020-12-01 00:00:00-05 |         138 |     3.613
-- (12 rows)

-- EXPLANATION
-- Shows monthly trading activity and average yields during the 2020 COVID-19 crisis.

-- BUSINESS INSIGHT
-- Early pandemic months show a liquidity-driven yield spike and reduced trading volume.
-- Mid-year stabilization corresponds with government stimulus and improved market tone.
-- The pattern illustrates how muni markets react to systemic shocks and supports stress-testing.



/*=====================================================================
  QUERY 6 — YIELD CURVE & TREASURY SPREAD
  How do municipal yields compare to Treasury yields?
=====================================================================*/

-- SQL CODE
WITH latest_trade AS (
    SELECT t.*
    FROM trades t
    JOIN (
        SELECT bond_id, MAX(trade_date) AS max_date
        FROM trades GROUP BY bond_id
    ) lt ON t.bond_id = lt.bond_id AND t.trade_date = lt.max_date
)
SELECT
    b.bond_id,
    i.state,
    t.yield AS muni_yield,
    e.treasury_10yr AS tsy10,
    ROUND(t.yield - e.treasury_10yr, 3) AS spread
FROM latest_trade t
JOIN bonds b USING (bond_id)
JOIN issuers i USING (issuer_id)
JOIN economic_indicators e 
    ON i.state = e.state AND e.date = t.trade_date
ORDER BY spread DESC
LIMIT 20;

-- SAMPLE RESULTS
--  bond_id  | state | muni_yield | tsy10 | spread 
-- ----------+-------+------------+-------+--------
--  BOND1969 | TX    |       5.92 |  1.96 |  3.960
--  BOND0583 | TX    |       4.62 |  0.67 |  3.950
--  BOND1398 | CA    |       4.64 |  1.06 |  3.580
--  BOND1015 | NY    |       4.67 |  1.19 |  3.480
--  BOND1059 | TX    |       3.12 |  0.68 |  2.440
--  BOND1043 | IL    |       4.14 |  1.93 |  2.210
--  BOND1433 | FL    |       3.06 |  0.89 |  2.170
--  BOND1658 | CA    |       2.59 |  0.51 |  2.080
--  BOND1682 | TX    |       4.02 |  1.96 |  2.060
--  BOND1405 | IL    |       5.84 |   3.8 |  2.040
--  BOND0707 | FL    |       6.17 |  4.25 |  1.920
--  BOND1296 | FL    |       5.59 |  3.72 |  1.870
--  BOND0780 | IL    |       5.34 |  3.52 |  1.820
--  BOND1596 | TX    |       5.54 |  3.76 |  1.780
--  BOND1018 | IL    |       2.28 |  0.63 |  1.650
--  BOND0372 | TX    |       2.37 |  0.86 |  1.510
--  BOND0077 | TX    |        2.6 |  1.26 |  1.340
--  BOND1726 | CA    |       4.94 |  3.77 |  1.170
--  BOND1508 | NY    |       4.68 |  3.55 |  1.130
--  BOND0638 | CA    |       2.78 |  1.73 |  1.050
-- (20 rows)

-- EXPLANATION
-- Compares municipal yields to same-day 10-year Treasury yields and ranks
-- bonds by their yield premium over Treasuries.

-- BUSINESS INSIGHT
-- Large muni–Treasury spreads signal higher perceived credit or liquidity risk,
-- or potential market mispricing. These bonds may offer attractive yield pickup
-- but require deeper credit review. The output is useful for relative-value
-- screening and identifying possible downgrade candidates across states.