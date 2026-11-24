-- 12a_wilson_region.sql
-- Wilson 95% intervals (z = 1.96) for the share with negative equity in each region.
-- x = negative-equity companies, n = all companies in the region. Unknown region is left out (it isn't a place).
DROP TABLE IF EXISTS res_wilson_region;
CREATE TABLE res_wilson_region AS
WITH c AS (
  SELECT r.region,
         count(*)::numeric AS n,
         (count(*) FILTER (WHERE f.state_10 = 'Negative'))::numeric AS x
  FROM fact_company_year f
  JOIN dim_region r ON r.region_key = f.region_key
  WHERE f.in_central_population AND f.region_key <> 0
  GROUP BY r.region
), p AS (
  SELECT region, n, x, x / n AS p FROM c
)
SELECT region, n::int AS n, x::int AS x,
       round(100 * p, 1) AS pct_negative,
       round(100 * (p + 1.96*1.96/(2*n) - 1.96 * sqrt(p*(1-p)/n + 1.96*1.96/(4*n*n))) / (1 + 1.96*1.96/n), 1) AS ci_low,
       round(100 * (p + 1.96*1.96/(2*n) + 1.96 * sqrt(p*(1-p)/n + 1.96*1.96/(4*n*n))) / (1 + 1.96*1.96/n), 1) AS ci_high
FROM p;

SELECT * FROM res_wilson_region ORDER BY pct_negative DESC;
