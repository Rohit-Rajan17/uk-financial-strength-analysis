-- 07e_sector_region.sql
-- Sector x region, FY2024 central population, leaving out pseudo-sectors and unknown sector or region.
-- Groups under 30 companies are kept but marked not reliable, so they're counted but never ranked.
-- Expect 233 groups, 147 reliable, 25,537 companies in total and 24,638 in reliable groups.
DROP TABLE IF EXISTS res_sector_region;
CREATE TABLE res_sector_region AS
SELECT s.sic_section, r.region,
       count(*) AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.equity_ratio)::numeric, 3) AS median_equity_ratio,
       (count(*) >= 30) AS is_reliable
FROM fact_company_year f
JOIN dim_sector s ON s.sector_key = f.sector_key
JOIN dim_region r ON r.region_key = f.region_key
WHERE f.in_central_population
  AND NOT f.is_pseudo_sector
  AND f.sector_key <> 0
  AND f.region_key <> 0
GROUP BY s.sic_section, r.region;

SELECT count(*) AS cells,
       count(*) FILTER (WHERE is_reliable) AS reliable_cells,
       sum(n) AS total_n,
       sum(n) FILTER (WHERE is_reliable) AS reliable_n
FROM res_sector_region;

SELECT * FROM res_sector_region
WHERE is_reliable
ORDER BY pct_negative DESC
LIMIT 10;
