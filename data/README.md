# Shared data

Six fictional managers represent the Kenneth French six size/book-to-market research portfolios. Observations cover January 2021–December 2025 (60 months; 360 manager-month records).

| ID | Manager | Research style |
|---|---|---|
| M01 | Frank | Small growth |
| M02 | Mary | Small neutral |
| M03 | Ellen | Small value |
| M04 | Sue | Large growth |
| M05 | Dave | Large neutral |
| M06 | Richard | Large value |

`manager_returns.csv` contains monthly decimal returns. `market_data.csv` contains market and factor data, including the risk-free series. `allocations.csv` contains Current and Proposed fixed target weights. `managers.csv`, `reviews.csv`, and `policy_limits.csv` provide fictional business metadata and controls. Returns and weights are decimals: 0.10 means 10%.

Oversight date: December 31, 2025. Initial underperformance review: calendar year 2025, against the assigned U.S. market benchmark, with a lag strictly greater than five percentage points. The study-wide analytics use 2021–2025.

## Sources

- [Kenneth French Data Library](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html)
- [Six portfolios formed on size and book-to-market](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/six_portfolios.html)
- [Fama/French factors](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html)

The source vintage is August 2026 CRSP. `source_manifest.json` records the downloaded source archive URLs and SHA-256 hashes; those raw archives are not included here. `validation.json` records the baseline checks. Derived values retain the source attribution; no ownership of the underlying research data is asserted.
