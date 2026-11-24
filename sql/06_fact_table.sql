-- 06_fact_table.sql
-- dim_company (one row per company) and fact_company_year (one row per company per year),
-- with primary keys, foreign keys, a CHECK on state, and indexes. Built from the view in 04.
-- Name, incorporation year, status, type, sector, region and accounts type never change
-- between a company's years, so they sit on the company rather than on each year.

DROP TABLE IF EXISTS fact_company_year;
DROP TABLE IF EXISTS dim_company;

CREATE TABLE dim_company (
    company_id         text PRIMARY KEY,
    company_number     char(8) NOT NULL,
    legal_name_clean   text NOT NULL,
    incorporation_year smallint,
    company_status     text,
    company_type       text
);
INSERT INTO dim_company
SELECT DISTINCT company_id, company_number, legal_name_clean, incorporation_year, company_status, company_type
FROM v_company_clean;

CREATE TABLE fact_company_year (
    company_id           text     NOT NULL REFERENCES dim_company (company_id),
    fiscal_year          smallint NOT NULL,
    period_end           date     NOT NULL REFERENCES dim_date (date_key),
    sector_key           smallint NOT NULL REFERENCES dim_sector (sector_key),
    division_key         smallint NOT NULL REFERENCES dim_division (division_key),
    region_key           smallint NOT NULL REFERENCES dim_region (region_key),
    size_key             smallint NOT NULL REFERENCES dim_size (size_key),
    currency             char(3)  NOT NULL,
    turnover             numeric,
    profit               numeric,
    total_assets         numeric,
    equity               numeric,
    employees            integer,
    equity_ratio         numeric,
    state_10             text     NOT NULL,
    company_age          smallint,
    is_gbp               boolean  NOT NULL,
    is_dormant_accounts  boolean  NOT NULL,
    left_register        boolean  NOT NULL,
    is_pseudo_sector     boolean  NOT NULL,
    is_extreme_equity    boolean  NOT NULL,
    in_central_population boolean NOT NULL,
    CONSTRAINT pk_fact PRIMARY KEY (company_id, fiscal_year),
    CONSTRAINT ck_state CHECK (state_10 IN ('Negative', 'Thin', 'Healthy', 'Unknown'))
);

INSERT INTO fact_company_year
SELECT
    v.company_id, v.fiscal_year, v.period_end,
    COALESCE(s.sector_key, 0),
    COALESCE(dv.division_key, 0),
    COALESCE(r.region_key, 0),
    COALESCE(z.size_key, 0),
    v.currency, v.turnover, v.profit, v.total_assets, v.equity, v.employees,
    v.equity_ratio, v.state_10, v.company_age,
    v.is_gbp, v.is_dormant_accounts, v.left_register, v.is_pseudo_sector, v.is_extreme_equity,
    v.in_central_population
FROM v_company_clean v
LEFT JOIN dim_sector   s  ON s.sic_section  = v.sic_section
LEFT JOIN dim_division dv ON dv.sic_division = v.sic_division
LEFT JOIN dim_region   r  ON r.region       = v.region
LEFT JOIN dim_size     z  ON z.size_class   = v.size_class;

CREATE INDEX ix_fact_year        ON fact_company_year (fiscal_year);
CREATE INDEX ix_fact_central     ON fact_company_year (sector_key, region_key) WHERE in_central_population;
CREATE INDEX ix_fact_period_end  ON fact_company_year (period_end);

-- Checks
SELECT
  (SELECT count(*) FROM dim_company)                                  AS companies,          -- 51,516
  (SELECT count(*) FROM fact_company_year)                            AS fact_rows,          -- 100,000
  (SELECT count(*) FROM fact_company_year WHERE in_central_population) AS central_population, -- 32,137
  (SELECT count(*) FROM fact_company_year WHERE sector_key = 0)       AS unknown_sector,     -- 19,126
  (SELECT count(*) FROM fact_company_year WHERE region_key = 0)       AS unknown_region,     -- 18,505
  (SELECT sum(total_assets) FROM fact_company_year
     WHERE in_central_population)                                     AS central_assets_gbp, -- must equal view
  (SELECT sum(total_assets) FROM v_company_clean
     WHERE in_central_population)                                     AS central_assets_view;
