-- 09_transitions.sql
-- 09a. Year-to-year pairs with LAG(). A pair is kept only if the years are exactly one fiscal year apart and the
-- period-end dates are 300 to 430 days apart. Both years must be usable: GBP, not Dormant, not extreme equity,
-- equity present, assets above 0. Expect 32,841 pairs from 30,248 companies.
DROP TABLE IF EXISTS res_pairs;
CREATE TABLE res_pairs AS
WITH u AS (
  SELECT company_id, fiscal_year, period_end, state_10, sector_key, region_key, size_key
  FROM fact_company_year
  WHERE is_gbp AND NOT is_dormant_accounts AND NOT is_extreme_equity
    AND equity IS NOT NULL AND total_assets > 0
), p AS (
  SELECT company_id, fiscal_year,
         LAG(fiscal_year) OVER w AS prev_year,
         LAG(period_end)  OVER w AS prev_end,
         period_end,
         LAG(state_10) OVER w AS prev_state,
         state_10 AS this_state,
         sector_key, region_key
  FROM u
  WINDOW w AS (PARTITION BY company_id ORDER BY fiscal_year)
)
SELECT *, (period_end - prev_end) AS gap_days
FROM p
WHERE prev_year = fiscal_year - 1
  AND (period_end - prev_end) BETWEEN 300 AND 430;

SELECT count(*) AS pairs, count(DISTINCT company_id) AS companies FROM res_pairs;

-- 09b. Transition matrix
SELECT prev_state, this_state, count(*) AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY prev_state), 1) AS pct_of_prev
FROM res_pairs GROUP BY prev_state, this_state ORDER BY prev_state, this_state;
