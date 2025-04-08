//+------------------------------------------------------------------+
//|                       Strategy 7.mq4                             |
//|                           Kline                                  |
//|                 https://www.mql5.com                             |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// External Parameters for Strategy
//Replace TrailingStoploss with TakePeofit 
//extern double TakeProfit = 3;       // Take profit in whole numbers 
extern double Lots = 0.07;           // Lot size for trading
extern double StopLoss = 5.0;        // Stop loss in whole numbers
extern double TrailingStepUSD = 3.0; // Trailing step in USD

string StrategyName = "Strategy 7: Engulfing"; // Strategy name for logging
datetime LastTradeTime; // Track the last trade to avoid rapid re-entry

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
   
   // Update trailing stop-loss
   UpdateTrailingStopLoss();
   
   // Check for existing positions
   if (HasOpenPositions())
   {
      Print(StrategyName, " Existing position detected. No new trades placed.");
      return;
   }

   // Fetch candlestick data
   double openCurrent = iOpen(Symbol(), PERIOD_CURRENT, 1);
   double closeCurrent = iClose(Symbol(), PERIOD_CURRENT, 1);
   double openPrevious = iOpen(Symbol(), PERIOD_CURRENT, 2);
   double closePrevious = iClose(Symbol(), PERIOD_CURRENT, 2);

   // Variables for trade details
   double entryPrice, tpPrice, slPrice;

   // Bullish Engulfing Pattern Detection
   if (closeCurrent > openCurrent &&            // Current candle is bullish
       closePrevious < openPrevious &&          // Previous candle is bearish
       closeCurrent > openPrevious &&           // Current close engulfs previous open
       openCurrent < closePrevious)             // Current open engulfs previous close
   {
      Print(StrategyName, " Bullish engulfing detected.");
      entryPrice = Ask;
      
      //Replace Trailing StopLoss with TP
      //tpPrice = entryPrice + TakeProfit;
      slPrice = entryPrice - StopLoss;

      if (PlaceOrder(OP_BUY, entryPrice, tpPrice, slPrice, "Bullish Engulfing"))
      {
         DrawTradeLevels("Bullish", entryPrice, tpPrice, slPrice);
      }
   }

   // Bearish Engulfing Pattern Detection
   if (closeCurrent < openCurrent &&            // Current candle is bearish
       closePrevious > openPrevious &&          // Previous candle is bullish
       closeCurrent < openPrevious &&           // Current close engulfs previous open
       openCurrent > closePrevious)             // Current open engulfs previous close
   {
      Print(StrategyName, " Bearish engulfing detected.");
      entryPrice = Bid;
      //Replace TrailingStopLoss with TakeProfit
      //tpPrice = entryPrice - TakeProfit;
      slPrice = entryPrice + StopLoss;

      if (PlaceOrder(OP_SELL, entryPrice, tpPrice, slPrice, "Bearish Engulfing"))
      {
         DrawTradeLevels("Bearish", entryPrice, tpPrice, slPrice);
      }
   }
}

//+------------------------------------------------------------------+
//| PlaceOrder Function                                              |
//| Handles order placement logic                                    |
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
      LastTradeTime = TimeCurrent();
      Print(StrategyName, " ", tradeType, " order placed. Entry: ", entryPrice, ", TP: ", tpPrice, ", SL: ", slPrice);
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
      if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol())
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| UpdateTrailingStopLoss Function                                  |
//+------------------------------------------------------------------+
void UpdateTrailingStopLoss()
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS) &&
          OrderSymbol() == Symbol() &&
          (OrderType() == OP_BUY || OrderType() == OP_SELL))
      {
         double entryPrice = OrderOpenPrice();
         double currentSL = OrderStopLoss();
         double marketPrice = (OrderType() == OP_BUY) ? Bid : Ask;
         double profitThreshold = TrailingStepUSD / MarketInfo(Symbol(), MODE_TICKVALUE);

         if (OrderType() == OP_BUY)
         {
            double newSL = entryPrice + profitThreshold;
            if (marketPrice - entryPrice >= profitThreshold && newSL > currentSL)
            {
               if (OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrGreen))
                  Print("Trailing Stop Updated for Buy Order | New SL: ", newSL);
            }
         }
         else if (OrderType() == OP_SELL)
         {
            double newSL = entryPrice - profitThreshold;
            if (entryPrice - marketPrice >= profitThreshold && newSL < currentSL)
            {
               if (OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrRed))
                  Print("Trailing Stop Updated for Sell Order | New SL: ", newSL);
            }
         }
      }
   }
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
      ObjectSetInteger(0, entryLineName, OBJPROP_COLOR, clrBlue);

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