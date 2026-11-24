-- 04_clean_view.sql
-- One cleaned view over the staging table. No rows are removed: each row gets flags instead,
-- so every later step can say exactly which rows it leaves out and why.
-- Expect 100,000 rows, 32,137 of them in the central population.
CREATE OR REPLACE VIEW v_company_clean AS
SELECT
    s.company_id,
    s.company_number,
    s.legal_name,
    -- 1. Tidy legal name: upper case, single spaces, and LTD / LTD. written as LIMITED
    regexp_replace(
        regexp_replace(upper(btrim(s.legal_name)), '\s+', ' ', 'g'),
        '\mLTD\.?$', 'LIMITED') AS legal_name_clean,
    s.fiscal_year,
    s.period_end,
    s.company_status,
    s.company_type,
    s.incorporation_year,
    s.fiscal_year - s.incorporation_year AS company_age,
    s.accounts_type,
    -- 2. Group the accounts types into size classes (latest accounts, not necessarily this year)
    CASE
        WHEN s.accounts_type = 'Micro-entity'                 THEN 'Micro'
        WHEN s.accounts_type LIKE 'Small%'                    THEN 'Small'
        WHEN s.accounts_type = 'Medium'                       THEN 'Medium'
        WHEN s.accounts_type IN ('Full (large)', 'Group (consolidated)') THEN 'Large or group'
        WHEN s.accounts_type = 'Dormant'                      THEN 'Dormant'
        WHEN s.accounts_type IS NULL                          THEN 'Unknown'
        ELSE 'Other'
    END AS size_class,
    s.sic_code,
    s.sic_section,
    s.sic_division,
    s.region,
    s.currency,
    s.turnover,
    s.profit,
    s.total_assets,
    s.equity,
    s.employees,
    -- 3. Flags, always true or false. A blank flag would silently drop rows from a "NOT flag" filter.
    COALESCE(s.currency = 'GBP', false)                                           AS is_gbp,
    COALESCE(s.accounts_type = 'Dormant', false)                                  AS is_dormant_accounts,
    (s.company_status IS NULL)                                                    AS left_register,
    COALESCE(s.sic_section IN ('Dormant company', 'Non-trading company', 'Residents property management'), false) AS is_pseudo_sector,
    COALESCE(abs(s.equity) > 1e9, false)                                          AS is_extreme_equity,
    -- 4. Equity ratio = equity / total assets, only where total assets > 0
    CASE WHEN s.total_assets > 0 AND s.equity IS NOT NULL
         THEN s.equity / s.total_assets END                                       AS equity_ratio,
    -- 5. Financial state at the central 10% threshold:
    --    Negative (equity < 0, needs no assets figure), Thin (0 to <10%), Healthy (10% or more), else Unknown
    CASE
        WHEN s.equity < 0                                              THEN 'Negative'
        WHEN s.total_assets > 0 AND s.equity / s.total_assets < 0.10   THEN 'Thin'
        WHEN s.total_assets > 0 AND s.equity / s.total_assets >= 0.10  THEN 'Healthy'
        ELSE 'Unknown'
    END AS state_10,
    -- 6. Central population (see docs/scope.md): GBP, FY2024, equity present, assets > 0, not Dormant accounts
    COALESCE(s.currency = 'GBP' AND s.fiscal_year = 2024 AND s.equity IS NOT NULL
     AND s.total_assets > 0 AND s.accounts_type IS DISTINCT FROM 'Dormant', false) AS in_central_population
FROM stg_company_financials s;
