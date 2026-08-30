#!/usr/bin/env bash
set -euo pipefail

test -f EA/TikTokGoldBot.mq5
grep -q 'input double InpBaseLot = 0.05;' EA/TikTokGoldBot.mq5
grep -q 'InpMaxPositions' EA/TikTokGoldBot.mq5
grep -q 'InpMaxExposureLots' EA/TikTokGoldBot.mq5
grep -q 'InpBasketProfitMoney' EA/TikTokGoldBot.mq5
grep -q 'InpBasketLossMoney' EA/TikTokGoldBot.mq5
grep -q 'BASKET_BUY' EA/TikTokGoldBot.mq5
grep -q 'BASKET_SELL' EA/TikTokGoldBot.mq5

echo 'Static V1 smoke checks passed.'
