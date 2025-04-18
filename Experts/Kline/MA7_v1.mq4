//+------------------------------------------------------------------+
//|                        Strategy 5.mq4                            |
//|                            Kline                                 |
//|                  https://www.mql5.com                            |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "1.0"
#property strict

// External Parameters
extern double Lots = 1;           // Lot size for trading
extern double StopLoss = 3.0;        // Stop loss in pips
extern double takeProfit = 5.0;      // Take Profit
extern int CooldownDuration = 60;   // Cooldown period in seconds (10 minutes)

// Global Variables
string StrategyName = "MA7";  // Strategy name for logging
datetime CooldownEndTime = 0;        // Cooldown end time (default is 0)
datetime LastCloseTime = 0;          // Tracks the last order close time
double LastBuyThreshold = 0.0;  // For Buy Orders
double LastSellThreshold = 0.0; // For Sell Orders


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(StrategyName, " Initialized.");
   CooldownEndTime = 0; // Ensure cooldown is reset on EA initialization
   LastCloseTime = 0;   // Reset LastCloseTime to prevent history processing
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

// Monitor for closed orders and update cooldown if necessary
   MonitorClosedOrders();


// Enforce cooldown only if it was triggered by a trade closure
   if(CooldownEndTime > TimeCurrent())
     {
      Print(StrategyName, ": Cooldown active. No trades until ", TimeToString(CooldownEndTime, TIME_DATE | TIME_SECONDS));
      return; // Exit early if cooldown is active
     }

// Trailing stop logic: Check and modify open orders
//   UpdateTrailingStopLoss();

// Skip if there are open positions
   if(HasOpenPositions())
     {
      Print(StrategyName, ": Position ongoing. Skipping new trades.");
      return; // Do not place new trades if an open position exists
     }

// Define parameters for Moving Average (MA7)
   int MA_Period = 7;

// Calculate MA7 values for the last 3 candles
   double MA7_ThirdCandle = iMA(Symbol(), 0, MA_Period, 0, MODE_EMA, PRICE_CLOSE, 2); // 3rd candle MA7
   double MA7_SecondCandle = iMA(Symbol(), 0, MA_Period, 0, MODE_EMA, PRICE_CLOSE, 1); // 2nd candle MA7

// Get closing and opening prices for the last 3 candles
   double Close_ThirdCandle = iClose(Symbol(), 0, 2); // 3rd candle close
   double Open_ThirdCandle = iOpen(Symbol(), 0, 2);   // 3rd candle open
   double Close_SecondCandle = iClose(Symbol(), 0, 1); // 2nd candle close
   double Open_SecondCandle = iOpen(Symbol(), 0, 1);   // 2nd candle open
   
   
   double High_SecondCandle = iHigh(Symbol(), 0, 1); //2nd candle high
   double Low_SecondCandle = iLow(Symbol(), 0, 1); //2nd candle low

// Long Entry Condition
   if(Open_ThirdCandle < MA7_ThirdCandle && Close_ThirdCandle > MA7_ThirdCandle)
     {
      Print(StrategyName, ": Candle breaks through MA7 (Long)");
      if(Open_SecondCandle > MA7_SecondCandle && Close_SecondCandle > MA7_SecondCandle && High_SecondCandle > MA7_SecondCandle && Low_SecondCandle > MA7_SecondCandle)
        {
         Print(StrategyName, ": Long condition met. Opening Buy order.");
         PlaceOrder(OP_BUY, Ask, "Long Entry");
         return; // Exit after placing an order
        }
     }

// Short Entry Condition
   if(Open_ThirdCandle > MA7_ThirdCandle && Close_ThirdCandle < MA7_ThirdCandle)
     {
      Print(StrategyName, ": Candle breaks through MA7 (Short)");
      if(Open_SecondCandle < MA7_SecondCandle && Close_SecondCandle < MA7_SecondCandle && High_SecondCandle < MA7_SecondCandle && Low_SecondCandle < MA7_SecondCandle)
        {
         Print(StrategyName, ": Short condition met. Opening Sell order.");
         PlaceOrder(OP_SELL, Bid, "Short Entry");
         return; // Exit after placing an order
        }
     }

   Print(StrategyName, ": No trade conditions met.");
  }

//+------------------------------------------------------------------+
//| Monitor Closed Orders and Start Cooldown                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Monitor Closed Orders and Start Cooldown                         |
//+------------------------------------------------------------------+
void MonitorClosedOrders()
  {
// Loop through order history
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         // Skip orders already processed (before the last recorded close time)
         if(OrderCloseTime() <= LastCloseTime)
            continue;

         // Update LastCloseTime to this order's close time
         LastCloseTime = OrderCloseTime();

         // Start cooldown only if a trade has been closed
         if(CooldownEndTime == 0 || TimeCurrent() > CooldownEndTime)
           {
            CooldownEndTime = TimeCurrent() + CooldownDuration;
            Print(StrategyName, ": Order closed. Cooldown started. Ends at: ", TimeToString(CooldownEndTime, TIME_DATE | TIME_SECONDS));
           }
         break; // No need to process further orders
        }
     }
  }

//+------------------------------------------------------------------+
//| Place Order Function                                             |
//+------------------------------------------------------------------+
void PlaceOrder(int orderType, double price, string comment)
  {
   double sl = (orderType == OP_BUY)
               ? price - StopLoss
               : price + StopLoss;
   double tp = (orderType == OP_BUY)
               ? price + takeProfit// Calculate Take Profit for BUY
               : price - takeProfit; // Calculate Take Profit for SELL
   int ticket = OrderSend(Symbol(), orderType, Lots, price, 3, sl,tp, comment, 0, clrBlue);

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
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() <= OP_SELL)
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
