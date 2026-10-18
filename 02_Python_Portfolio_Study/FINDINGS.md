# Allocation review: large growth to small value

## Decision

Do not describe the Proposed allocation as an unqualified risk reduction. In this retrospective study, shifting ten percentage points from Sue to Ellen reduced the 2022 loss and the full-period maximum drawdown, but increased full-period volatility and slightly reduced annualized return. Continue candidate diligence if the objective is to reduce the large-growth allocation and investigate the observed downside trade-off. The results alone do not establish a superior allocation.

## Evidence

| Measure | Current | Proposed | Proposed minus Current |
|---|---:|---:|---:|
| Annualized return, 2021–2025 | 12.77% | 12.63% | -0.13 percentage points |
| Annualized volatility, 2021–2025 | 15.75% | 16.13% | +0.38 percentage points |
| Maximum drawdown, 2021–2025 | -21.95% | -20.65% | +1.30 percentage points |
| Calendar 2022 return | -16.54% | -14.57% | +1.98 percentage points |
| 2022 P&L on an illustrative USD 100,000 | -$16,544 | -$14,568 | +$1,976 |

Differences are calculated before display rounding. A positive change in maximum drawdown means the loss is shallower. The worst individual month in 2022 was slightly worse under Proposed (-9.21% versus -9.14%), so the improved calendar-year return does not imply improvement in every downside measure.

Sue's allocation falls from 40% to 30%, bringing it below the illustrative 35% allocation limit used in the SQL project. This is a policy-concentration improvement, separate from the observed increase in overall volatility.

## Diversification interpretation

Ellen and Sue had a full-sample return correlation of approximately 0.53, rising to approximately 0.80 in 2022. Their different styles therefore did not provide stable independence during the selected stress period. The short 2022 sample has only twelve observations.

The risk-contribution chart separates capital weights from contributions to volatility. Spreading capital across more managers does not automatically reduce total portfolio volatility. A strategy's own volatility and its covariance with the whole portfolio both matter.

## Further diligence

- Determine whether Ellen's actual strategy exposures would resemble the small-value research proxy.
- Review overlap in holdings, fees, capacity, implementation costs and the unfinished onboarding review.
- Test additional market regimes and genuinely held-out periods before treating this historical comparison as evidence for a future allocation.

## Scope and validation

This is a hypothetical monthly-rebalanced equity portfolio using research returns from the August 2026 CRSP vintage. It is not a real manager track record or a point-in-time strategy test. No additional costs are modelled. Monthly drawdowns miss intra-month lows, and the study does not assess hedge-fund liquidity, leverage or derivative risks.

The notebook completed all eleven code cells. Input coverage and weight checks passed. Independent calculations confirmed compounded returns, annualized volatility, drawdown, the 2022 replay and risk-contribution reconciliation. A separate first-month-loss example confirmed that the initial wealth baseline is included correctly. All three exported charts were visually reviewed.
