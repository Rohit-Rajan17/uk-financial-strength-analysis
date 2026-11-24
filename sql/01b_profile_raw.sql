-- 01b_profile_raw.sql
-- Run after importing the CSV into raw_company_financials (expect 100,000 rows).

-- 0. Some import tools load empty cells as empty text instead of blanks.
-- This turns them into real blanks so the fill rates below are right. Safe to run twice.
UPDATE raw_company_financials SET
    company_type = NULLIF(company_type,''), company_status = NULLIF(company_status,''),
    incorporation_year = NULLIF(incorporation_year,''), accounts_type = NULLIF(accounts_type,''),
    sic_code = NULLIF(sic_code,''), sic_section = NULLIF(sic_section,''), sic_division = NULLIF(sic_division,''),
    region = NULLIF(region,''), turnover = NULLIF(turnover,''), profit = NULLIF(profit,''),
    total_assets = NULLIF(total_assets,''), equity = NULLIF(equity,''), employees = NULLIF(employees,''),
    company_domain = NULLIF(company_domain,''), fliar_profile_url = NULLIF(fliar_profile_url,'');

-- 1. Row count (expect 100,000)
SELECT count(*) AS raw_rows FROM raw_company_financials;

-- 2. Fill rate per column (non-empty share). Expect equity ~98.6%, assets ~72.9%, turnover ~2.5%.
SELECT col, filled, round(100.0 * filled / total, 1) AS pct_filled
FROM (
    SELECT 'company_type' AS col, count(company_type) AS filled, count(*) AS total FROM raw_company_financials
    UNION ALL SELECT 'company_status', count(company_status), count(*) FROM raw_company_financials
    UNION ALL SELECT 'incorporation_year', count(incorporation_year), count(*) FROM raw_company_financials
    UNION ALL SELECT 'accounts_type', count(accounts_type), count(*) FROM raw_company_financials
    UNION ALL SELECT 'sic_section', count(sic_section), count(*) FROM raw_company_financials
    UNION ALL SELECT 'region', count(region), count(*) FROM raw_company_financials
    UNION ALL SELECT 'turnover', count(turnover), count(*) FROM raw_company_financials
    UNION ALL SELECT 'profit', count(profit), count(*) FROM raw_company_financials
    UNION ALL SELECT 'total_assets', count(total_assets), count(*) FROM raw_company_financials
    UNION ALL SELECT 'equity', count(equity), count(*) FROM raw_company_financials
    UNION ALL SELECT 'employees', count(employees), count(*) FROM raw_company_financials
) t
ORDER BY pct_filled DESC;

-- 3. Rows per fiscal year
SELECT fiscal_year, count(*) AS rows FROM raw_company_financials GROUP BY fiscal_year ORDER BY fiscal_year;

-- 4. Text columns that must stay text: company_number is always 8 characters (leading zeros kept)
SELECT length(company_number) AS len, count(*) FROM raw_company_financials GROUP BY 1 ORDER BY 1;
