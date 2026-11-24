-- 13_validity.sql
-- Validity test: are FY2024 negative-equity companies more likely to show an adverse register status
-- (May 2026 snapshot: proposal to strike off, liquidation, voluntary arrangement, administration, receiver)
-- or to have left the register? Central population, pseudo-sectors excluded.
-- Result: a weak signal (adverse 2.46% vs 1.79% for healthy, about 1.4x); no signal for leaving the register.
-- So negative equity is a screen for review, not a predictor of failure.
DROP TABLE IF EXISTS res_validity;
CREATE TABLE res_validity AS
SELECT f.state_10 AS state_fy2024,
       count(*) AS n,
       count(*) FILTER (WHERE c.company_status IN ('Active - Proposal to Strike off','Liquidation','Voluntary Arrangement','In Administration','Live but Receiver Manager on at least one charge')) AS adverse,
       count(*) FILTER (WHERE c.company_status IS NULL) AS left_register,
       round(100.0 * count(*) FILTER (WHERE c.company_status IN ('Active - Proposal to Strike off','Liquidation','Voluntary Arrangement','In Administration','Live but Receiver Manager on at least one charge')) / count(*), 2) AS pct_adverse,
       round(100.0 * count(*) FILTER (WHERE c.company_status IS NULL) / count(*), 2) AS pct_left_register
FROM fact_company_year f
JOIN dim_company c ON c.company_id = f.company_id
WHERE f.in_central_population AND NOT f.is_pseudo_sector
GROUP BY f.state_10;

SELECT * FROM res_validity ORDER BY state_fy2024;
