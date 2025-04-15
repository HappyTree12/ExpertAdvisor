//+------------------------------------------------------------------+
//|                       Strategy 6.mq4                             |
//|                           Kline                                  |
//|                 https://www.mql5.com                             |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// External Parameters for Strategy
extern double Lots = 0.06;          // Lot size for trading
extern double TakeProfit = 2;       // Take Profit in points (direct price change)
extern double StopLoss = 5;         // Stop Loss in points (direct price change)

string StrategyName = "Strategy 6: Hammer"; // Strategy name for logging

// Global Variables
datetime lastTradeTime; // To track the time of the last trade

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print(StrategyName, " Initialized.");
   return(INIT_SUCCEEDED); // Initialization successful
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
   // Check for hammer pattern on the previous candle
   if (IsHammer(1))
   {
      Print(StrategyName, " Hammer detected at bar: ", TimeToString(Time[1], TIME_DATE | TIME_MINUTES));

      // Check for existing positions
      if (HasOpenPositions())
      {
         Print(StrategyName, " Existing position detected. No new order placed.");
         return;
      }

      // Variables for order placement
      double entryPrice, stopLoss, takeProfit;

      // Bullish Hammer: Buy condition
      if (iClose(Symbol(), PERIOD_CURRENT, 1) > iOpen(Symbol(), PERIOD_CURRENT, 1)) // Bullish hammer
      {
         entryPrice = Ask;
         stopLoss = entryPrice - StopLoss;
         takeProfit = entryPrice + TakeProfit;

         PlaceOrder(OP_BUY, entryPrice, stopLoss, takeProfit, "Bullish Hammer");
      }
      // Bearish Hammer: Sell condition
      else
      {
         entryPrice = Bid;
         stopLoss = entryPrice + StopLoss;
         takeProfit = entryPrice - TakeProfit;

         PlaceOrder(OP_SELL, entryPrice, stopLoss, takeProfit, "Bearish Hammer");
      }
   }
}

//+------------------------------------------------------------------+
//| PlaceOrder Function                                              |
//| Handles order placement logic                                    |
//+------------------------------------------------------------------+
bool PlaceOrder(int orderType, double entryPrice, double stopLoss, double takeProfit, string tradeType)
{
   int ticket = OrderSend(Symbol(), orderType, Lots, entryPrice, 0, stopLoss, takeProfit, StrategyName + " " + tradeType, 0, 0, (orderType == OP_BUY ? clrGreen : clrRed));
   if (ticket < 0)
   {
      Print(StrategyName, " Error placing ", (orderType == OP_BUY ? "Buy" : "Sell"), " order: ", GetLastError());
      return false;
   }
   else
   {
      lastTradeTime = TimeCurrent();
      Print(StrategyName, " Order placed: ", tradeType, " | Entry: ", entryPrice, " | TP: ", takeProfit, " | SL: ", stopLoss);
      DrawTradeLevels(tradeType, entryPrice, takeProfit, stopLoss);
      return true;
   }
}

//+------------------------------------------------------------------+
//| HasOpenPositions Function                                        |
//| Checks if any position is open for the symbol                   |
//+------------------------------------------------------------------+
bool HasOpenPositions()
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol())
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| IsHammer Function                                                |
//| Detects a hammer pattern on a specified bar index               |
//+------------------------------------------------------------------+
bool IsHammer(int index)
{
   double openPrice = iOpen(Symbol(), PERIOD_CURRENT, index);
   double closePrice = iClose(Symbol(), PERIOD_CURRENT, index);
   double highPrice = iHigh(Symbol(), PERIOD_CURRENT, index);
   double lowPrice = iLow(Symbol(), PERIOD_CURRENT, index);

   double bodySize = MathAbs(closePrice - openPrice);
   double upperShadow = highPrice - MathMax(openPrice, closePrice);
   double lowerShadow = MathMin(openPrice, closePrice) - lowPrice;

   bool isSmallBody = bodySize <= (highPrice - lowPrice) * 0.3;
   bool hasLongLowerShadow = lowerShadow >= (bodySize * 2);
   bool hasSmallUpperShadow = upperShadow <= (bodySize * 0.2);

   return isSmallBody && hasLongLowerShadow && hasSmallUpperShadow;
}

//+------------------------------------------------------------------+
//| DrawTradeLevels Function                                         |
//| Draws visual trade levels on the chart                          |
//+------------------------------------------------------------------+
void DrawTradeLevels(string tradeType, double entryPrice, double tpPrice, double slPrice)
{
   string prefix = "TP_SL_";
   string entryLineName = prefix + tradeType + "_Entry";
   string tpLineName = prefix + tradeType + "_TakeProfit";
   string slLineName = prefix + tradeType + "_StopLoss";

   ObjectDelete(0, entryLineName);
   ObjectDelete(0, tpLineName);
   ObjectDelete(0, slLineName);

   if (!ObjectCreate(0, entryLineName, OBJ_HLINE, 0, 0, entryPrice))
      Print("Error creating entry line: ", GetLastError());
   else
      ObjectSetInteger(0, entryLineName, OBJPROP_COLOR, clrWhite);

   if (!ObjectCreate(0, tpLineName, OBJ_HLINE, 0, 0, tpPrice))
      Print("Error creating take profit line: ", GetLastError());
   else
      ObjectSetInteger(0, tpLineName, OBJPROP_COLOR, clrGreen);

   if (!ObjectCreate(0, slLineName, OBJ_HLINE, 0, 0, slPrice))
      Print("Error creating stop loss line: ", GetLastError());
   else
      ObjectSetInteger(0, slLineName, OBJPROP_COLOR, clrRed);

   Print(tradeType, " trade levels drawn. Entry: ", entryPrice, ", TP: ", tpPrice, ", SL: ", slPrice);
}
//+------------------------------------------------------------------+