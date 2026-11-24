-- 15e_reconciliation.sql
-- Reconciliation: row counts and asset sums must agree between staging, the clean view and the fact table,
-- and every results table must add up to the population it was built from. One row per check.
-- Expect: 100,000 / 100,000 / 32,137 / 32,137 / 656,922,621,948 / 656,922,621,948 / 32,137 / 32,137 / 32,137 /
--         31,549 / 31,549 / 32,137 / 6,410 / 6,410.
-- res_cohort and res_validity are 31,549 = 32,137 minus 588 pseudo-sector rows, which they exclude by design.
SELECT 'stg rows' AS chk, count(*)::numeric AS val FROM stg_company_financials
UNION ALL SELECT 'fact rows', count(*) FROM fact_company_year
UNION ALL SELECT 'view central rows', count(*) FROM v_company_clean WHERE in_central_population
UNION ALL SELECT 'fact central rows', count(*) FROM fact_company_year WHERE in_central_population
UNION ALL SELECT 'view central assets', sum(total_assets) FROM v_company_clean WHERE in_central_population
UNION ALL SELECT 'fact central assets', sum(total_assets) FROM fact_company_year WHERE in_central_population
UNION ALL SELECT 'res_region n total', sum(n) FROM res_region
UNION ALL SELECT 'res_size n total', sum(n) FROM res_size
UNION ALL SELECT 'res_sector n total + pseudo', (SELECT sum(n) FROM res_sector) + (SELECT count(*) FROM fact_company_year WHERE in_central_population AND (is_pseudo_sector OR sector_key = 0))
UNION ALL SELECT 'res_cohort n total', sum(n) FROM res_cohort
UNION ALL SELECT 'res_validity n total', sum(n) FROM res_validity
UNION ALL SELECT 'res_sensitivity B n', n FROM res_sensitivity WHERE population LIKE 'B%' AND thin_cut_pct = 10
UNION ALL SELECT 'res_concentration n', count(*) FROM res_concentration
UNION ALL SELECT 'negative in fact central', count(*) FROM fact_company_year WHERE in_central_population AND state_10 = 'Negative' AND NOT is_extreme_equity AND NOT is_pseudo_sector;
