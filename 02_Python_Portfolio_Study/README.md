# Portfolio diversification and historical stress study

## Business question

Does reallocating 10 percentage points from Sue's large-growth proxy to Ellen's small-value proxy improve a hypothetical multi-manager equity portfolio?

The analysis compares Current and Proposed over January 2021–December 2025 and replays calendar year 2022. It reports annualized return and volatility, maximum drawdown, manager correlations, contribution to portfolio volatility, and stress-period results.

## Data and assumptions

Inputs are the shared managers, manager_returns, allocations and market_data CSV files. Historical returns come from the Kenneth French Data Library's six size/book-to-market portfolios and market factors, using the August 2026 CRSP vintage. Names and allocations are fictional. These are research proxies, not actual manager results.

Both portfolios rebalance monthly to fixed target weights. No additional fees, trading costs, taxes, borrowing or external cash flows are modelled. Total market return is reconstructed as Mkt-RF + RF. Monthly observations miss intra-month drawdowns.

## Run the study

See SETUP_VSCODE.md for installation and notebook-kernel selection. The main artifact is portfolio_diversification.ipynb. portfolio_study.py contains the same analysis as a script with VS Code cell markers.

The first cell locates the repository root from the working directory and uses its data folder. Run from the repository root or this project folder. Derived results are written to 02_Python_Portfolio_Study/outputs. Source files are not overwritten.

## Results and interpretation

See FINDINGS.md for the verified baseline comparison and its decision implications. The three figures show performance and drawdowns, manager correlations, and capital allocation versus risk contribution. CSV tables are suitable for subsequent dashboard work.

## Output definitions

- portfolio_metrics.csv: cumulative return, CAGR, annualized volatility and full-sample maximum drawdown.
- stress_2022.csv: 2022 compounded return, within-window drawdown, worst month and illustrative P&L on USD 100,000.
- scenario_comparison.csv: Current, Proposed and change in percentage points.
- monthly_portfolio_returns.csv: monthly scenario and benchmark total returns.
- wealth_index.csv: compounded wealth, initial value 1 on December 31, 2020.
- drawdowns.csv: wealth relative to its running peak, minus 1.
- risk_contributions.csv: capital weights, annualized volatility contributions and risk shares.
- manager_correlations.csv and manager_correlations_2022.csv: manager correlation matrices keyed by ID.
- candidate_correlations.csv: Ellen versus Sue and versus the Current portfolio.
- run_details.json: package versions and input SHA-256 hashes.

Returns, weights and risk shares are stored as decimals. Change columns labelled percentage_points are already multiplied by 100. Dollar P&L is in USD. Volatility contribution is in annualized return units and sums to portfolio volatility; risk shares sum to 1. A positive change in negative maximum drawdown means a shallower loss.

## Limitations

This is a fixed-allocation retrospective comparison selected after the observation period, not a live record, forecast, optimization or out-of-sample strategy test. The six proxies all represent U.S. equity exposure. Correlations and covariance are estimated from 60 monthly observations; the 2022 correlation estimate uses only 12. Annualization uses conventional square-root-of-time scaling. Neither the proxies nor the single stress window establish actual manager skill or future resilience.

Ellen remains a candidate subject to onboarding. Actual holdings, fees, capacity and implementation costs would be required before a real allocation decision. The analysis does not cover hedge-fund liquidity, leverage, derivatives or counterparty risk. 

## Sources

- https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html
- https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/six_portfolios.html
- https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html
- https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.cov.html
