# V1 Logic Test Specification

These cases define the behavior we must verify in MT5 Strategy Tester before demo deployment.

| Case | Expected result |
|---|---|
| No crossover, no positions | No new position |
| Bullish EMA crossover on closed bar | Open one BUY basket position |
| Bearish EMA crossover on closed bar | Open one SELL basket position |
| Existing BUY basket, price moves favorably | Do not add a grid position |
| Existing BUY basket, price moves adversely by grid step | Add one BUY position, subject to limits |
| Existing SELL basket, price moves favorably | Do not add a grid position |
| Existing SELL basket, price moves adversely by grid step | Add one SELL position, subject to limits |
| Max position count reached | No additional position |
| Max exposure reached | No additional position |
| Basket profit >= target | Close all EA positions |
| Basket loss <= configured loss limit | Close all EA positions |
| Chart symbol is not configured symbol | No trading |
| Mixed-direction EA positions detected | No new entry; basket direction resolves to NONE |

The Strategy Tester is the source of truth for execution behavior. GitHub stores the source and review history; it cannot execute an MT5 terminal itself.
