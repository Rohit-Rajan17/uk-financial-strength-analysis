-- 06b_index_explain.sql
-- What an index changes: EXPLAIN ANALYZE on a lookup by company number, before and after.
-- Run each statement on its own (Cmd+Enter in DBeaver).
-- Without the index Postgres reads every row (Seq Scan); with it, it goes straight to the row
-- (Index Scan). At 51,516 rows both are fast. The point is that the plan changes, and the gap
-- grows with the size of the table.

-- 1. Clean start
DROP INDEX IF EXISTS ix_company_number;

-- 2. BEFORE: no index on company_number, so Postgres must read every row (Seq Scan)
EXPLAIN ANALYZE SELECT * FROM dim_company WHERE company_number = '08936252';

-- 3. Create the index
CREATE INDEX ix_company_number ON dim_company (company_number);

-- 4. Refresh the planner's statistics
ANALYZE dim_company;

-- 5. AFTER: Postgres jumps straight to the row (Index Scan)
EXPLAIN ANALYZE SELECT * FROM dim_company WHERE company_number = '08936252';
