-- Run in portfolio_lab. This setup is intended to run once.
-- A transaction prevents a partially created setup if a statement fails.
BEGIN;
CREATE SCHEMA portfolio;

-- A primary key prevents duplicate IDs in the reference table.
CREATE TABLE portfolio.managers (
    manager_id TEXT PRIMARY KEY,
    manager_name TEXT NOT NULL,
    strategy_style TEXT NOT NULL,
    source_column TEXT NOT NULL,
    status TEXT NOT NULL,
    benchmark_id TEXT NOT NULL,
    data_basis TEXT NOT NULL
);

-- This is an intake table. Missing and duplicate records remain inspectable.
-- No primary key or NOT NULL rule is imposed on the incoming return fields.
CREATE TABLE portfolio.manager_returns (
    month_end DATE,
    manager_id TEXT,
    return_decimal NUMERIC
);

CREATE TABLE portfolio.market_data (
    month_end DATE PRIMARY KEY,
    market_return_decimal NUMERIC,
    mkt_excess_decimal NUMERIC,
    smb_decimal NUMERIC,
    hml_decimal NUMERIC,
    rf_decimal NUMERIC
);

CREATE TABLE portfolio.allocations (
    scenario TEXT,
    manager_id TEXT,
    target_weight NUMERIC
);

CREATE TABLE portfolio.reviews (
    review_id TEXT PRIMARY KEY,
    manager_id TEXT REFERENCES portfolio.managers(manager_id),
    last_review_date DATE,
    next_review_due DATE,
    review_type TEXT,
    open_item TEXT
);

CREATE TABLE portfolio.policy_limits (
    rule_id TEXT PRIMARY KEY,
    metric TEXT NOT NULL,
    operator TEXT NOT NULL,
    threshold NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    description TEXT
);

-- These controls are fixed for this case study, rather than today's date.
CREATE TABLE portfolio.settings (
    settings_id INTEGER PRIMARY KEY CHECK (settings_id = 1),
    analysis_start DATE NOT NULL,
    analysis_end DATE NOT NULL,
    as_of_date DATE NOT NULL,
    performance_start DATE NOT NULL,
    performance_end DATE NOT NULL,
    CHECK (analysis_start <= analysis_end),
    CHECK (performance_start <= performance_end)
);
INSERT INTO portfolio.settings VALUES
    (1, '2021-01-01', '2025-12-31', '2025-12-31', '2025-01-01', '2025-12-31');

CREATE TABLE portfolio.scenarios (scenario TEXT PRIMARY KEY);
INSERT INTO portfolio.scenarios VALUES ('Current'), ('Proposed');

-- Convert each generated month to its calendar month-end.
CREATE VIEW portfolio.expected_months AS
SELECT (month_start + INTERVAL '1 month - 1 day')::DATE AS month_end
FROM portfolio.settings s
CROSS JOIN LATERAL generate_series(
    date_trunc('month', s.analysis_start::TIMESTAMP),
    date_trunc('month', s.analysis_end::TIMESTAMP),
    INTERVAL '1 month'
) AS dates(month_start);

-- Explicit mapping between the assigned benchmark ID and its return series.
CREATE VIEW portfolio.benchmark_returns AS
SELECT 'US_MARKET'::TEXT AS benchmark_id, month_end,
       market_return_decimal AS return_decimal
FROM portfolio.market_data;
COMMIT;
