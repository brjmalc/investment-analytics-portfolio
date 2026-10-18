-- Run this file once to create the views. SELECT statements can be rerun freely.
-- A view saves a query, not a frozen result; it reflects the underlying tables.

-- 1A. Missing rows OR rows present with a missing return value.
-- CROSS JOIN creates the complete expected grid: six managers x 60 months.
CREATE OR REPLACE VIEW portfolio.missing_returns AS
SELECT m.manager_id, m.manager_name, e.month_end,
       CASE WHEN r.manager_id IS NULL THEN 'Missing record'
            ELSE 'Missing return value' END AS issue
FROM portfolio.managers m
CROSS JOIN portfolio.expected_months e
LEFT JOIN portfolio.manager_returns r
  ON r.manager_id = m.manager_id AND r.month_end = e.month_end
WHERE r.manager_id IS NULL OR r.return_decimal IS NULL;

SELECT * FROM portfolio.missing_returns ORDER BY manager_id, month_end;

-- 1B. Duplicate keys: more than one row for the same manager and month.
CREATE OR REPLACE VIEW portfolio.duplicate_returns AS
SELECT manager_id, month_end, COUNT(*) AS record_count
FROM portfolio.manager_returns
GROUP BY manager_id, month_end
HAVING COUNT(*) > 1;

SELECT * FROM portfolio.duplicate_returns ORDER BY manager_id, month_end;

-- Additional intake checks: invalid IDs, dates and impossible total returns.
CREATE OR REPLACE VIEW portfolio.invalid_returns AS
SELECT r.*
FROM portfolio.manager_returns r
LEFT JOIN portfolio.managers m ON m.manager_id = r.manager_id
LEFT JOIN portfolio.expected_months e ON e.month_end = r.month_end
WHERE m.manager_id IS NULL OR e.month_end IS NULL
   OR r.return_decimal < -1
   OR r.return_decimal::TEXT IN ('NaN', 'Infinity', '-Infinity');

SELECT * FROM portfolio.invalid_returns;

-- 2. Weights that fail to total 100%, including missing whole scenarios.
CREATE OR REPLACE VIEW portfolio.weight_totals AS
SELECT s.scenario, COUNT(a.manager_id) AS allocation_rows,
       COUNT(a.target_weight) AS populated_weights,
       SUM(a.target_weight) AS total_weight
FROM portfolio.scenarios s
LEFT JOIN portfolio.allocations a ON a.scenario = s.scenario
GROUP BY s.scenario;

CREATE OR REPLACE VIEW portfolio.weight_exceptions AS
SELECT w.scenario, w.allocation_rows, w.populated_weights,
       w.total_weight, ROUND(w.total_weight * 100, 4) AS total_weight_pct
FROM portfolio.weight_totals w
CROSS JOIN portfolio.policy_limits p
WHERE p.rule_id = 'WEIGHT_SUM'
  AND (w.allocation_rows = 0
       OR w.populated_weights <> w.allocation_rows
       OR w.total_weight IS NULL
       OR ABS(w.total_weight - 1) > p.threshold);

SELECT * FROM portfolio.weight_totals ORDER BY scenario;
SELECT * FROM portfolio.weight_exceptions ORDER BY scenario;

-- A sum of 100% alone does not establish complete, valid allocations.
CREATE OR REPLACE VIEW portfolio.allocation_record_exceptions AS
SELECT s.scenario, m.manager_id, COUNT(a.manager_id) AS record_count
FROM portfolio.scenarios s
CROSS JOIN portfolio.managers m
LEFT JOIN portfolio.allocations a
  ON a.scenario = s.scenario AND a.manager_id = m.manager_id
GROUP BY s.scenario, m.manager_id
HAVING COUNT(a.manager_id) <> 1
    OR COUNT(a.target_weight) <> 1
    OR MIN(a.target_weight) < 0 OR MAX(a.target_weight) > 1;

