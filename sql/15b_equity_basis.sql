-- 15b_equity_basis.sql
-- Repeat the region and sector findings on the broader equity-only basis. The central population needs assets
-- above zero, which leaves out 11,880 rows that report equity but no assets. Here they are included:
-- GBP, FY2024, equity present, not Dormant, no pseudo-sectors, sector and region known.
-- Side by side: negative share and Wilson 95% interval on this basis, and the central-basis share.
DROP TABLE IF EXISTS res_equity_basis;
CREATE TABLE res_equity_basis AS
WITH e AS (
  SELECT f.company_id, f.state_10, f.equity, r.region, s.sic_section, f.in_central_population AS in_central
  FROM fact_company_year f
  JOIN dim_region r ON r.region_key = f.region_key
  JOIN dim_sector s ON s.sector_key = f.sector_key
  WHERE f.is_gbp AND f.fiscal_year = 2024 AND f.equity IS NOT NULL
    AND NOT f.is_dormant_accounts AND NOT f.is_pseudo_sector
    AND f.region_key <> 0 AND f.sector_key <> 0
), g AS (
  SELECT 'region' AS dim, region AS grp,
         count(*)::numeric AS n_e,
         (count(*) FILTER (WHERE equity < 0))::numeric AS x_e,
         count(*) FILTER (WHERE in_central) AS n_c,
         count(*) FILTER (WHERE in_central AND equity < 0) AS x_c
  FROM e GROUP BY region
  UNION ALL
  SELECT 'sector', sic_section,
         count(*)::numeric, (count(*) FILTER (WHERE equity < 0))::numeric,
         count(*) FILTER (WHERE in_central), count(*) FILTER (WHERE in_central AND equity < 0)
  FROM e GROUP BY sic_section
), p AS (
  SELECT *, x_e / n_e AS p FROM g WHERE n_e >= 30
)
SELECT dim, grp, n_e::int AS n_equity_basis,
       round(100 * p, 1) AS pct_neg_equity_basis,
       round(100 * (p + 1.96*1.96/(2*n_e) - 1.96 * sqrt(p*(1-p)/n_e + 1.96*1.96/(4*n_e*n_e))) / (1 + 1.96*1.96/n_e), 1) AS ci_low,
       round(100 * (p + 1.96*1.96/(2*n_e) + 1.96 * sqrt(p*(1-p)/n_e + 1.96*1.96/(4*n_e*n_e))) / (1 + 1.96*1.96/n_e), 1) AS ci_high,
       n_c AS n_central,
       round(100.0 * x_c / nullif(n_c,0), 1) AS pct_neg_central
FROM p;

SELECT grp, n_equity_basis, pct_neg_equity_basis, ci_low, ci_high, n_central, pct_neg_central
FROM res_equity_basis WHERE dim = 'region' ORDER BY pct_neg_equity_basis DESC;

SELECT grp, n_equity_basis, pct_neg_equity_basis, ci_low, ci_high, n_central, pct_neg_central
FROM res_equity_basis WHERE dim = 'sector' ORDER BY pct_neg_equity_basis DESC;
