# PostgreSQL manager oversight

This project imports six portfolio CSVs and reports return-data exceptions, allocation exceptions, overdue diligence and benchmark-relative performance. Database: `portfolio_lab`. Schema: `portfolio`.

The dataset combines real historical research returns with fictional manager identities and operational inputs. It is an independent case study. Data cover January 2021–December 2025; oversight is fixed at December 31, 2025. Performance comparisons initially use the twelve months of 2025.

## First-time setup in pgAdmin

1. Open Postgres.app and confirm the local server is running. Open pgAdmin and connect to that server using the role and password from the existing connection. This project does not require a new database user.
2. In pgAdmin's left-hand Browser panel, expand the server and Databases. Right-click the existing `postgres` database and open Query Tool.
3. Open `00_create_database.sql`. Execute its one statement with auto-commit enabled. Database creation must run alone, outside a transaction. If `portfolio_lab` already exists, inspect it and use it only if it belongs to this project; do not delete another database to resolve the name conflict.
4. Refresh Databases. Right-click `portfolio_lab` and open a NEW Query Tool. Creating a database does not automatically connect the old Query Tool to it.
5. Confirm the new connection with `SELECT current_database();`. Its result must be `portfolio_lab`.
6. Open and run `01_setup.sql` in this connection. It creates the schema, six import tables, settings, scenario list and supporting views. This script is intended to run once; it does not drop or replace existing tables.
7. Refresh `portfolio_lab > Schemas > portfolio > Tables` to see the tables.

A database is the top-level project container. A schema is a namespace inside that database. `portfolio.managers` means the `managers` table in the `portfolio` schema. A new schema alone could work inside an existing database, but a separate project database keeps the exercise organized.

## Import the CSVs

The six CSVs are in `/absolute/path/to/investment-analytics-portfolio/data/`. Table column order matches CSV column order. `NUMERIC` preserves decimal values, and `DATE` parses the supplied ISO dates.

### Option A: SQL import on the local server

Run `02_import_pgadmin.sql` in Query Tool while connected to `portfolio_lab`. It uses ordinary SQL `COPY`, so PostgreSQL itself must have permission to read these local files. The script wraps all six imports in one transaction. If any import fails, run `ROLLBACK;` in that same Query Tool before doing anything else. After rollback, none of that transaction's imports should remain.

Expected row counts:

| Table | Rows |
|---|---:|
| managers | 6 |
| manager_returns | 360 |
| market_data | 60 |
| allocations | 12 |
| reviews | 6 |
| policy_limits | 4 |

`HEADER TRUE` skips the header. It does not match columns by name. The supplied table definitions and CSV order must stay aligned.

### Option B: pgAdmin Import/Export Data

If COPY reports a file-access or permission error, roll back the failed transaction, then use the table's Import/Export Data dialog where supported by the pgAdmin connection. Choose Import, the matching CSV, format CSV, UTF8 encoding, comma delimiter, and Header enabled. Keep all columns selected in their existing order. Import managers first, then returns, market data, allocations, reviews and policy limits. The review table references manager IDs, so managers must exist before reviews are imported.

GUI path access still depends on where pgAdmin and PostgreSQL run. If the connection is remote or the dialog cannot read the files, use client-side `\copy` through psql. `\copy` is a psql command, NOT SQL for Query Tool. Do not change COPY to \copy inside pgAdmin's Query Tool.

Example for psql only:

```text
\copy portfolio.managers FROM '/absolute/path/to/investment-analytics-portfolio/data/managers.csv' WITH (FORMAT CSV, HEADER TRUE)
```

Import only once with one method. The return and allocation tables intentionally allow duplicates for the monitoring exercise, so importing them twice would append duplicate rows. Check table counts before retrying an import. This package does not automatically clear existing records.

## Run the monitoring queries

Run `03_monitoring.sql` after import. It creates reusable views and includes SELECT queries to inspect them. In pgAdmin, highlight one SELECT statement and execute it to see that result on its own. Running the whole file may show only the last result grid even though all views were created successfully.

| Question | Main view | Expected baseline result |
|---|---|---|
| Missing monthly rows or blank return values? | portfolio.missing_returns | No rows |
| Duplicate manager-month keys? | portfolio.duplicate_returns | No rows |
| Scenario weights fail to total 100%? | portfolio.weight_exceptions | No rows |
| Any allocation over 35%? | portfolio.allocation_limit_exceptions | Sue, Current, 40%; 5 percentage points above limit |
| Any overdue reviews? | portfolio.overdue_reviews | Frank and Dave |
| Any benchmark lag greater than 5 percentage points? | portfolio.underperformance_exceptions | Frank, Mary and Ellen in 2025 |

Additional queries identify invalid manager IDs, dates outside the expected month-end grid, impossible returns, missing/duplicate allocation records, unknown scenarios and missing review dates.

Examples to rerun individually:

```sql
SELECT * FROM portfolio.missing_returns;
SELECT * FROM portfolio.duplicate_returns;
SELECT * FROM portfolio.weight_totals ORDER BY scenario;
SELECT * FROM portfolio.weight_exceptions;
SELECT * FROM portfolio.allocation_limit_exceptions;
SELECT * FROM portfolio.overdue_reviews;
SELECT * FROM portfolio.period_performance ORDER BY manager_id;
SELECT * FROM portfolio.underperformance_exceptions;
```

