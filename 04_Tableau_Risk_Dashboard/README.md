# Portfolio Risk & Diversification — Tableau

[Open the interactive dashboard](https://public.tableau.com/views/PortfolioRiskDiversification/PortfolioRiskDiversification) · [Download the packaged workbook](Portfolio_Risk_Diversification.twbx)

![Tableau dashboard](../images/tableau_dashboard.png)

## Business question

How do a manager allocation change, return correlations, and historical stress outcomes inform a portfolio risk discussion?

## Views

1. **Drawdown Over Time:** month-end losses relative to previous wealth peaks for Current, Proposed, and the U.S. market.
2. **Manager Correlations:** the full-period pairwise monthly-return correlation matrix.
3. **2022 Stress Comparison:** calendar-year returns, with drawdown, worst-month return, and illustrative dollar losses in tooltips.

## Findings

- Proposed lost 14.57% in 2022 versus 16.54% for Current and 19.92% for the market.
- Full-period maximum drawdown was −20.65% for Proposed versus −21.95% for Current.
- Ellen/Sue had the lowest full-period pairwise correlation, 0.53.
- Lower drawdown did not imply lower volatility: Proposed's annualized volatility was 16.13% versus 15.75% for Current.

## Data and validation

Separate data sources: `drawdowns.csv`, `manager_correlations.csv`, and `stress_2022.csv`, all in `../02_Python_Portfolio_Study/outputs/`. Separate connections prevent duplication from joining different levels of detail. Drawdown begins with a December 2020 baseline; the return study covers January 2021–December 2025.

Dashboard extrema, correlation cells, and 2022 return labels were checked against the Python outputs. Research returns come from the Kenneth French Data Library. Fictional managers and fixed monthly-rebalanced allocations support an educational retrospective study. Monthly data omit intra-month losses, and historical correlations need not persist.
