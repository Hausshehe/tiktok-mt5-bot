# V1 Status

Current milestone: EA source ready for MT5 compilation and behavioral testing.

Implemented in GitHub:
- Standalone XAUUSD EA source
- 0.05 default lot input
- Closed-candle 9/21 EMA crossover entry
- Bounded multi-position logic
- Adverse-only grid expansion
- Basket profit target
- Basket loss guard
- Maximum positions
- Maximum total lot exposure
- Spread filter
- Automatic basket close
- Hedging-account requirement
- Source smoke checks and CI

Current default risk envelope:
- 0.05 lots per position
- 5 positions maximum
- 0.25 lots total exposure maximum
- 3.0 XAU price-unit grid spacing
- 5.00 account-currency basket profit target
- 25.00 account-currency basket loss limit

Validation boundary:
- GitHub source review: performed.
- GitHub static smoke checks: configured.
- MQL5 compilation: not yet physically verified.
- MT5 Strategy Tester behavior: not yet physically verified.
- Demo forward test: not yet started.
- Live trading: prohibited for V1.

Next physical step: compile `EA/TikTokGoldBot.mq5` in MetaTrader 5, then run the behavioral cases in `tests/LOGIC_SPEC.md` on a demo account/tester.