No rows in an exception view means that check found no exceptions. It does not independently prove that the dataset loaded; the row-count and completeness checks establish that.

### Reading the SQL

- `SELECT` chooses the output columns; `FROM` identifies the input table.
- `WHERE` filters individual rows before aggregation.
- `JOIN` matches tables on shared keys, such as `manager_id`.
- `LEFT JOIN` retains the expected record even when a matching actual record is absent.
- `CROSS JOIN` pairs every row from one input with every row from another. Managers crossed with expected months create the complete 360-row calendar.
- `GROUP BY` groups records before calculations such as `COUNT` and `SUM`.
- `HAVING` filters groups after aggregation, such as groups with `COUNT(*) > 1`.
- `CASE` supplies conditional labels or values.
- A CTE (`WITH name AS (...)`) breaks a larger query into named steps.
- A view stores a query definition. It recalculates when queried; it does not store a frozen copy of the results.

### Why returns are not added

Two monthly returns of 10% and -10% produce `(1.10 * 0.90) - 1 = -1%`, not 0%. The performance query compounds returns with `EXP(SUM(LN(1 + return_decimal))) - 1`, handles a valid -100% total-loss month separately, and suppresses results when observations are missing, duplicated or invalid.

`excess_return` is the compounded manager return minus the compounded benchmark return. Multiplying it by 100 expresses the difference in percentage points. It is not compounded monthly excess returns, a relative wealth ratio or an estimate of alpha.

The assigned benchmark is joined through `managers.benchmark_id`. This dataset assigns US_MARKET to all six managers. The market total return is `Mkt-RF + RF`, not Mkt-RF alone. New benchmark IDs require corresponding benchmark series; without one, the query reports `Check benchmark data` rather than substituting a benchmark.

The main policy threshold is a lag strictly greater than five percentage points (`excess_return < -0.05`). The script also provides a separate query for any negative benchmark difference. The six style proxies have different exposures from the broad market, so neither comparison proves manager skill or lack of skill.

The initial settings are full calendar months. Changing `performance_start` or `performance_end` changes the evaluated months; the query always includes each selected calendar month in full. Keep dates at the first day of the first month and the last day of the last month. The RETURN_LAG policy is defined for twelve months; a different horizon needs a separately justified threshold and label.

## Reproduce validation.json

Run `04_validation.sql`. Then run:

```sql
SELECT * FROM portfolio.validation_checklist ORDER BY check_name;
SELECT jsonb_pretty(actual) FROM portfolio.validation_actual;
```

The first query shows expected value, actual value and PASS/FAIL for all nine fields in the original validation.json. The second returns the actual values in the same JSON structure. The original file is included under `reference/` for comparison.

For the original baseline, all nine checks should PASS. The arrays use stable manager IDs, so replacing placeholder names with Frank, Mary, Ellen, Sue, Dave and Richard does not change the expected JSON.

`duplicate_return_keys` counts repeated manager-month groups, not excess rows. `missing_return_values` counts explicit NULL values in stored rows; a completely absent row is detected separately by `missing_returns`. `both_weight_totals` is 1.0 only when both scenarios sum to 1 with populated weights; detailed totals are available in `weight_totals`.

Validation also checks 60 distinct months per manager, missing expected rows, invalid records, allocation records, performance completeness and benchmark arithmetic. The baseline JSON is a regression checklist, not a comprehensive data-quality certificate. Its expected values remain tied to the original dataset and reporting date.

## Portfolio documentation

Returns are historical research portfolio proxies. Manager names, reviews, allocations and policy limits are fictional. The intake tables deliberately permit certain defects so that queries can detect them; malformed dates or non-numeric strings still fail typed CSV import. A production pipeline would normally validate intake data before loading constrained reporting tables.

The SQL is supplied for a local setup; change the path prefix when running it on another machine. No credentials are embedded in the scripts.

## Verified baseline results

The setup, all six imports, monitoring views and validation queries were executed against PostgreSQL 18.6 in an isolated test database. All nine original JSON checks passed. Additional transaction tests confirmed detection of missing rows, duplicate keys, NULL returns, incorrect weight totals, an absent scenario and a missing benchmark mapping. Exact-limit and due-today boundaries, a -100% return and an invalid return below -100% were also checked. Test modifications were rolled back. The optional `test_monitoring.sql` file is separate from the beginner setup sequence.

| Manager | 2025 proxy return | Assigned market return | Difference (percentage points) |
|---|---:|---:|---:|
| Frank | 8.95% | 17.54% | -8.59 |
| Mary | 11.41% | 17.54% | -6.13 |
| Ellen | 11.51% | 17.54% | -6.03 |
| Sue | 17.99% | 17.54% | 0.44 |
| Dave | 13.41% | 17.54% | -4.13 |
| Richard | 32.85% | 17.54% | 15.31 |

Differences are calculated before display rounding. Ellen is a candidate, not an allocated manager in Current. Frank's review is 77 days overdue and Dave's is 31 days overdue as of December 31, 2025.

## References

- [PostgreSQL CREATE DATABASE](https://www.postgresql.org/docs/current/sql-createdatabase.html)
- [PostgreSQL COPY](https://www.postgresql.org/docs/current/sql-copy.html)
- [PostgreSQL psql and client-side copy](https://www.postgresql.org/docs/current/app-psql.html)
- [Kenneth French Data Library](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html)
