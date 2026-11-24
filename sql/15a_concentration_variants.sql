-- 15a_concentration_variants.sql
-- Does the concentration result survive removing suspect rows? Two plausibility rules:
--   ratio rule: deficit more than 10x assets (equity ratio below -10);
--   size rule: filed as Micro or Small but total assets over 5.1m (the small-company ceiling).
-- Four versions: all rows, minus each rule, minus both. Top 1% = ceil(1% of companies), e.g. 65 of 6,410.
-- Result: the top 1% holds 51.5% to 53.3% in every version, but the pound total moves (0.79bn to 1.14bn),
-- so quote shares, not the pound total. Run as a whole script.
DROP TABLE IF EXISTS res_concentration_variants;
CREATE TABLE res_concentration_variants AS
WITH neg AS (
  SELECT f.company_id, -f.equity AS deficit,
         (f.equity_ratio < -10) AS ratio_flag,
         (s.accounts_type IN ('Micro-entity','Small (total exemption)','Small (abridged)')
           AND f.total_assets > 5100000) AS size_flag
  FROM fact_company_year f
  JOIN stg_company_financials s ON s.company_id = f.company_id AND s.fiscal_year = f.fiscal_year
  WHERE f.in_central_population AND NOT f.is_pseudo_sector
    AND NOT f.is_extreme_equity AND f.state_10 = 'Negative'
), v AS (
  SELECT 'V1 all negative-equity rows' AS variant, company_id, deficit FROM neg
  UNION ALL SELECT 'V2 excl ratio below -10', company_id, deficit FROM neg WHERE NOT ratio_flag
  UNION ALL SELECT 'V3 excl small-type with assets over 5.1m', company_id, deficit FROM neg WHERE NOT size_flag
  UNION ALL SELECT 'V4 excl both', company_id, deficit FROM neg WHERE NOT ratio_flag AND NOT size_flag
), r AS (
  SELECT variant, deficit,
         row_number() OVER (PARTITION BY variant ORDER BY deficit DESC, company_id) AS rnk,
         count(*) OVER (PARTITION BY variant) AS total_n,
         sum(deficit) OVER (PARTITION BY variant) AS total_deficit,
         sum(deficit) OVER (PARTITION BY variant ORDER BY deficit DESC, company_id) AS running
  FROM v
)
SELECT variant, max(total_n) AS n, max(total_deficit) AS total_deficit,
       round(100.0 * max(running) FILTER (WHERE rnk <= ceil(total_n * 0.01)) / max(total_deficit), 1) AS top1pct_share,
       round(100.0 * max(running) FILTER (WHERE rnk <= ceil(total_n * 0.10)) / max(total_deficit), 1) AS top10pct_share,
       round(100.0 * max(running) FILTER (WHERE rnk = 10) / max(total_deficit), 1) AS top10_companies_share
FROM r GROUP BY variant;

SELECT * FROM res_concentration_variants ORDER BY variant;
