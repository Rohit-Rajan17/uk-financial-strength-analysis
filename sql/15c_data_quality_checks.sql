-- 15c_data_quality_checks.sql
-- Three open data-quality items. Run each query on its own.

-- Check 1: the "extreme equity" rows (|equity| over 1bn). Expect 7 rows (n 1, 5, 5, 6, 6, 6, 4 for 2019-2025),
-- none negative, 5 in the central population in FY2024. They are real large groups with positive equity, so they
-- cannot affect any negative-equity share; they do dominate asset totals, so medians are used, never means.
SELECT fiscal_year, count(*) AS n,
       count(*) FILTER (WHERE equity < 0) AS negative,
       count(*) FILTER (WHERE in_central_population) AS in_central
FROM fact_company_year
WHERE is_extreme_equity
GROUP BY fiscal_year ORDER BY fiscal_year;

-- Check 2: equity larger than assets (arithmetically needs negative liabilities).
-- Expect 73 rows, 46 over 1, 17 over 100, 1 over 10,000, largest gap 86,286. All positive equity: immaterial, logged.
SELECT count(*) AS n,
       count(*) FILTER (WHERE equity - total_assets > 1)     AS gap_over_1,
       count(*) FILTER (WHERE equity - total_assets > 100)   AS gap_over_100,
       count(*) FILTER (WHERE equity - total_assets > 10000) AS gap_over_10k,
       max(equity - total_assets) AS max_gap
FROM fact_company_year
WHERE in_central_population AND equity > total_assets;

-- Check 3: London's share of companies (publisher: about 26%). Expect 26.6% of 37,024.
-- The publisher's 71%-of-assets claim did not reproduce on the sample (45.2%, and fragile), so it is not quoted.
SELECT round(100.0*count(*) FILTER (WHERE r.region='London')/count(*),1) AS pct_companies_london,
       count(*) AS n
FROM fact_company_year f JOIN dim_region r USING (region_key)
WHERE f.fiscal_year = 2024 AND f.region_key <> 0;
