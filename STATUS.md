# V1 Status

Current milestone: initial EA implementation.

Implemented in GitHub:
- Standalone XAUUSD EA source
- 0.05 default lot input
- EMA-based entry signal
- Bounded multi-position logic
- Basket profit target
- Basket loss guard
- Maximum positions
- Maximum lot exposure
- Automatic basket close
- Adverse-only grid expansion intended for hedging accounts
- Source smoke checks and CI

Next physical step: compile the EA in MetaTrader 5 and run the behavioral cases in `tests/LOGIC_SPEC.md`.

Do not deploy to live money.
