-- Run in the pgAdmin Query Tool, connected to portfolio_lab, after 01_setup.sql.
-- COPY reads from the PostgreSQL SERVER's filesystem.
-- These paths work when the local server can read this Mac's Documents folder.
-- If access is denied, use the Import/Export Data dialog described in README.md.
-- Run once. Re-importing would append duplicate intake records.
BEGIN;
COPY portfolio.managers
FROM '/absolute/path/to/investment-analytics-portfolio/data/managers.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY portfolio.manager_returns
FROM '/absolute/path/to/investment-analytics-portfolio/data/manager_returns.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY portfolio.market_data
FROM '/absolute/path/to/investment-analytics-portfolio/data/market_data.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY portfolio.allocations
FROM '/absolute/path/to/investment-analytics-portfolio/data/allocations.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY portfolio.reviews
FROM '/absolute/path/to/investment-analytics-portfolio/data/reviews.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY portfolio.policy_limits
FROM '/absolute/path/to/investment-analytics-portfolio/data/policy_limits.csv'
WITH (FORMAT CSV, HEADER TRUE);
COMMIT;

-- Six rows of import counts. Compare with 6, 360, 60, 12, 6 and 4.
SELECT 'managers' AS table_name, COUNT(*) AS row_count FROM portfolio.managers
UNION ALL SELECT 'manager_returns', COUNT(*) FROM portfolio.manager_returns
UNION ALL SELECT 'market_data', COUNT(*) FROM portfolio.market_data
UNION ALL SELECT 'allocations', COUNT(*) FROM portfolio.allocations
UNION ALL SELECT 'reviews', COUNT(*) FROM portfolio.reviews
UNION ALL SELECT 'policy_limits', COUNT(*) FROM portfolio.policy_limits;
