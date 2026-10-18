# Manager Portfolio Review — Power BI

## Business question

How can an advisor explain the performance and allocation implications of a proposed manager change?

[Download the Power BI workbook](Manager_Portfolio_Review.pbix).

## Report features

- Current/Proposed single-select scenario control.
- Annualized portfolio and benchmark returns, annualized volatility, and maximum drawdown.
- Compounded portfolio and market performance on a shared axis.
- Manager allocations with an illustrative 35% policy limit.
- Scenario-specific commentary describing the full 2021–2025 study.

## Model and sources

`PortfolioReturns` is prepared by unpivoting Current and Proposed in `../02_Python_Portfolio_Study/outputs/monthly_portfolio_returns.csv`, retaining the benchmark. Allocations and Managers come from `../data/`. A Scenarios dimension filters PortfolioReturns and Allocations; Managers filters Allocations. Relationships are single-direction, one-to-many.

## Validation and interpretation

Displayed cards and allocations were checked against Python outputs for both scenarios. Current annualized return is 12.77%, volatility 15.75%, and maximum drawdown −21.95%; Proposed values are 12.63%, 16.13%, and −20.65%. The benchmark annualized return is 13.05%.

The proposed allocation reduces Sue from 40% to 30% and adds Ellen at 10%. All six proposed allocations meet the illustrative 35% limit.

## Open and refresh

Open the PBIX file in Power BI Desktop. The workbook retains the original author's source paths; update the file sources in Power Query to the corresponding repository files before refreshing. Keep the existing query transformations and column names. The embedded imported data allow inspection before refreshing.

Commentary uses fixed full-period figures; it is not designed for arbitrary date filters. Returns are research proxies, and names and policy limits are fictional. This is a retrospective allocation comparison.
