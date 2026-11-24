-- 02_typed_staging.sql
-- Copies the raw text into a typed table with a primary key and CHECK rules.
-- Rows that break a rule aren't dropped silently: they go to stg_rejects and get counted.
-- company_id stays text because some values (up to 1.0e19) are too big for bigint.
-- company_number is 8-character text so leading zeros survive.
-- Expect 100,000 staged and 0 rejected.

DROP TABLE IF EXISTS stg_rejects;
DROP TABLE IF EXISTS stg_company_financials;

CREATE TABLE stg_company_financials (
    company_id          text         NOT NULL,
    company_number      char(8)      NOT NULL,
    legal_name          text         NOT NULL,
    fiscal_year         smallint     NOT NULL,
    period_end          date         NOT NULL,
    company_type        text,
    company_status      text,
    incorporation_year  smallint,
    accounts_type       text,
    sic_code            text,
    sic_section         text,
    sic_division        text,
    region              text,
    currency            char(3)      NOT NULL,
    turnover            numeric,
    profit              numeric,
    total_assets        numeric,
    equity              numeric,
    employees           integer,
    company_domain      text,
    fliar_profile_url   text,
    CONSTRAINT pk_stg PRIMARY KEY (company_id, fiscal_year),
    CONSTRAINT ck_year CHECK (fiscal_year BETWEEN 2019 AND 2025),
    CONSTRAINT ck_assets_nonneg CHECK (total_assets IS NULL OR total_assets >= 0),
    CONSTRAINT ck_turnover_nonneg CHECK (turnover IS NULL OR turnover >= 0),
    CONSTRAINT ck_employees_nonneg CHECK (employees IS NULL OR employees >= 0),
    CONSTRAINT ck_currency CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT ck_company_number CHECK (company_number ~ '^[A-Z0-9]{8}$')
);

CREATE TABLE stg_rejects (
    reason text,
    company_id text,
    fiscal_year text,
    raw_row jsonb
);

-- Rows that would break a rule go to stg_rejects first, then everything else is loaded.
INSERT INTO stg_rejects
SELECT
    CASE
        WHEN r.fiscal_year !~ '^[0-9]{4}$'                                   THEN 'bad fiscal_year'
        WHEN r.period_end !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'                  THEN 'bad period_end'
        WHEN r.total_assets IS NOT NULL AND r.total_assets::numeric < 0      THEN 'negative total_assets'
        WHEN r.turnover IS NOT NULL AND r.turnover::numeric < 0              THEN 'negative turnover'
        WHEN r.employees IS NOT NULL AND r.employees::numeric < 0            THEN 'negative employees'
        WHEN r.company_number !~ '^[A-Z0-9]{8}$'                             THEN 'bad company_number'
        WHEN r.currency !~ '^[A-Z]{3}$'                                      THEN 'bad currency'
    END,
    r.company_id, r.fiscal_year, to_jsonb(r)
FROM raw_company_financials r
WHERE r.fiscal_year !~ '^[0-9]{4}$' OR r.period_end !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
   OR (r.total_assets IS NOT NULL AND r.total_assets::numeric < 0)
   OR (r.turnover IS NOT NULL AND r.turnover::numeric < 0)
   OR (r.employees IS NOT NULL AND r.employees::numeric < 0)
   OR r.company_number !~ '^[A-Z0-9]{8}$' OR r.currency !~ '^[A-Z]{3}$';

INSERT INTO stg_company_financials
SELECT
    r.company_id, r.company_number, r.legal_name, r.fiscal_year::smallint, r.period_end::date,
    r.company_type, r.company_status, r.incorporation_year::numeric::smallint, r.accounts_type,
    r.sic_code, r.sic_section, r.sic_division, r.region, r.currency,
    r.turnover::numeric, r.profit::numeric, r.total_assets::numeric, r.equity::numeric,
    r.employees::numeric::integer, r.company_domain, r.fliar_profile_url
FROM raw_company_financials r
WHERE NOT EXISTS (
    SELECT 1 FROM stg_rejects x
    WHERE x.company_id = r.company_id AND x.fiscal_year = r.fiscal_year
);

CREATE INDEX ix_stg_year   ON stg_company_financials (fiscal_year);
CREATE INDEX ix_stg_sector ON stg_company_financials (sic_section);
CREATE INDEX ix_stg_region ON stg_company_financials (region);

-- Reconciliation: staged + rejected must equal raw (100,000).
SELECT (SELECT count(*) FROM raw_company_financials) AS raw_rows,
       (SELECT count(*) FROM stg_company_financials) AS staged_rows,
       (SELECT count(*) FROM stg_rejects)            AS rejected_rows,
       (SELECT count(*) FROM raw_company_financials)
         - (SELECT count(*) FROM stg_company_financials)
         - (SELECT count(*) FROM stg_rejects)        AS difference;
