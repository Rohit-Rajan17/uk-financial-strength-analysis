-- 11_concentration.sql
-- Concentration of negative equity: each negative-equity company's deficit (-equity), sorted largest first,
-- with a running total. Same population as before: central, no pseudo-sectors, no extreme-equity rows.
-- Expect 6,410 companies, total deficit 1,144,384,034. Quote shares, not the pound total (see 15b).
DROP TABLE IF EXISTS res_concentration;
CREATE TABLE res_concentration AS
WITH neg AS (
  SELECT company_id, -equity AS deficit
  FROM fact_company_year
  WHERE in_central_population AND NOT is_pseudo_sector
    AND NOT is_extreme_equity AND state_10 = 'Negative'
), r AS (
  SELECT company_id, deficit,
         row_number() OVER (ORDER BY deficit DESC) AS rnk,
         count(*) OVER () AS total_n,
         sum(deficit) OVER () AS total_deficit,
         sum(deficit) OVER (ORDER BY deficit DESC, company_id) AS running_deficit
  FROM neg
)
SELECT rnk, deficit, round(100.0*rnk/total_n,2) AS pct_of_companies,
       round(100.0*running_deficit/total_deficit,1) AS cum_pct_of_deficit
FROM r;

SELECT count(*) AS n, sum(deficit) AS total_deficit, max(deficit) AS biggest
FROM res_concentration;

SELECT 'top 1%' AS grp, max(cum_pct_of_deficit) AS cum_pct FROM res_concentration WHERE pct_of_companies <= 1
UNION ALL SELECT 'top 5%',  max(cum_pct_of_deficit) FROM res_concentration WHERE pct_of_companies <= 5
UNION ALL SELECT 'top 10%', max(cum_pct_of_deficit) FROM res_concentration WHERE pct_of_companies <= 10
UNION ALL SELECT 'top 20%', max(cum_pct_of_deficit) FROM res_concentration WHERE pct_of_companies <= 20
UNION ALL SELECT 'top 10 companies', cum_pct_of_deficit FROM res_concentration WHERE rnk = 10
UNION ALL SELECT 'top 50 companies', cum_pct_of_deficit FROM res_concentration WHERE rnk = 50;
