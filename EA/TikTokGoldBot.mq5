#property strict
#property version   "0.1.0"
#property description "Standalone XAUUSD demo EA: bounded grid, basket target and risk limits."

#include <Trade/Trade.mqh>

CTrade trade;

input string InpSymbol = "XAUUSD";
input double InpBaseLot = 0.05;
input ulong  InpMagic = 26083001;
input int    InpMaxPositions = 5;
input double InpMaxExposureLots = 0.25;
input double InpGridStepPrice = 3.0;
input double InpBasketProfitMoney = 5.0;
input int    InpFastMAPeriod = 9;
input int    InpSlowMAPeriod = 21;
input int    InpDeviationPoints = 30;

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
             + PositionGetDouble(POSITION_SWAP)
             + PositionGetDouble(POSITION_COMMISSION);
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
     }
   return ok;
  }

bool ReadSignal(BasketDirection &signal)
  {
   signal = BASKET_NONE;
   double fast[2], slow[2];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   if(CopyBuffer(fast_ma_handle, 0, 0, 2, fast) != 2)
      return false;
   if(CopyBuffer(slow_ma_handle, 0, 0, 2, slow) != 2)
      return false;

   if(fast[1] <= slow[1] && fast[0] > slow[0])
      signal = BASKET_BUY;
   else if(fast[1] >= slow[1] && fast[0] < slow[0])
      signal = BASKET_SELL;

   return true;
  }

bool LastEntryFarEnough(BasketDirection direction)
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

   double market_price = (direction == BASKET_BUY)
                       ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                       : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   return (MathAbs(market_price - last_price) >= InpGridStepPrice);
  }

bool OpenPosition(BasketDirection direction)
  {
   if(direction == BASKET_NONE)
      return false;
   if(CountPositions(BASKET_NONE) >= InpMaxPositions)
      return false;
   if(ExposureLots() + InpBaseLot > InpMaxExposureLots + 1e-9)
      return false;
   if(!LastEntryFarEnough(direction))
      return false;

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);

   bool result = false;
   if(direction == BASKET_BUY)
      result = trade.Buy(InpBaseLot, _Symbol, 0.0, 0.0, 0.0, "TikTokGoldBot");
   else
      result = trade.Sell(InpBaseLot, _Symbol, 0.0, 0.0, 0.0, "TikTokGoldBot");

   if(!result)
      PrintFormat("Entry failed: %s", trade.ResultRetcodeDescription());
   return result;
  }

int OnInit()
  {
   if(InpBaseLot <= 0.0 || InpMaxPositions < 1 || InpMaxExposureLots < InpBaseLot ||
      InpGridStepPrice <= 0.0 || InpBasketProfitMoney <= 0.0 ||
      InpFastMAPeriod < 1 || InpSlowMAPeriod <= InpFastMAPeriod)
      return INIT_PARAMETERS_INCORRECT;

   if(!SymbolSelect(InpSymbol, true))
     {
      Print("Unable to select configured symbol: ", InpSymbol);
      return INIT_FAILED;
     }

   if(_Symbol != InpSymbol)
      PrintFormat("Attach this EA to %s. Current chart: %s", InpSymbol, _Symbol);

   fast_ma_handle = iMA(_Symbol, PERIOD_CURRENT, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slow_ma_handle = iMA(_Symbol, PERIOD_CURRENT, InpSlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(fast_ma_handle == INVALID_HANDLE || slow_ma_handle == INVALID_HANDLE)
      return INIT_FAILED;

   trade.SetExpertMagicNumber(InpMagic);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(fast_ma_handle != INVALID_HANDLE) IndicatorRelease(fast_ma_handle);
   if(slow_ma_handle != INVALID_HANDLE) IndicatorRelease(slow_ma_handle);
  }

void OnTick()
  {
   if(!IsTargetSymbol())
      return;

   if(CountPositions(BASKET_NONE) > 0 && BasketProfit() >= InpBasketProfitMoney)
     {
      CloseBasket();
      return;
     }

   if(!IsNewBar())
      return;

   BasketDirection signal;
   if(!ReadSignal(signal))
      return;

   BasketDirection basket = GetBasketDirection();

   if(basket == BASKET_NONE)
     {
      OpenPosition(signal);
      return;
     }

   // V1 only adds to an existing basket in the same direction.
   if(signal == basket)
      OpenPosition(basket);
  }
