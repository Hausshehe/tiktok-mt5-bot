# Expert Advisor

`TikTokGoldBot.mq5` is the initial V1 Expert Advisor.

## V1 behavior

1. A fast/slow EMA crossover on a closed candle starts a basket.
2. Additional positions are opened only in the basket direction and only when price moves adversely by the configured grid distance from the most recent entry.
3. The basket closes automatically when its configured profit target is reached.
4. A maximum position count and maximum total lot exposure cap further entries.
5. A maximum basket loss can force an early close.
6. The EA only operates when attached to the configured XAUUSD symbol.

The EA is intended for demo testing first. It does not claim profitability and does not remove market risk.
