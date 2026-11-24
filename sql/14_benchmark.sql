-- 14_benchmark.sql
-- Benchmark: can the 3% sample reproduce the publisher's full-data FY2024 negative-equity shares?
-- Publisher (full data): overall 17.8%, London 20.0%, Northern Ireland 11.1%, accommodation and food 27.0%,
-- real estate 24.1%, financial and insurance 14.0%.
-- Five population definitions, broadest to central. D1/D2 (equity present) is the like-for-like comparison.
-- Run as a whole script (Option+X in DBeaver).
WITH b AS (
  SELECT f.*, r.region, s.sic_section, c.company_status
  FROM fact_company_year f
  JOIN dim_region r USING (region_key) JOIN dim_sector s USING (sector_key)
  JOIN dim_company c USING (company_id)
  WHERE f.fiscal_year = 2024 AND f.equity IS NOT NULL
), d AS (
  SELECT 'D1 equity present, any currency, incl dormant' AS def, * FROM b
  UNION ALL SELECT 'D2 D1 + GBP', * FROM b WHERE is_gbp
  UNION ALL SELECT 'D3 D2 + assets>0 (population A)', * FROM b WHERE is_gbp AND total_assets > 0
  UNION ALL SELECT 'D4 central (B)', * FROM b WHERE in_central_population
  UNION ALL SELECT 'D5 D4 + status Active only', * FROM b WHERE in_central_population AND company_status = 'Active'
)
SELECT def, count(*) AS n,
  round(100.0*count(*) FILTER (WHERE equity<0)/count(*),1) AS overall,
  round(100.0*count(*) FILTER (WHERE equity<0 AND region='London')/nullif(count(*) FILTER (WHERE region='London'),0),1) AS london,
  round(100.0*count(*) FILTER (WHERE equity<0 AND region='Northern Ireland')/nullif(count(*) FILTER (WHERE region='Northern Ireland'),0),1) AS ni,
  round(100.0*count(*) FILTER (WHERE equity<0 AND sic_section='Accommodation and food services')/nullif(count(*) FILTER (WHERE sic_section='Accommodation and food services'),0),1) AS accom,
  round(100.0*count(*) FILTER (WHERE equity<0 AND sic_section='Real estate activities')/nullif(count(*) FILTER (WHERE sic_section='Real estate activities'),0),1) AS real_estate,
  round(100.0*count(*) FILTER (WHERE equity<0 AND sic_section='Financial and insurance activities')/nullif(count(*) FILTER (WHERE sic_section='Financial and insurance activities'),0),1) AS finance
FROM d GROUP BY def ORDER BY def;
