-- Run after 03_monitoring.sql. This reproduces every validation.json field.
-- Expected values describe the ORIGINAL 2021-2025 baseline, not future refreshes.
CREATE OR REPLACE VIEW portfolio.validation_actual AS
SELECT jsonb_build_object(
    'months', (SELECT COUNT(DISTINCT month_end) FROM portfolio.manager_returns),
    'manager_return_rows', (SELECT COUNT(*) FROM portfolio.manager_returns),
    'duplicate_return_keys', (SELECT COUNT(*) FROM portfolio.duplicate_returns),
    'missing_return_values', (SELECT COUNT(*) FROM portfolio.manager_returns WHERE return_decimal IS NULL),
    'both_weight_totals', (SELECT CASE WHEN COUNT(*) = 2
                                AND BOOL_AND(COALESCE(total_weight = 1, FALSE)
                                             AND allocation_rows > 0
                                             AND allocation_rows = populated_weights)
                                THEN 1.0 ELSE NULL END FROM portfolio.weight_totals),
    'current_allocation_breaches', (SELECT COALESCE(jsonb_agg(manager_id ORDER BY manager_id), '[]'::JSONB)
                                  FROM portfolio.allocation_limit_exceptions WHERE scenario = 'Current'),
    'overdue_reviews_at_2025_12_31', (SELECT COALESCE(jsonb_agg(manager_id ORDER BY manager_id), '[]'::JSONB)
                                    FROM portfolio.overdue_reviews),
    'first_return', (SELECT jsonb_build_array(to_char(month_end, 'YYYY-MM-DD'), manager_id, return_decimal)
                     FROM portfolio.manager_returns ORDER BY month_end, manager_id LIMIT 1),
    'last_return', (SELECT jsonb_build_array(to_char(month_end, 'YYYY-MM-DD'), manager_id, return_decimal)
                    FROM portfolio.manager_returns ORDER BY month_end DESC, manager_id DESC LIMIT 1)
) AS actual;

CREATE OR REPLACE VIEW portfolio.validation_checklist AS
WITH expected AS (
    SELECT '{
      "months": 60,
      "manager_return_rows": 360,
      "duplicate_return_keys": 0,
      "missing_return_values": 0,
      "both_weight_totals": 1.0,
      "current_allocation_breaches": ["M04"],
      "overdue_reviews_at_2025_12_31": ["M01", "M05"],
      "first_return": ["2021-01-31", "M01", 0.05489],
      "last_return": ["2025-12-31", "M06", 0.037871]
    }'::JSONB AS baseline
)
SELECT e.key AS check_name, e.value AS expected_value,
       a.actual -> e.key AS actual_value,
       CASE WHEN a.actual -> e.key = e.value THEN 'PASS' ELSE 'FAIL' END AS result
FROM expected x
CROSS JOIN LATERAL jsonb_each(x.baseline) e
CROSS JOIN portfolio.validation_actual a;

SELECT * FROM portfolio.validation_checklist ORDER BY check_name;

-- Same JSON structure as validation.json, computed from imported records.
SELECT jsonb_pretty(actual) AS reproduced_validation_json FROM portfolio.validation_actual;

-- These checks strengthen the original JSON: it does not detect every defect.
SELECT m.manager_id, m.manager_name, COUNT(r.month_end) AS return_rows,
       COUNT(DISTINCT r.month_end) AS distinct_months,
       COUNT(r.return_decimal) AS populated_returns
FROM portfolio.managers m
LEFT JOIN portfolio.manager_returns r ON r.manager_id = m.manager_id
GROUP BY m.manager_id, m.manager_name ORDER BY m.manager_id;

SELECT 'Missing expected returns' AS check_name, COUNT(*) AS issues FROM portfolio.missing_returns
UNION ALL SELECT 'Invalid return records', COUNT(*) FROM portfolio.invalid_returns
UNION ALL SELECT 'Allocation record exceptions', COUNT(*) FROM portfolio.allocation_record_exceptions
UNION ALL SELECT 'Weight total exceptions', COUNT(*) FROM portfolio.weight_exceptions
UNION ALL SELECT 'Incomplete performance calculations', COUNT(*) FROM portfolio.period_performance WHERE data_status <> 'Complete';

-- Missing benchmark months or values. Expect zero rows.
SELECT e.month_end FROM portfolio.expected_months e
LEFT JOIN portfolio.market_data b ON b.month_end = e.month_end
WHERE b.month_end IS NULL OR b.market_return_decimal IS NULL;

-- Reconstruct total market return. Expect zero rows.
SELECT * FROM portfolio.market_data
WHERE market_return_decimal IS NULL OR mkt_excess_decimal IS NULL OR rf_decimal IS NULL
   OR ABS(market_return_decimal - (mkt_excess_decimal + rf_decimal)) > 0.00000001;
