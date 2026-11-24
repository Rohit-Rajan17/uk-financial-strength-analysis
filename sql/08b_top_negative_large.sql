-- 08b_top_negative_large.sql
-- Largest negative-equity companies among Medium, Full and Group filers only (no micro or small company is named).
-- Pseudo-sectors and extreme-equity rows (|equity| over 1bn) are excluded. Expect 46 rows.
-- The output names real companies, so it stays in the local workbook only. Negative equity is not distress:
-- several are subsidiaries funded by a parent.
DROP TABLE IF EXISTS res_top_negative_large;
CREATE TABLE res_top_negative_large AS
SELECT row_number() OVER (ORDER BY f.equity ASC) AS rank_no,
       c.legal_name_clean, s.accounts_type, d.sic_section, r.region,
       f.total_assets, f.equity, round(f.equity_ratio, 3) AS equity_ratio
FROM fact_company_year f
JOIN dim_company c ON c.company_id = f.company_id
JOIN stg_company_financials s ON s.company_id = f.company_id AND s.fiscal_year = f.fiscal_year
JOIN dim_sector d ON d.sector_key = f.sector_key
JOIN dim_region r ON r.region_key = f.region_key
WHERE f.in_central_population
  AND NOT f.is_pseudo_sector
  AND NOT f.is_extreme_equity
  AND f.state_10 = 'Negative'
  AND s.accounts_type IN ('Medium','Full (large)','Group (consolidated)');

SELECT count(*) FROM res_top_negative_large;