SELECT * FROM portfolio.allocation_record_exceptions;
SELECT a.* FROM portfolio.allocations a
LEFT JOIN portfolio.scenarios s ON s.scenario = a.scenario
LEFT JOIN portfolio.managers m ON m.manager_id = a.manager_id
WHERE s.scenario IS NULL OR m.manager_id IS NULL
   OR a.target_weight::TEXT IN ('NaN', 'Infinity', '-Infinity');

-- 3. Managers above the allocation limit. We aggregate in case rows repeat.
CREATE OR REPLACE VIEW portfolio.allocation_limit_exceptions AS
SELECT a.scenario, m.manager_id, m.manager_name,
       SUM(a.target_weight) AS manager_weight,
       p.threshold AS allocation_limit,
       ROUND((SUM(a.target_weight) - p.threshold) * 100, 2) AS excess_percentage_points
FROM portfolio.allocations a
JOIN portfolio.managers m ON m.manager_id = a.manager_id
CROSS JOIN portfolio.policy_limits p
WHERE p.rule_id = 'MAX_WEIGHT'
GROUP BY a.scenario, m.manager_id, m.manager_name, p.threshold
HAVING SUM(a.target_weight) > p.threshold;

SELECT * FROM portfolio.allocation_limit_exceptions ORDER BY scenario, manager_id;

-- 4. Overdue diligence reviews, evaluated at the fixed oversight date.
CREATE OR REPLACE VIEW portfolio.overdue_reviews AS
SELECT m.manager_id, m.manager_name, r.review_id,
       r.next_review_due, s.as_of_date,
       s.as_of_date - r.next_review_due AS days_overdue, r.open_item
FROM portfolio.reviews r
JOIN portfolio.managers m ON m.manager_id = r.manager_id
CROSS JOIN portfolio.settings s
CROSS JOIN portfolio.policy_limits p
WHERE p.rule_id = 'OVERDUE'
  AND s.as_of_date - r.next_review_due > p.threshold;

SELECT * FROM portfolio.overdue_reviews ORDER BY days_overdue DESC;

-- A missing review or due date is unknown, not an on-time review.
SELECT m.manager_id, m.manager_name, r.review_id, r.next_review_due
FROM portfolio.managers m
LEFT JOIN portfolio.reviews r ON r.manager_id = m.manager_id
WHERE r.review_id IS NULL OR r.next_review_due IS NULL;

