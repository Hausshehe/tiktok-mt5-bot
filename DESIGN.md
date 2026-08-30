# V1 Design Rules

The bot is intentionally small.

- One symbol: XAUUSD.
- One basket direction at a time.
- Entry starts from a closed-candle EMA crossover.
- Grid additions must be adverse-only, never favorable chasing.
- Each additional order uses the same base lot in V1.
- Exposure is bounded by both count and total lots.
- Profit and loss basket thresholds are checked on every tick.
- V1 does not reverse an active basket.
- V1 does not depend on Nova, LLMs, external APIs, or the previous Nova codebase.
- Live-money deployment is out of scope until demo behavior is verified.
