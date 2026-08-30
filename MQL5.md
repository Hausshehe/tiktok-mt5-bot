# MT5 implementation notes

The V1 EA uses the standard MQL5 `CTrade` class for market orders and position closing. Multiple simultaneous positions on the same symbol require a hedging-style MT5 account; on netting accounts, MT5 represents a symbol with a single position.

The basket target is evaluated from current position profit plus swap. Execution success must still be checked through the trade result in the terminal because a successful `CTrade` method call only confirms the request passed local checks.

Reference: MQL5 documentation for `CTrade::PositionClose`, `CTrade::Buy`, `PositionGetDouble`, and position accounting modes.
