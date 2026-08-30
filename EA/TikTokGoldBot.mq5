#property strict
#property version   "0.1.2"
#property description "Standalone XAUUSD demo EA: bounded adverse-move grid, basket target and risk limits."

#include <Trade/Trade.mqh>

CTrade trade;

input string InpSymbol = "XAUUSD";
input double InpBaseLot = 0.05;
input ulong  InpMagic = 26083001;
input int    InpMaxPositions = 5;
input double InpMaxExposureLots = 0.25;
input double InpGridStepPrice = 3.0;
input double InpBasketProfitMoney = 5.0;
input double InpBasketLossMoney = 25.0;
input int    InpFastMAPeriod = 9;
input int    InpSlowMAPeriod = 21;
input int    InpDeviationPoints = 30;
input int    InpMaxSpreadPoints = 100;

int fast_ma_handle = INVALID_HANDLE;
int slow_ma_handle = INVALID_HANDLE;
datetime last_bar_time = 0;

enum BasketDirection
  {
   BASKET_NONE = 0,
   BASKET_BUY  = 1,
   BASKET_SELL = -1
  };

bool IsTargetSymbol()
  {
   return (_Symbol == InpSymbol);
  }

bool IsNewBar()
  {
   datetime times[1];
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, 1, times) != 1)
      return false;
   if(times[0] == last_bar_time)
      return false;
   last_bar_time = times[0];
   return true;
  }

int CountPositions(BasketDirection direction)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(direction == BASKET_NONE ||
         (direction == BASKET_BUY && type == POSITION_TYPE_BUY) ||
         (direction == BASKET_SELL && type == POSITION_TYPE_SELL))
         count++;
     }
   return count;
  }

double ExposureLots()
  {
   double lots = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      lots += PositionGetDouble(POSITION_VOLUME);
     }
   return lots;
  }

double BasketProfit()
  {
   double profit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      profit += PositionGetDouble(POSITION_PROFIT)
             + PositionGetDouble(POSITION_SWAP);
     }
   return profit;
  }

BasketDirection GetBasketDirection()
  {
   bool buy = false;
   bool sell = false;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      buy |= (type == POSITION_TYPE_BUY);
      sell |= (type == POSITION_TYPE_SELL);
     }

   if(buy && !sell) return BASKET_BUY;
   if(sell && !buy) return BASKET_SELL;
   return BASKET_NONE;
  }

bool SpreadAllowed()
  {
   if(InpMaxSpreadPoints <= 0)
      return true;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(point <= 0.0 || ask <= 0.0 || bid <= 0.0)
      return false;

   return ((ask - bid) / point <= InpMaxSpreadPoints);
  }

bool CloseBasket()
  {
   bool ok = true;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      if(!trade.PositionClose(ticket))
        {
         PrintFormat("Close failed for ticket %I64u: %s", ticket, trade.ResultRetcodeDescription());
         ok = false;
        }
      else if(trade.ResultRetcode() != TRADE_RETCODE_DONE &&
              trade.ResultRetcode() != TRADE_RETCODE_DONE_PARTIAL)
        {
         PrintFormat("Close rejected for ticket %I64u: %s", ticket, trade.ResultRetcodeDescription());
         ok = false;
        }
     }
   return ok;
  }

bool ReadSignal(BasketDirection &signal)
  {
   signal = BASKET_NONE;

   // Completed candles only: shift 1 and shift 2.
   double fast[2], slow[2];
   if(CopyBuffer(fast_ma_handle, 0, 1, 2, fast) != 2)
      return false;
   if(CopyBuffer(slow_ma_handle, 0, 1, 2, slow) != 2)
      return false;

   // CopyBuffer places the older requested value first: [0]=shift 2, [1]=shift 1.
   if(fast[0] <= slow[0] && fast[1] > slow[1])
      signal = BASKET_BUY;
   else if(fast[0] >= slow[0] && fast[1] < slow[1])
      signal = BASKET_SELL;

   return true;
  }

bool AdverseGridDistanceReached(BasketDirection direction)
  {
   double last_price = 0.0;
   datetime latest = 0;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((direction == BASKET_BUY && type != POSITION_TYPE_BUY) ||
         (direction == BASKET_SELL && type != POSITION_TYPE_SELL))
         continue;

      datetime opened = (datetime)PositionGetInteger(POSITION_TIME);
      if(opened >= latest)
        {
         latest = opened;
         last_price = PositionGetDouble(POSITION_PRICE_OPEN);
        }
     }

   if(latest == 0)
      return true;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return false;

   if(direction == BASKET_BUY)
      return bid <= last_price - InpGridStepPrice;
   if(direction == BASKET_SELL)
      return ask >= last_price + InpGridStepPrice;

   return false;
  }

