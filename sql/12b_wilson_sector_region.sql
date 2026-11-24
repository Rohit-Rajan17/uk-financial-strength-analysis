-- 12b_wilson_sector_region.sql
-- Wilson 95% intervals for every sector x region cell with at least 30 companies (147 cells),
-- ranked by the LOW bound, so a small cell with a lucky high share can't jump ahead of a big, steady one.
-- Baseline 20.3% = negative share across the 25,537 companies in the sector x region table.
-- Not adjusted for multiple comparisons.
DROP TABLE IF EXISTS res_wilson_sector_region;
CREATE TABLE res_wilson_sector_region AS
WITH c AS (
  SELECT s.sic_section, r.region,
         count(*)::numeric AS n,
         (count(*) FILTER (WHERE f.state_10 = 'Negative'))::numeric AS x
  FROM fact_company_year f
  JOIN dim_sector s ON s.sector_key = f.sector_key
  JOIN dim_region r ON r.region_key = f.region_key
  WHERE f.in_central_population AND NOT f.is_pseudo_sector
    AND f.sector_key <> 0 AND f.region_key <> 0
  GROUP BY s.sic_section, r.region
  HAVING count(*) >= 30
), p AS (
  SELECT sic_section, region, n, x, x / n AS p FROM c
), w AS (
  SELECT sic_section, region, n::int AS n, x::int AS x,
         round(100 * p, 1) AS pct_negative,
         round(100 * (p + 1.96*1.96/(2*n) - 1.96 * sqrt(p*(1-p)/n + 1.96*1.96/(4*n*n))) / (1 + 1.96*1.96/n), 1) AS ci_low,
         round(100 * (p + 1.96*1.96/(2*n) + 1.96 * sqrt(p*(1-p)/n + 1.96*1.96/(4*n*n))) / (1 + 1.96*1.96/n), 1) AS ci_high
  FROM p
)
SELECT RANK() OVER (ORDER BY ci_low DESC) AS rank_by_low, * FROM w;

SELECT rank_by_low, sic_section, region, n, pct_negative, ci_low, ci_high
FROM res_wilson_sector_region
ORDER BY rank_by_low
LIMIT 10;

-- Cells clearly above / below the 20.3% baseline (expect 21 and 22; about 3 to 4 each would be chance)
SELECT count(*) AS cells_clearly_above FROM res_wilson_sector_region WHERE ci_low > 20.3;
SELECT count(*) AS cells_clearly_below FROM res_wilson_sector_region WHERE ci_high < 20.3;
