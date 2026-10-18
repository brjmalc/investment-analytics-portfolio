-- Optional checks for an isolated test database. Every change is rolled back.
-- This is not part of the beginner setup sequence.
BEGIN;
DELETE FROM portfolio.manager_returns WHERE manager_id = 'M01' AND month_end = '2025-01-31';
DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.missing_returns) = 1, 'Missing row not detected';
    ASSERT (SELECT data_status FROM portfolio.period_performance WHERE manager_id = 'M01') = 'Check manager data';
    ASSERT (SELECT manager_return FROM portfolio.period_performance WHERE manager_id = 'M01') IS NULL;
END $$;
ROLLBACK;

BEGIN;
INSERT INTO portfolio.manager_returns SELECT * FROM portfolio.manager_returns WHERE manager_id = 'M01' AND month_end = '2025-01-31';
DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.duplicate_returns) = 1, 'Duplicate not detected';
    ASSERT (SELECT data_status FROM portfolio.period_performance WHERE manager_id = 'M01') = 'Check manager data';
END $$;
ROLLBACK;

BEGIN;
UPDATE portfolio.manager_returns SET return_decimal = NULL WHERE manager_id = 'M01' AND month_end = '2025-01-31';
DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.missing_returns) = 1, 'NULL return not detected';
    ASSERT (SELECT manager_return FROM portfolio.period_performance WHERE manager_id = 'M01') IS NULL;
END $$;
ROLLBACK;

BEGIN;
UPDATE portfolio.allocations SET target_weight = 0.09 WHERE scenario = 'Current' AND manager_id = 'M01';
DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.weight_exceptions) = 1, 'Incorrect weight sum not detected';
END $$;
ROLLBACK;

BEGIN;
DELETE FROM portfolio.allocations WHERE scenario = 'Proposed';
DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.weight_exceptions WHERE scenario = 'Proposed') = 1, 'Absent scenario not detected';
    ASSERT (SELECT result FROM portfolio.validation_checklist WHERE check_name = 'both_weight_totals') = 'FAIL';
END $$;
ROLLBACK;

BEGIN;
UPDATE portfolio.allocations SET target_weight = 0.35 WHERE scenario = 'Current' AND manager_id = 'M04';
UPDATE portfolio.reviews SET next_review_due = '2025-12-31' WHERE manager_id = 'M01';
DO $$ BEGIN
    ASSERT NOT EXISTS (SELECT 1 FROM portfolio.allocation_limit_exceptions WHERE manager_id = 'M04'), 'Exact limit wrongly flagged';
    ASSERT NOT EXISTS (SELECT 1 FROM portfolio.overdue_reviews WHERE manager_id = 'M01'), 'Due-today review wrongly flagged';
END $$;
ROLLBACK;

BEGIN;
UPDATE portfolio.managers SET benchmark_id = 'UNKNOWN' WHERE manager_id = 'M01';
DO $$ BEGIN
    ASSERT (SELECT data_status FROM portfolio.period_performance WHERE manager_id = 'M01') = 'Check benchmark data';
    ASSERT (SELECT excess_return FROM portfolio.period_performance WHERE manager_id = 'M01') IS NULL;
END $$;
ROLLBACK;

BEGIN;
UPDATE portfolio.manager_returns SET return_decimal = -1 WHERE manager_id = 'M01' AND month_end = '2025-01-31';
DO $$ BEGIN
    ASSERT (SELECT manager_return FROM portfolio.period_performance WHERE manager_id = 'M01') = -1, 'Total loss calculation failed';
END $$;
UPDATE portfolio.manager_returns SET return_decimal = -1.1 WHERE manager_id = 'M01' AND month_end = '2025-01-31';
DO $$ BEGIN
    ASSERT (SELECT data_status FROM portfolio.period_performance WHERE manager_id = 'M01') = 'Check manager data';
    ASSERT (SELECT manager_return FROM portfolio.period_performance WHERE manager_id = 'M01') IS NULL;
END $$;
ROLLBACK;

DO $$ BEGIN
    ASSERT (SELECT COUNT(*) FROM portfolio.validation_checklist WHERE result = 'PASS') = 9, 'Baseline not restored';
END $$;