double NormalizeVolume(double requested)
  {
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(min_lot <= 0.0 || max_lot <= 0.0 || step <= 0.0)
      return 0.0;
   if(requested < min_lot || requested > max_lot)
      return 0.0;

   double volume = MathFloor((requested + 1e-12) / step) * step;
   if(volume < min_lot || volume > max_lot)
      return 0.0;
   return volume;
  }

bool OpenPosition(BasketDirection direction)
  {
   if(direction == BASKET_NONE)
      return false;
   if(!SpreadAllowed())
      return false;
   if(CountPositions(BASKET_NONE) >= InpMaxPositions)
      return false;

   double volume = NormalizeVolume(InpBaseLot);
   if(volume <= 0.0)
     {
      Print("Configured lot is incompatible with symbol volume limits/step.");
      return false;
     }
   if(ExposureLots() + volume > InpMaxExposureLots + 1e-9)
      return false;
   if(!AdverseGridDistanceReached(direction))
      return false;

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   bool result = false;
   if(direction == BASKET_BUY)
      result = trade.Buy(volume, _Symbol, 0.0, 0.0, 0.0, "TikTokGoldBot");
   else
      result = trade.Sell(volume, _Symbol, 0.0, 0.0, 0.0, "TikTokGoldBot");

   if(!result ||
      (trade.ResultRetcode() != TRADE_RETCODE_DONE &&
       trade.ResultRetcode() != TRADE_RETCODE_DONE_PARTIAL &&
       trade.ResultRetcode() != TRADE_RETCODE_PLACED))
     {
      PrintFormat("Entry failed/rejected: %s", trade.ResultRetcodeDescription());
      return false;
     }

   return true;
  }

int OnInit()
  {
   if(InpBaseLot <= 0.0 || InpMaxPositions < 1 || InpMaxExposureLots < InpBaseLot ||
      InpGridStepPrice <= 0.0 || InpBasketProfitMoney <= 0.0 || InpBasketLossMoney <= 0.0 ||
      InpFastMAPeriod < 1 || InpSlowMAPeriod <= InpFastMAPeriod ||
      InpDeviationPoints < 0 || InpMaxSpreadPoints < 0)
      return INIT_PARAMETERS_INCORRECT;

   if(!SymbolSelect(InpSymbol, true))
     {
      Print("Unable to select configured symbol: ", InpSymbol);
      return INIT_FAILED;
     }

   if(_Symbol != InpSymbol)
     {
      PrintFormat("Attach this EA to %s. Current chart: %s", InpSymbol, _Symbol);
      return INIT_FAILED;
     }

   long margin_mode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(margin_mode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print("TikTokGoldBot V1 requires a hedging MT5 account because the grid uses multiple positions.");
      return INIT_FAILED;
     }

   fast_ma_handle = iMA(_Symbol, PERIOD_CURRENT, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slow_ma_handle = iMA(_Symbol, PERIOD_CURRENT, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(fast_ma_handle == INVALID_HANDLE || slow_ma_handle == INVALID_HANDLE)
      return INIT_FAILED;

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(fast_ma_handle != INVALID_HANDLE)
      IndicatorRelease(fast_ma_handle);
   if(slow_ma_handle != INVALID_HANDLE)
      IndicatorRelease(slow_ma_handle);
  }

void OnTick()
  {
   if(!IsTargetSymbol())
      return;

   int positions = CountPositions(BASKET_NONE);
   if(positions > 0)
     {
      double basket_profit = BasketProfit();
      if(basket_profit >= InpBasketProfitMoney || basket_profit <= -InpBasketLossMoney)
        {
         CloseBasket();
         return;
        }

      // Grid management is tick-driven. Add only after an adverse move.
      BasketDirection basket = GetBasketDirection();
      if(basket != BASKET_NONE)
         OpenPosition(basket);
      return;
     }

   // New baskets are opened only on a new bar and a completed-candle EMA cross.
   if(!IsNewBar() || !SpreadAllowed())
      return;

   BasketDirection signal;
   if(!ReadSignal(signal) || signal == BASKET_NONE)
      return;

   OpenPosition(signal);
  }
