# TikTok MT5 Bot

A standalone MetaTrader 5 Expert Advisor for XAUUSD demo trading.

## V1 scope

- XAUUSD
- Configurable base lot, default `0.05`
- Closed-candle EMA crossover entry
- Controlled multi-position/adverse grid expansion
- Basket profit target
- Basket loss limit
- Maximum position count and total exposure limits
- Optional spread filter
- Automatic basket close
- Hedging-account requirement
- Demo-first operation

## Current behavior

1. When no basket exists, the EA waits for a fresh bar.
2. A 9/21 EMA crossover on completed candles creates the first BUY or SELL position.
3. Once a basket exists, additional positions use the same direction only.
4. A grid addition is allowed only after price moves against the most recently opened position by `InpGridStepPrice`.
5. The basket closes when profit reaches `InpBasketProfitMoney` or loss reaches `InpBasketLossMoney`.
6. Position count and total exposure are hard limits.
7. The EA requires an MT5 hedging account because V1 intentionally supports multiple simultaneous positions on XAUUSD.

## Default V1 limits

| Input | Default |
|---|---:|
| Base lot | 0.05 |
| Max positions | 5 |
| Max exposure | 0.25 lots |
| Grid step | 3.0 XAU price units |
| Basket profit | 5.00 account-currency units |
| Basket loss | 25.00 account-currency units |
| Fast EMA | 9 |
| Slow EMA | 21 |

These are implementation defaults, not claims that the settings are profitable or optimal.

## Safety boundary

V1 is for demo testing. No claim of profitability is made. Grid/multi-position logic can amplify losses, so limits are explicit inputs and the EA fails closed when configuration or account requirements are not met.

This repository is intentionally independent from Nova.

## Validation status

Source-level review is performed in GitHub. Actual MQL5 compilation and Strategy Tester execution require MetaTrader 5 and therefore must be performed in an MT5 environment.