-- 5. Compounded performance over the selected period (initially calendar 2025).
-- Product(1 + r) = EXP(SUM(LN(1 + r))). The -100% case is handled separately.
-- The monthly grid exposes missing months. Counts expose duplicate records.
CREATE OR REPLACE VIEW portfolio.period_performance AS
WITH period_months AS (
    SELECT (month_start + INTERVAL '1 month - 1 day')::DATE AS month_end
    FROM portfolio.settings s
    CROSS JOIN LATERAL generate_series(
        date_trunc('month', s.performance_start::TIMESTAMP),
        date_trunc('month', s.performance_end::TIMESTAMP),
        INTERVAL '1 month'
    ) AS dates(month_start)
), manager_summary AS (
    SELECT m.manager_id,
           COUNT(r.month_end) AS return_rows,
           COUNT(DISTINCT r.month_end) AS distinct_months,
           COUNT(r.return_decimal) AS populated_returns,
           COUNT(*) FILTER (WHERE r.return_decimal < -1
             OR r.return_decimal::TEXT IN ('NaN', 'Infinity', '-Infinity')) AS invalid_values,
           CASE WHEN MIN(r.return_decimal) = -1 THEN -1
                ELSE EXP(SUM(LN(CASE WHEN r.return_decimal > -1
                       AND r.return_decimal::TEXT NOT IN ('NaN', 'Infinity', '-Infinity')
                       THEN 1 + r.return_decimal END))) - 1
           END AS calculated_return
    FROM portfolio.managers m CROSS JOIN period_months e
    LEFT JOIN portfolio.manager_returns r
      ON r.manager_id = m.manager_id AND r.month_end = e.month_end
    GROUP BY m.manager_id
), benchmark_summary AS (
    SELECT m.manager_id, COUNT(b.return_decimal) AS populated_returns,
           COUNT(*) FILTER (WHERE b.return_decimal < -1
             OR b.return_decimal::TEXT IN ('NaN', 'Infinity', '-Infinity')) AS invalid_values,
           CASE WHEN MIN(b.return_decimal) = -1 THEN -1
                ELSE EXP(SUM(LN(CASE WHEN b.return_decimal > -1
                       AND b.return_decimal::TEXT NOT IN ('NaN', 'Infinity', '-Infinity')
                       THEN 1 + b.return_decimal END))) - 1
           END AS calculated_return
    FROM portfolio.managers m CROSS JOIN period_months e
    LEFT JOIN portfolio.benchmark_returns b
      ON b.benchmark_id = m.benchmark_id AND b.month_end = e.month_end
    GROUP BY m.manager_id
), quality AS (
    SELECT m.manager_id, m.manager_name, m.benchmark_id,
           s.performance_start, s.performance_end,
           (SELECT COUNT(*) FROM period_months) AS expected_months,
           r.return_rows, r.distinct_months, b.populated_returns AS benchmark_months,
           r.calculated_return AS manager_return,
           b.calculated_return AS benchmark_return,
           CASE WHEN r.return_rows <> (SELECT COUNT(*) FROM period_months)
                  OR r.distinct_months <> (SELECT COUNT(*) FROM period_months)
                  OR r.populated_returns <> (SELECT COUNT(*) FROM period_months)
                  OR r.invalid_values > 0 THEN 'Check manager data'
                WHEN b.populated_returns <> (SELECT COUNT(*) FROM period_months)
                  OR b.invalid_values > 0 THEN 'Check benchmark data'
                ELSE 'Complete' END AS data_status
    FROM portfolio.managers m
    JOIN manager_summary r ON r.manager_id = m.manager_id
    JOIN benchmark_summary b ON b.manager_id = m.manager_id
    CROSS JOIN portfolio.settings s
)
SELECT manager_id, manager_name, benchmark_id, performance_start, performance_end,
       expected_months, return_rows, distinct_months, benchmark_months, data_status,
       CASE WHEN data_status = 'Complete' THEN manager_return END AS manager_return,
       CASE WHEN data_status = 'Complete' THEN benchmark_return END AS benchmark_return,
       CASE WHEN data_status = 'Complete' THEN manager_return - benchmark_return END AS excess_return
FROM quality;

-- Show ALL managers first, including any blocked performance calculations.
SELECT manager_id, manager_name, data_status,
       ROUND(manager_return * 100, 2) AS manager_return_pct,
       ROUND(benchmark_return * 100, 2) AS benchmark_return_pct,
       ROUND(excess_return * 100, 2) AS excess_percentage_points
FROM portfolio.period_performance ORDER BY manager_id;

-- Any underperformance: a negative difference versus the assigned benchmark.
SELECT manager_id, manager_name, ROUND(excess_return * 100, 2) AS excess_percentage_points
FROM portfolio.period_performance
WHERE data_status = 'Complete' AND excess_return < 0
ORDER BY excess_return;

-- The formal policy alert is a larger lag: strictly below -5 percentage points.
CREATE OR REPLACE VIEW portfolio.underperformance_exceptions AS
SELECT r.*, p.threshold AS return_lag_threshold
FROM portfolio.period_performance r
CROSS JOIN portfolio.policy_limits p
WHERE p.rule_id = 'RETURN_LAG'
  AND r.data_status = 'Complete' AND r.excess_return < p.threshold;

SELECT manager_id, manager_name, ROUND(excess_return * 100, 2) AS excess_percentage_points
FROM portfolio.underperformance_exceptions ORDER BY excess_return;
