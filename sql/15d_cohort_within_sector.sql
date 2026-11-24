-- 15d_cohort_within_sector.sql
-- Is "younger means thinner" just sector mix? Split each sector into three age bands (before 2013, 2013-2018,
-- since 2019) and compare inside each sector. Bands under 30 companies dropped; no incorporation year excluded.
-- Result: 15 sectors have all three bands, and the newest band is higher than the oldest in all 15.
-- This shows the pattern is not a sector artefact; it does not show that youth causes weakness (survivorship).
DROP TABLE IF EXISTS res_cohort_by_sector;
CREATE TABLE res_cohort_by_sector AS
SELECT s.sic_section,
       CASE WHEN c.incorporation_year >= 2019 THEN '3 Since 2019'
            WHEN c.incorporation_year >= 2013 THEN '2 2013-2018'
            ELSE '1 Before 2013' END AS cohort,
       count(*) AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative
FROM fact_company_year f
JOIN dim_company c ON c.company_id = f.company_id
JOIN dim_sector s ON s.sector_key = f.sector_key
WHERE f.in_central_population AND NOT f.is_pseudo_sector
  AND f.sector_key <> 0 AND c.incorporation_year IS NOT NULL
GROUP BY s.sic_section, 2
HAVING count(*) >= 30;

SELECT sic_section,
       max(CASE WHEN cohort LIKE '1%' THEN n END) AS n_old,
       max(CASE WHEN cohort LIKE '1%' THEN pct_negative END) AS old,
       max(CASE WHEN cohort LIKE '2%' THEN pct_negative END) AS mid,
       max(CASE WHEN cohort LIKE '3%' THEN n END) AS n_new,
       max(CASE WHEN cohort LIKE '3%' THEN pct_negative END) AS new
FROM res_cohort_by_sector
GROUP BY sic_section
ORDER BY sum(n) DESC;

SELECT count(*) FILTER (WHERE new > old) AS new_worse,
       count(*) FILTER (WHERE new <= old) AS new_not_worse
FROM (SELECT sic_section,
             max(CASE WHEN cohort LIKE '1%' THEN pct_negative END) AS old,
             max(CASE WHEN cohort LIKE '3%' THEN pct_negative END) AS new
      FROM res_cohort_by_sector GROUP BY 1 HAVING count(*) = 3) x;
