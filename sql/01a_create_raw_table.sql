-- 01a_create_raw_table.sql
-- Point-and-click version of 01: creates the empty raw table. Then import the CSV with your
-- database tool's import wizard and run 01b.
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
