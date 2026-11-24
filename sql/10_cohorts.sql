-- 10_cohorts.sql
-- Cohorts by incorporation year, FY2024 central population, pseudo-sectors excluded.
-- Companies with no incorporation year (they left the register) go into 'Unknown'. Expect 7 rows totalling 31,549.
-- Caution: survivorship (old companies in the table are the ones that survived) and start-up losses.
DROP TABLE IF EXISTS res_cohort;
CREATE TABLE res_cohort AS
SELECT CASE WHEN c.incorporation_year IS NULL THEN 'Unknown'
            WHEN c.incorporation_year >= 2022 THEN '2022-2024'
            WHEN c.incorporation_year >= 2019 THEN '2019-2021'
            WHEN c.incorporation_year >= 2013 THEN '2013-2018'
            WHEN c.incorporation_year >= 2003 THEN '2003-2012'
            WHEN c.incorporation_year >= 1993 THEN '1993-2002'
            ELSE 'Before 1993' END AS incorporated,
       count(*) AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Thin')     / count(*), 1) AS pct_thin,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Healthy')  / count(*), 1) AS pct_healthy,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.equity_ratio)::numeric, 3) AS median_equity_ratio
FROM fact_company_year f
JOIN dim_company c ON c.company_id = f.company_id
WHERE f.in_central_population AND NOT f.is_pseudo_sector
GROUP BY 1;

SELECT * FROM res_cohort
ORDER BY CASE incorporated
           WHEN 'Before 1993' THEN 1 WHEN '1993-2002' THEN 2 WHEN '2003-2012' THEN 3
           WHEN '2013-2018' THEN 4 WHEN '2019-2021' THEN 5 WHEN '2022-2024' THEN 6
           ELSE 7 END;
