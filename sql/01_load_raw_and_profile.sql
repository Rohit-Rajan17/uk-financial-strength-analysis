-- 01_load_raw_and_profile.sql
-- Loads the CSV exactly as supplied (every column as text), then profiles it.
-- Run in psql from the repo folder, with the CSV in data/ (it isn't in the repo):
--   psql -d ukfin -f sql/01_load_raw_and_profile.sql
-- In DBeaver or pgAdmin, use 01a and 01b instead.
-- Data: Fliar Research (2026), CC BY-NC 4.0.

DROP TABLE IF EXISTS raw_company_financials;
CREATE TABLE raw_company_financials (
    company_id          text,
    company_number      text,
    legal_name          text,
    fiscal_year         text,
    period_end          text,
    company_type        text,
    company_status      text,
    incorporation_year  text,
    accounts_type       text,
    sic_code            text,
    sic_section         text,
    sic_division        text,
    region              text,
    currency            text,
    turnover            text,
    profit              text,
    total_assets        text,
    equity              text,
    employees           text,
    company_domain      text,
    fliar_profile_url   text
);

\copy raw_company_financials FROM 'data/uk_company_financials_2019_2025_sample.csv' WITH (FORMAT csv, HEADER true)

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
