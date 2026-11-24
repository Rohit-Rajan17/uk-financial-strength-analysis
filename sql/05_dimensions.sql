-- 05_dimensions.sql
-- Dimension tables for the star schema: sector, division, region, size class and date.
-- Key 0 is an "Unknown" row, so companies that left the register (no sector or region)
-- still join instead of disappearing.
-- Expect 25 sectors, 90 divisions, 13 regions, 7 size classes and 3,652 days.

DROP TABLE IF EXISTS dim_division;
DROP TABLE IF EXISTS dim_sector;
DROP TABLE IF EXISTS dim_region;
DROP TABLE IF EXISTS dim_size;
DROP TABLE IF EXISTS dim_date;

-- 1. Sector (SIC section, 24 values)
CREATE TABLE dim_sector (
    sector_key       smallint PRIMARY KEY,
    sic_section      text NOT NULL UNIQUE,
    is_pseudo_sector boolean NOT NULL,
    is_financial     boolean NOT NULL
);
INSERT INTO dim_sector
SELECT 0, 'Unknown (left register)', false, false;
INSERT INTO dim_sector
SELECT row_number() OVER (ORDER BY sic_section), sic_section,
       sic_section IN ('Dormant company', 'Non-trading company', 'Residents property management'),
       sic_section = 'Financial and insurance activities'
FROM (SELECT DISTINCT sic_section FROM stg_company_financials WHERE sic_section IS NOT NULL) s;

-- 2. Division (SIC division, 89 values), each belongs to exactly one sector
CREATE TABLE dim_division (
    division_key smallint PRIMARY KEY,
    sic_division text NOT NULL UNIQUE,
    sector_key   smallint NOT NULL REFERENCES dim_sector (sector_key)
);
INSERT INTO dim_division
SELECT 0, 'Unknown (left register)', 0;
INSERT INTO dim_division
SELECT row_number() OVER (ORDER BY d.sic_division), d.sic_division, s.sector_key
FROM (SELECT DISTINCT sic_division, sic_section FROM stg_company_financials WHERE sic_division IS NOT NULL) d
JOIN dim_sector s ON s.sic_section = d.sic_section;

-- 3. Region (12 values)
CREATE TABLE dim_region (
    region_key smallint PRIMARY KEY,
    region     text NOT NULL UNIQUE
);
INSERT INTO dim_region SELECT 0, 'Unknown (left register)';
INSERT INTO dim_region
SELECT row_number() OVER (ORDER BY region), region
FROM (SELECT DISTINCT region FROM stg_company_financials WHERE region IS NOT NULL) r;

-- 4. Size class, in a fixed display order
CREATE TABLE dim_size (
    size_key   smallint PRIMARY KEY,
    size_class text NOT NULL UNIQUE
);
INSERT INTO dim_size VALUES
    (1, 'Micro'), (2, 'Small'), (3, 'Medium'), (4, 'Large or group'),
    (5, 'Dormant'), (6, 'Other'), (0, 'Unknown');

-- 5. Date (one row per day, 2017 to 2026) built with generate_series
CREATE TABLE dim_date (
    date_key     date PRIMARY KEY,
    year         smallint NOT NULL,
    quarter      smallint NOT NULL,
    month        smallint NOT NULL,
    month_name   text NOT NULL,
    year_month   text NOT NULL,
    is_month_end boolean NOT NULL
);
INSERT INTO dim_date
SELECT d::date,
       extract(year FROM d)::smallint,
       extract(quarter FROM d)::smallint,
       extract(month FROM d)::smallint,
       to_char(d, 'Mon'),
       to_char(d, 'YYYY-MM'),
       (d + interval '1 day')::date = date_trunc('month', d + interval '1 day')::date
FROM generate_series('2017-01-01'::date, '2026-12-31'::date, interval '1 day') AS g(d);

-- Checks: every sector, division, region and year-end date in the data must have a dimension row.
SELECT
  (SELECT count(*) FROM dim_sector)   AS sectors_incl_unknown,
  (SELECT count(*) FROM dim_division) AS divisions_incl_unknown,
  (SELECT count(*) FROM dim_region)   AS regions_incl_unknown,
  (SELECT count(*) FROM dim_size)     AS size_classes,
  (SELECT count(*) FROM dim_date)     AS days,
  (SELECT count(*) FROM stg_company_financials s
     WHERE NOT EXISTS (SELECT 1 FROM dim_date d WHERE d.date_key = s.period_end)) AS period_ends_not_in_dim_date;
