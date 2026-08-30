# V1 Verification Plan

## GitHub-side checks

- Confirm required source files exist.
- Review entry, grid, basket-profit, basket-loss, and exposure guards.
- Check that no Nova/research-framework dependency exists.

## MT5-side checks

GitHub cannot compile or execute an MT5 terminal. The actual Expert Advisor must be compiled and exercised in MetaTrader 5 Strategy Tester.

The first phone-side test should be compile-only. After compilation succeeds, run a short Strategy Tester pass and inspect the Experts/Journal logs and trade list against `tests/LOGIC_SPEC.md`.
