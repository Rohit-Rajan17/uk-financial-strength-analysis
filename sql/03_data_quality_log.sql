-- 03_data_quality_log.sql
-- Counts each data-quality issue listed in the scope and stores the counts in dq_log (19 checks),
-- then counts the year-to-year pairs used later for transitions, and the population funnel.
-- Run after 02. Expect 156 non-GBP rows, 33,105 pairs for 2024 to 2025, and a funnel ending at 32,137.

DROP TABLE IF EXISTS dq_log;
CREATE TABLE dq_log (
    check_id   serial PRIMARY KEY,
    check_name text NOT NULL,
    n_rows     bigint NOT NULL,
    note       text
);

INSERT INTO dq_log (check_name, n_rows, note)
SELECT 'fiscal_year differs from year of period_end', count(*), 'year-end dates near 1 Jan or odd period lengths' FROM stg_company_financials WHERE extract(year FROM period_end) <> fiscal_year
UNION ALL SELECT 'total_assets = 0', count(*), NULL FROM stg_company_financials WHERE total_assets = 0
UNION ALL SELECT 'total_assets = 0 but equity <> 0', count(*), 'contradiction' FROM stg_company_financials WHERE total_assets = 0 AND equity <> 0
UNION ALL SELECT 'equity > total_assets', count(*), 'publisher says these are blanked; mostly rounding' FROM stg_company_financials WHERE equity > total_assets
UNION ALL SELECT 'equity > total_assets by more than 1', count(*), NULL FROM stg_company_financials WHERE equity - total_assets > 1
UNION ALL SELECT 'equity > total_assets by more than 100', count(*), NULL FROM stg_company_financials WHERE equity - total_assets > 100
UNION ALL SELECT 'abs(equity) above 1bn', count(*), 'outliers: use medians, decide treatment' FROM stg_company_financials WHERE abs(equity) > 1e9
UNION ALL SELECT 'incorporation_year after fiscal_year', count(*), NULL FROM stg_company_financials WHERE incorporation_year > fiscal_year
UNION ALL SELECT 'currency not GBP', count(*), 'excluded from GBP sums' FROM stg_company_financials WHERE currency <> 'GBP'
UNION ALL SELECT 'accounts_type = Dormant', count(*), NULL FROM stg_company_financials WHERE accounts_type = 'Dormant'
UNION ALL SELECT 'employees = 0', count(*), 'reported zero, not missing' FROM stg_company_financials WHERE employees = 0
UNION ALL SELECT 'company_status blank (left the register)', count(*), 'type, SIC, region, accounts_type also blank' FROM stg_company_financials WHERE company_status IS NULL
UNION ALL SELECT 'region blank', count(*), NULL FROM stg_company_financials WHERE region IS NULL
UNION ALL SELECT 'sic_section blank', count(*), NULL FROM stg_company_financials WHERE sic_section IS NULL
UNION ALL SELECT 'legal_name not upper case', count(*), NULL FROM stg_company_financials WHERE legal_name <> upper(legal_name)
UNION ALL SELECT 'legal_name ends in LTD', count(*), 'LTD vs LIMITED variants' FROM stg_company_financials WHERE upper(legal_name) ~ '\mLTD\.?$'
UNION ALL SELECT 'legal_name ends in LIMITED', count(*), NULL FROM stg_company_financials WHERE upper(legal_name) ~ '\mLIMITED$'
UNION ALL SELECT 'legal_name has no recognised suffix', count(*), NULL FROM stg_company_financials WHERE upper(legal_name) !~ '(LIMITED|LTD\.?|LLP|PLC|P\.L\.C\.?|CIC|C\.I\.C\.?)\)?$'
UNION ALL SELECT 'SIC section is a pseudo-sector (dormant, non-trading, residents)', count(*), 'show separately, exclude from rankings' FROM stg_company_financials WHERE sic_section IN ('Dormant company','Non-trading company','Residents property management');

SELECT check_id, check_name, n_rows, note FROM dq_log ORDER BY check_id;

-- Consecutive fiscal-year pairs (same company, next fiscal year), using LAG.
DROP TABLE IF EXISTS tmp_pairs;
CREATE TEMP TABLE tmp_pairs AS
SELECT company_id, fiscal_year,
       LAG(fiscal_year) OVER w AS prev_year,
       period_end,
       LAG(period_end)  OVER w AS prev_period_end,
       equity,
       LAG(equity)      OVER w AS prev_equity
FROM stg_company_financials
WINDOW w AS (PARTITION BY company_id ORDER BY fiscal_year);

-- Pairs by year pair (all years pairs, then consecutive only)
SELECT prev_year, fiscal_year, count(*) AS pairs,
       count(*) FILTER (WHERE period_end - prev_period_end BETWEEN 300 AND 430) AS gap_about_one_year
FROM tmp_pairs
WHERE prev_year IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;

SELECT count(*) AS consecutive_pairs,
       count(*) FILTER (WHERE equity IS NOT NULL AND prev_equity IS NOT NULL) AS with_equity_both,
       count(*) FILTER (WHERE prev_equity >= 0 AND equity < 0) AS fell_into_negative,
       count(*) FILTER (WHERE prev_equity < 0 AND equity >= 0) AS recovered
FROM tmp_pairs
WHERE fiscal_year - prev_year = 1;

-- Same, split by the two year pairs that matter
SELECT prev_year || '->' || fiscal_year AS year_pair,
       count(*) AS pairs_with_equity_both,
       count(*) FILTER (WHERE prev_equity >= 0 AND equity < 0) AS fell_into_negative,
       count(*) FILTER (WHERE prev_equity < 0 AND equity >= 0) AS recovered
FROM tmp_pairs
WHERE fiscal_year - prev_year = 1 AND equity IS NOT NULL AND prev_equity IS NOT NULL
  AND prev_year IN (2023, 2024)
GROUP BY 1 ORDER BY 1;

-- Data funnel for the central population (FY2024). Each step must be a subset of the last.
SELECT step, n FROM (
  SELECT 1 AS o, 'all rows' AS step, count(*) AS n FROM stg_company_financials
  UNION ALL SELECT 2, 'GBP only', count(*) FROM stg_company_financials WHERE currency = 'GBP'
  UNION ALL SELECT 3, 'fiscal year 2024', count(*) FROM stg_company_financials WHERE currency = 'GBP' AND fiscal_year = 2024
  UNION ALL SELECT 4, 'equity present', count(*) FROM stg_company_financials WHERE currency = 'GBP' AND fiscal_year = 2024 AND equity IS NOT NULL
  UNION ALL SELECT 5, 'total_assets > 0', count(*) FROM stg_company_financials WHERE currency = 'GBP' AND fiscal_year = 2024 AND equity IS NOT NULL AND total_assets > 0
  UNION ALL SELECT 6, 'accounts type not Dormant (blank type kept)', count(*) FROM stg_company_financials WHERE currency = 'GBP' AND fiscal_year = 2024 AND equity IS NOT NULL AND total_assets > 0 AND accounts_type IS DISTINCT FROM 'Dormant'
) f ORDER BY o;
