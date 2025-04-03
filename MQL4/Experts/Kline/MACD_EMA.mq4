//+------------------------------------------------------------------+
//|                        MACD with EMA.mq4                            |
//|                            Kline                                 |
//|                  https://www.mql5.com                            |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property strict

// Global Variables
string StrategyName = "MACD_EMA";  // Strategy name for logging

// Adjustable Parameters
extern double Lots = 0.05;           // Lot size for trading
extern double StopLoss = 5.0;        // Stop loss in pips
extern double takeProfit = 3.0;      // Take Profit
extern int CooldownDuration = 60;   // Cooldown period in seconds (10 minutes)

//Indicator Adjustable Paramteter
int FastEMA = 12;            // Fast EMA for MACD
int SlowEMA = 26;            // Slow EMA for MACD
int SignalSMA = 9;           // Signal SMA for MACD
int EMA_Period = 52;         // EMA52 Value
int magicNumber = 100;

                          // User defined identifier
double MACD_Line_Current, Signal_Line_Current;  // MACD and Signal Line
double EMA_Current;                             // EMA52 value
double LastBuyThreshold = 0.0;  // For Buy Orders
double LastSellThreshold = 0.0; // For Sell Orders


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(StrategyName, " Initialized.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(StrategyName, " Deinitialized. Reason: ", reason);
   ObjectsDeleteAll(0, "SL_");
  }

//+------------------------------------------------------------------+
//| Main OnTick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Print(StrategyName, ": OnTick called.");

// Skip if there are open positions
   if(HasOpenPositions())
     {
      return; // Do not place new trades if an open position exists
     }

   
// Calculate MA7 values for the last 2 candles
   double EMA_SecondCandle =iMA(Symbol(), 0, EMA_Period, 0, MODE_SMA, PRICE_CLOSE, 2); // Second  MA7
   double EMA_Current = iMA(Symbol(), 0, EMA_Period, 0, MODE_SMA, PRICE_CLOSE, 1); // First  MA7


// Get closing and opening prices for the last  candle
   double Close_SecondCandle = iClose(Symbol(), 0, 2); // 1st candle close
   double Open_SecondCandle = iOpen(Symbol(), 0, 2);   // 1st candle open
   double Close_FirstCandle = iClose(Symbol(), 0, 1); // 1st candle close
   double Open_FirstCandle = iOpen(Symbol(), 0, 1);   // 1st candle open
   double Close_CurrentCandle = iClose(Symbol(), 0, 0); // Current candle close
   double Open_CurrentCandle = iOpen(Symbol(), 0, 0); // Current candle close

//--- Retrieve MACD values using iCustom
//double MACD_Current = iMACD(NULL, 0, "MACD", FastEMA, SlowEMA, SignalSMA, MODE_MAIN, 0);    // Current MACD Line
   double MACD_Current = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
//   Print("Current MACD Line : ", MACD_Current);
//double MACD_Previous = iMACD(NULL, 0, "MACD", FastEMA, SlowEMA, SignalSMA, MODE_MAIN, 1);  // Previous MACD Line
   double MACD_Previous = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
//   Print("Previous MACD Line : ", MACD_Previous);
//double Signal_Current = iMACD(NULL, 0,"MACD", FastEMA, SlowEMA, SignalSMA, MODE_SIGNAL, 0); // Current Signal Line
   double Signal_Current = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
//   Print("Current Signal Line : ", Signal_Current);
//double Signal_Previous = iMACD(NULL, 0, "MACD", FastEMA, SlowEMA, SignalSMA, MODE_SIGNAL, 1); // Previous Signal Line
   double Signal_Previous = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
//   Print("Previous Signal Line : ", Signal_Previous);
//   Print("Current EMA52 Value = ",EMA_Current);


// Long Entry Condition
//   if((Open_FirstCandle < EMA_Current)&& (Close_FirstCandle > EMA_Current))
  if((Open_SecondCandle < EMA_SecondCandle)&& (Close_SecondCandle > EMA_SecondCandle) && (Open_CurrentCandle > EMA_Current)&& (Close_CurrentCandle > EMA_Current))
     {
      Print("Candle Closes Above EMA52");
        {
         if((MACD_Previous < 0 &&Signal_Previous < 0 &&MACD_Current > 0 && Signal_Current >0) ||
            (MACD_Previous > 0 &&Signal_Previous < 0 &&MACD_Current > 0 && Signal_Current >0) ||
            (MACD_Previous < 0 &&Signal_Previous > 0 &&MACD_Current > 0 && Signal_Current >0))
           {
            Print(StrategyName, ": MACD and Signal lines cross above 0");
              {
               Print(StrategyName, ": Long condition met. Opening Buy order.");
               PlaceOrder(OP_BUY, Ask, "Long Entry");
               return; // Exit after placing an order
              }
           }

        }
     }




// Short Entry Condition
   else
 //     if((Open_FirstCandle > EMA_Current)&& (Close_FirstCandle < EMA_Current))
   if((Open_SecondCandle > EMA_SecondCandle)&& (Close_SecondCandle < EMA_SecondCandle) && (Open_CurrentCandle < EMA_Current)&& (Close_CurrentCandle < EMA_Current))
        {
         Print("Candle Closes Below EMA52");
           {
            if((MACD_Previous > 0 &&Signal_Previous > 0 &&MACD_Current < 0 && Signal_Current <0) ||
               (MACD_Previous < 0 &&Signal_Previous > 0 &&MACD_Current < 0 && Signal_Current <0) ||
               (MACD_Previous > 0 &&Signal_Previous < 0 &&MACD_Current < 0 && Signal_Current <0))
              {
               Print(StrategyName, ": MACD and Signal lines cross above 0");
                 {
                  Print(StrategyName, ": Short condition met. Opening Sell order.");
                  PlaceOrder(OP_SELL, Bid, "Short Entry");
                  return; // Exit after placing an order
                 }
              }

           }
        }

      else
         Print(StrategyName, ": No trade conditions met.");
  }
  
  

//+------------------------------------------------------------------+
//| Place Order Function                                             |
//+------------------------------------------------------------------+
void PlaceOrder(int orderType, double price, string comment)
  {
// Refactor this code below for eaier understanding purpose.
   double sl = (orderType == OP_BUY)
               ? price - StopLoss
               : price + StopLoss;
   double tp = (orderType == OP_BUY)
               ? price + takeProfit// Calculate Take Profit for BUY
               : price - takeProfit; // Calculate Take Profit for SELL
   int ticket = OrderSend(Symbol(), orderType, Lots, price, 3, sl,tp, comment, magicNumber, clrBlue);

   if(ticket < 0)
      Print(StrategyName, ": Order failed to place. Error: ", GetLastError());
   else
      Print(StrategyName, ": Order placed successfully. Ticket #: ", ticket);
  }

//+------------------------------------------------------------------+
//| Check for Open Positions                                         |
//+------------------------------------------------------------------+
bool HasOpenPositions()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         OrderType() <= OP_SELL &&
         OrderMagicNumber() == 100
        )
        {
         Print(StrategyName, "EA Positions are ongoing");
         return true; // Found an open position with the specified magic number
        }
     }
   return false; // No matching positions found
  }
//+------------------------------------------------------------------+
