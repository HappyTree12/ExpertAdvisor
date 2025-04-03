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
//extern double TrailingStepUSD = 3.0; // Trailing step in USD
extern double TakeProfit = 5.0;
extern double AverageTrueRange = 14;

// Trading Mode: 0 = Hedging (Both Long and Short), 1 = Long Only, 2 = Short Only
extern int TradingMode = 0;

string StrategyName = "Engulfing"; // Strategy name for logging
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

   double atrValue = iATR(Symbol(), PERIOD_CURRENT, AverageTrueRange, 0);
   double roundedATR = RoundDownTo2Digits(atrValue);

   //Print("Original ATR: ", atrValue, " | Rounded Down ATR: ", roundedATR);
   if(TradingMode == 1 || TradingMode  == 2)
     {
      Print(StrategyName, " Single Mode is Running ");
     }

   else
      if(TradingMode == 0)
        {
         Print(StrategyName, " Hedge Mode is Running ");

        }
// Update trailing stop-loss
//Replace with using fix tp
//  UpdateTrailingStopLoss();

// Check for existing positions
   if(HasOpenPositions())
     {
      Print(StrategyName, " Existing position detected. No new trades placed.");
      return;
     }

// Fetch candlestick data
   double openCurrent = iOpen(Symbol(),PERIOD_CURRENT,1);
//Print(openCurrent);
   double closeCurrent = iClose(Symbol(), PERIOD_CURRENT, 1);
//Print(closeCurrent);
   double highCurrent = iHigh(Symbol(), PERIOD_CURRENT, 1);
//Print("iHigh:" ,highCurrent);
   double lowCurrent = iLow(Symbol(), PERIOD_CURRENT, 1);
//Print("iLow :" ,lowCurrent);

   double openPrevious = iOpen(Symbol(), PERIOD_CURRENT, 2);
//Print(openPrevious);
   double closePrevious = iClose(Symbol(), PERIOD_CURRENT, 2);
//Print(closePrevious);
   double highPrevious = iHigh(Symbol(), PERIOD_CURRENT, 2);
//Print(highCurrent);
   double lowPrevious = iLow(Symbol(),PERIOD_CURRENT, 2);
//Print(lowCurrent)
 //  double rsiValue = iRSI(Symbol(),4, RSIPeriod, PRICE_CLOSE, 0);


// Variables for trade details
   double entryPrice, tpPrice, slPrice;

// Bullish Engulfing Pattern Detection

   if((TradingMode == 0 || TradingMode == 1))
     {
         if(closePrevious < openPrevious)  // Previous candle is bearish
           {
            Print("Previous candle is bearish.");

            if(closeCurrent > openCurrent)  // Current candle is bullish
              {
               Print("Current candle is bullish.");

               if(lowCurrent < lowPrevious && highCurrent > highPrevious)  // Engulfing range
                 {
                  Print("Current candle engulfs the previous candle.");

                  if(openCurrent < closePrevious && closeCurrent > openPrevious)  // Open/Close relationships
                    {
                     Print("Bullish Engulfing Pattern detected!");

                     // Logic to place a buy trade
                     entryPrice = Ask;
                     //slPrice = entryPrice - StopLoss;  // Set Stop Loss below entry price
                     //tpPrice = entryPrice + TakeProfit; // Set Take Profit above entry price

                     double slPrice = (entryPrice - atrValue * 0.5); // 1.5x ATR Stop Loss
                     double tpPrice = (entryPrice + atrValue * 1.0); // 2.0x ATR Take Profit

                     if(PlaceOrder(OP_BUY, entryPrice, tpPrice, slPrice, "Bullish Engulfing"))
                       {
                        DrawTradeLevels("Bullish", entryPrice, tpPrice, slPrice);
                       }
                    }
                 }
             
           }
        }
     }

