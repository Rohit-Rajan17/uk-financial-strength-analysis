-- 12c_sensitivity.sql
-- 3 x 3 sensitivity grid: thin cut-off 5%, 10%, 15% x population
--   A = everyone with equity and assets; B = excluding Dormant accounts (central case);
--   C = B and also dropping companies with 0 or no employees.
-- For each setting: negative, thin and healthy shares, plus the London and accommodation-and-food findings.
DROP TABLE IF EXISTS res_sensitivity;
CREATE TABLE res_sensitivity AS
WITH base AS (
  SELECT f.*, r.region, s.sic_section
  FROM fact_company_year f
  JOIN dim_region r ON r.region_key = f.region_key
  JOIN dim_sector s ON s.sector_key = f.sector_key
  WHERE f.is_gbp AND f.fiscal_year = 2024
    AND f.equity IS NOT NULL AND f.total_assets > 0
), pop AS (
  SELECT 'A all with equity' AS population, * FROM base
  UNION ALL
  SELECT 'B excl Dormant (central)', * FROM base WHERE NOT is_dormant_accounts
  UNION ALL
  SELECT 'C excl Dormant and no staff', * FROM base WHERE NOT is_dormant_accounts AND employees > 0
), t AS (
  SELECT unnest(ARRAY[0.05, 0.10, 0.15]) AS thin_cut
)
SELECT population, (thin_cut*100)::int AS thin_cut_pct,
       count(*) AS n,
       round(100.0 * count(*) FILTER (WHERE equity < 0) / count(*), 1) AS pct_negative,
       round(100.0 * count(*) FILTER (WHERE equity >= 0 AND equity/total_assets < thin_cut) / count(*), 1) AS pct_thin,
       round(100.0 * count(*) FILTER (WHERE equity/total_assets >= thin_cut) / count(*), 1) AS pct_healthy,
       round(100.0 * count(*) FILTER (WHERE region = 'London' AND equity < 0) / nullif(count(*) FILTER (WHERE region = 'London'),0), 1) AS london_neg,
       round(100.0 * count(*) FILTER (WHERE region NOT IN ('London','Unknown (left register)') AND equity < 0) / nullif(count(*) FILTER (WHERE region NOT IN ('London','Unknown (left register)')),0), 1) AS other_regions_neg,
       round(100.0 * count(*) FILTER (WHERE sic_section = 'Accommodation and food services' AND equity < 0) / nullif(count(*) FILTER (WHERE sic_section = 'Accommodation and food services'),0), 1) AS accom_neg
FROM pop CROSS JOIN t
GROUP BY population, thin_cut;

SELECT * FROM res_sensitivity ORDER BY population, thin_cut_pct;
