//+------------------------------------------------------------------+
//|                                                   Double_RSI.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

string StrategyName = "Double RSI"; // Strategy name for logging

extern double Lots = 0.1;           // Lot size for trading
extern double AverageTrueRange = 14;
extern int RSILong_TimeFrame = 60;
extern int RSIShort_TimeFrame = PERIOD_CURRENT;
extern int LongThreshold = 20;
extern int ShortThreshold = -20;
extern int CooldownMinutes = 5;      // Cooldown period in minutes

datetime LastTradeTime; // Track the last trade to avoid rapid re-entry

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(StrategyName, " Initialized.");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(StrategyName, " Deinitialized. Reason: ", reason);
   ObjectsDeleteAll(0, "TP_SL_"); // Remove all trade level objects
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check if cooldown period has passed
   if (TimeCurrent() - LastTradeTime < CooldownMinutes * 60)
     {
      Print(StrategyName, " Cooldown active. Time remaining: ", (CooldownMinutes * 60) - (TimeCurrent() - LastTradeTime), " seconds.");
      return; // Exit without placing new trades
     }

   double atrValue = iATR(Symbol(), PERIOD_CURRENT, AverageTrueRange, 0);
   double roundedATR = RoundDownTo2Digits(atrValue);

   if (HasOpenPositions())
     {
      Print(StrategyName, " Existing position detected. No new trades placed.");
      return;
     }

   // Get the RSI values
   double entryPrice, tpPrice, slPrice;
   double LongTermRSI = iRSI(Symbol(), RSILong_TimeFrame, 14, PRICE_CLOSE, 0); // Fast RSI
   Print("Long Term RSI = ", LongTermRSI);

   double ShortTermRSI = iRSI(Symbol(), RSIShort_TimeFrame, 14, PRICE_CLOSE, 0); // Slow RSI
   Print("Short Term RSI = ", ShortTermRSI);
   double finalRSI = LongTermRSI - ShortTermRSI;
   Print("Current RSI = ", finalRSI);

   // Check for Buy or Sell conditions based on finalRSI value
   if (finalRSI >= LongThreshold)
     {
      entryPrice = Bid;
      slPrice = entryPrice + atrValue * 0.5; // 1.5x ATR Stop Loss
      tpPrice = entryPrice - atrValue * 1.0; // 2.0x ATR Take Profit
      PlaceOrder(OP_SELL, entryPrice, tpPrice, slPrice, "Bearish Engulfing");
     }
   else if (finalRSI <= ShortThreshold)
     {
      entryPrice = Ask;
      slPrice = entryPrice - atrValue * 0.5; // 1.5x ATR Stop Loss
      tpPrice = entryPrice + atrValue * 1.0; // 2.0x ATR Take Profit
      PlaceOrder(OP_BUY, entryPrice, tpPrice, slPrice, "Bullish Engulfing");
     }
  }

//+------------------------------------------------------------------+
double RoundDownTo2Digits(double value)
  {
   return MathFloor(value * 100) / 100.0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Function to check if there are open positions                    |
//+------------------------------------------------------------------+
bool HasOpenPositions()
  {
   for (int i = 0; i < OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol())
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Function to place a new order                                     |
//+------------------------------------------------------------------+
bool PlaceOrder(int orderType, double entryPrice, double tpPrice, double slPrice, string tradeType)
  {
   int ticket = OrderSend(Symbol(), orderType, Lots, entryPrice, 3, slPrice, tpPrice, StrategyName + " " + tradeType, 0, 0, (orderType == OP_BUY ? clrGreen : clrRed));
   if (ticket < 0)
     {
      Print(StrategyName, " Error placing ", (orderType == OP_BUY ? "Buy" : "Sell"), " order: ", GetLastError());
      return false;
     }
   else
     {
      LastTradeTime = TimeCurrent(); // Update the LastTradeTime after placing the order
      Print(StrategyName, " ", tradeType, " order placed. Entry: ", entryPrice, ", TP: ", tpPrice, ", SL: ", slPrice);
      return true;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+