# TikTok MT5 Bot

A standalone MetaTrader 5 Expert Advisor for XAUUSD demo trading.

## V1 scope

- XAUUSD
- Configurable default lot, 0.05
- Rule-based entry signal
- Controlled multi-position/grid expansion
- Basket profit target
- Maximum position count and exposure limits
- Automatic basket close
- Demo-first operation

This repository is intentionally independent from Nova.

## Safety boundary

V1 is for demo testing. No claim of profitability is made. Grid/multi-position logic can amplify losses, so limits are explicit inputs and the EA fails closed when they are exceeded.
