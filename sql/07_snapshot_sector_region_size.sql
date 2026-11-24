-- 07_snapshot_sector_region_size.sql
-- FY2024 snapshot of the central population (32,137 companies) by sector, region and size class.
-- Results are saved to res_ tables so Excel and Power BI can reuse them. Run each block on its own.

-- 07a. Why we use medians: assets are extremely skewed
SELECT count(*) AS n,
       round(avg(total_assets))                                                   AS mean_assets,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY total_assets)::numeric)  AS median_assets,
       round(percentile_cont(0.1) WITHIN GROUP (ORDER BY total_assets)::numeric)  AS p10_assets,
       round(percentile_cont(0.9) WITHIN GROUP (ORDER BY total_assets)::numeric)  AS p90_assets,
       round(avg(equity_ratio)::numeric, 3)                                       AS mean_equity_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY equity_ratio)::numeric, 3) AS median_equity_ratio
FROM fact_company_year
WHERE in_central_population;

-- 07b. Sector snapshot (pseudo-sectors and Unknown excluded from the ranking)
DROP TABLE IF EXISTS res_sector;
CREATE TABLE res_sector AS
SELECT s.sic_section,
       count(*)                                                                 AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Thin')     / count(*), 1) AS pct_thin,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Healthy')  / count(*), 1) AS pct_healthy,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.equity_ratio)::numeric, 3) AS median_equity_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.total_assets)::numeric)    AS median_assets,
       (count(*) >= 30)                                                          AS is_reliable
FROM fact_company_year f
JOIN dim_sector s ON s.sector_key = f.sector_key
WHERE f.in_central_population AND NOT s.is_pseudo_sector AND s.sector_key <> 0
GROUP BY s.sic_section;

SELECT * FROM res_sector ORDER BY pct_negative DESC;

-- 07c. Region snapshot (Unknown = company left the register, shown for transparency)
DROP TABLE IF EXISTS res_region;
CREATE TABLE res_region AS
SELECT r.region,
       count(*)                                                                 AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Thin')     / count(*), 1) AS pct_thin,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Healthy')  / count(*), 1) AS pct_healthy,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.equity_ratio)::numeric, 3) AS median_equity_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.total_assets)::numeric)    AS median_assets,
       (count(*) >= 30)                                                          AS is_reliable
FROM fact_company_year f
JOIN dim_region r ON r.region_key = f.region_key
WHERE f.in_central_population
GROUP BY r.region;

SELECT * FROM res_region ORDER BY pct_negative DESC;

-- 07d. Size-class snapshot (latest-accounts size class, indicative only)
DROP TABLE IF EXISTS res_size;
CREATE TABLE res_size AS
SELECT z.size_class,
       count(*)                                                                 AS n,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Negative') / count(*), 1) AS pct_negative,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Thin')     / count(*), 1) AS pct_thin,
       round(100.0 * count(*) FILTER (WHERE f.state_10 = 'Healthy')  / count(*), 1) AS pct_healthy,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.equity_ratio)::numeric, 3) AS median_equity_ratio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY f.total_assets)::numeric)    AS median_assets
FROM fact_company_year f
JOIN dim_size z ON z.size_key = f.size_key
WHERE f.in_central_population
GROUP BY z.size_class;

SELECT * FROM res_size ORDER BY median_assets;