// Bearish Engulfing Pattern Detection (Using Highs, Lows, Open, and Close)
// Bearish Engulfing Pattern Detection

   if((TradingMode == 0 || TradingMode == 2))
     {
         if(closePrevious > openPrevious)  // Previous candle is bullish
           {
            Print("Previous candle is bullish.");

            if(closeCurrent < openCurrent)  // Current candle is bearish
              {
               Print("Current candle is bearish.");

               if(lowCurrent < lowPrevious && highCurrent > highPrevious)  // Engulfing range
                 {
                  Print("Current candle engulfs the previous candle.");

                  if(openCurrent > closePrevious && closeCurrent < openPrevious)  // Open/Close relationships
                    {
                     Print("Bearish Engulfing Pattern detected!");

                     // Logic to place a sell trade
                     entryPrice = Bid;
                     //slPrice = entryPrice + StopLoss;  // Set Stop Loss above entry price
                     //tpPrice = entryPrice - TakeProfit; // Set Take Profit below entry price
                     double slPrice = (entryPrice + atrValue * 0.5); // 1.5x ATR Stop Loss
                     double tpPrice = (entryPrice - atrValue * 1.0); // 2.0x ATR Take Profit


                     if(PlaceOrder(OP_SELL, entryPrice, tpPrice, slPrice, "Bearish Engulfing"))
                       {
                        DrawTradeLevels("Bearish", entryPrice, tpPrice, slPrice);
                       }
                    }
                 }
              }
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
   if(ticket < 0)
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
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol())
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| UpdateTrailingStopLoss Function                                  |
//+------------------------------------------------------------------+
//void UpdateTrailingStopLoss()
//  {
//   for(int i = 0; i < OrdersTotal(); i++)
//     {
//      if(OrderSelect(i, SELECT_BY_POS) &&
//         OrderSymbol() == Symbol() &&
//        (OrderType() == OP_BUY || OrderType() == OP_SELL))
//       {
//        double entryPrice = OrderOpenPrice();
//         double currentSL = OrderStopLoss();
//       double marketPrice = (OrderType() == OP_BUY) ? Bid : Ask;
//         double profitThreshold = TrailingStepUSD / MarketInfo(Symbol(), MODE_TICKVALUE);
//
//        if(OrderType() == OP_BUY)
//           {
//            double newSL = entryPrice + profitThreshold;
//            if(marketPrice - entryPrice >= profitThreshold && newSL > currentSL)
//              {
//               if(OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrGreen))
//                  Print("Trailing Stop Updated for Buy Order | New SL: ", newSL);
//              }
//           }
//         else
//            if(OrderType() == OP_SELL)
//             {
//              double newSL = entryPrice - profitThreshold;
//               if(entryPrice - marketPrice >= profitThreshold && newSL < currentSL)
////                {
//                 if(OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrRed))
//                    Print("Trailing Stop Updated for Sell Order | New SL: ", newSL);
//                }
//             }
//       }
//    }
// }


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

   if(!ObjectCreate(0, entryLineName, OBJ_HLINE, 0, 0, entryPrice))
      Print("Error creating entry line: ", GetLastError());
   else
      ObjectSetInteger(0, entryLineName, OBJPROP_COLOR, clrBlue);

   if(!ObjectCreate(0, tpLineName, OBJ_HLINE, 0, 0, tpPrice))
      Print("Error creating take profit line: ", GetLastError());
   else
      ObjectSetInteger(0, tpLineName, OBJPROP_COLOR, clrGreen);

   if(!ObjectCreate(0, slLineName, OBJ_HLINE, 0, 0, slPrice))
      Print("Error creating stop loss line: ", GetLastError());
   else
      ObjectSetInteger(0, slLineName, OBJPROP_COLOR, clrRed);

   Print(tradeType, " trade levels drawn. Entry: ", entryPrice, ", TP: ", tpPrice, ", SL: ", slPrice);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double RoundDownTo2Digits(double value)
  {
   return MathFloor(value * 100) / 100.0;
  }
//+------------------------------------------------------------------+