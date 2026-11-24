-- 08a_rank_in_region.sql
-- Rank sectors within each region by share with negative equity. RANK() restarts for every region.
-- Only reliable cells (n >= 30) are ranked, so a tiny cell can't take rank 1 by luck.
DROP TABLE IF EXISTS res_sector_rank_in_region;
CREATE TABLE res_sector_rank_in_region AS
SELECT region, sic_section, n, pct_negative,
       RANK() OVER (PARTITION BY region ORDER BY pct_negative DESC) AS rank_in_region
FROM res_sector_region
WHERE is_reliable;

-- Rank 1 in each region (expect 12 rows)
SELECT region, sic_section, n, pct_negative, rank_in_region
FROM res_sector_rank_in_region
WHERE rank_in_region = 1
ORDER BY region;

-- How often each sector is in a region's top 3 (expect accommodation and food 11 of 11, real estate 9 of 12)
SELECT sic_section,
       count(*) FILTER (WHERE rank_in_region <= 3) AS times_top3,
       count(*) AS regions_reliable
FROM res_sector_rank_in_region
GROUP BY sic_section
ORDER BY times_top3 DESC, regions_reliable DESC
LIMIT 6;
