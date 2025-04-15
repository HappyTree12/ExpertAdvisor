//+------------------------------------------------------------------+
//|                        Strategy 5.mq4                            |
//|                            Kline                                 |
//|                  https://www.mql5.com                            |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "1.3"
#property strict

// External Parameters
extern double Lots = 0.05;           // Lot size for trading
extern double StopLoss = 5.0;        // Stop loss in pips
extern double TrailingStepUSD = 3.0; // Trailing step in USD
extern int CooldownDuration = 60;    // Cooldown period in seconds (1 minute)

// Global Variables
string StrategyName = "Strategy 5";  // Strategy name for logging
datetime CooldownEndTime = 0;        // Cooldown end time (default is 0)
datetime LastCloseTime = 0;          // Tracks the last order close time
bool CooldownActive = false;         // Flag to track if cooldown is active

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

   // Monitor for closed orders and update cooldown if necessary
   MonitorClosedOrders();

   // Enforce cooldown: Skip processing if cooldown hasn't ended
   if (CooldownActive)
     {
      Print(StrategyName, ": Cooldown active. No trades until ", TimeToString(CooldownEndTime, TIME_DATE | TIME_SECONDS));
      return; // Exit early if cooldown is active
     }

   // Trailing stop logic: Check and modify open orders
   TrailingStopLoss();

   // Skip if there are open positions
   if (HasOpenPositions())
     {
      Print(StrategyName, ": Position ongoing. Skipping new trades.");
      return; // Do not place new trades if an open position exists
     }

   // Define parameters for Moving Average (MA7)
   int MA_Period = 7;

   // Calculate MA7 values for the last 3 candles
   double MA7_ThirdCandle = iMA(Symbol(), 0, MA_Period, 0, MODE_SMA, PRICE_CLOSE, 2); // 3rd candle MA7
   double MA7_SecondCandle = iMA(Symbol(), 0, MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1); // 2nd candle MA7

   // Get closing and opening prices for the last 3 candles
   double Close_ThirdCandle = iClose(Symbol(), 0, 2); // 3rd candle close
   double Open_ThirdCandle = iOpen(Symbol(), 0, 2);   // 3rd candle open
   double Close_SecondCandle = iClose(Symbol(), 0, 1); // 2nd candle close
   double Open_SecondCandle = iOpen(Symbol(), 0, 1);   // 2nd candle open

   // Long Entry Condition
   if (Open_ThirdCandle < MA7_ThirdCandle && Close_ThirdCandle > MA7_ThirdCandle)
     {
      Print(StrategyName, ": Candle breaks through MA7 (Long)");
      if (Open_SecondCandle > MA7_SecondCandle && Close_SecondCandle > MA7_SecondCandle)
        {
         Print(StrategyName, ": Long condition met. Opening Buy order.");
         PlaceOrder(OP_BUY, Ask, "Long Entry");
         return; // Exit after placing an order
        }
     }

   // Short Entry Condition
   if (Open_ThirdCandle > MA7_ThirdCandle && Close_ThirdCandle < MA7_ThirdCandle)
     {
      Print(StrategyName, ": Candle breaks through MA7 (Short)");
      if (Open_SecondCandle < MA7_SecondCandle && Close_SecondCandle < MA7_SecondCandle)
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
void MonitorClosedOrders()
  {
   for (int i = OrdersHistoryTotal() - 1; i >= 0; i--)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         // Skip if this order's close time has already been processed
         if (OrderCloseTime() <= LastCloseTime) continue;

         // Update LastCloseTime to prevent reprocessing this order
         LastCloseTime = OrderCloseTime();

         // Start cooldown
         CooldownEndTime = TimeCurrent() + CooldownDuration;
         CooldownActive = true; // Set cooldown flag to true
         Print(StrategyName, ": Order closed. Cooldown started. Ends at: ", TimeToString(CooldownEndTime, TIME_DATE | TIME_SECONDS));
         break; // No need to process further orders
        }
     }
  }

//+------------------------------------------------------------------+
//| Trailing Stop Loss Function                                      |
//+------------------------------------------------------------------+
void TrailingStopLoss()
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

         // Adjust trailing stop
         if (OrderType() == OP_BUY && marketPrice - entryPrice >= profitThreshold)
           {
            double newSL = marketPrice - profitThreshold;
            if (newSL > currentSL && OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0))
               Print("Trailing Stop Updated for Buy Order | New SL: ", newSL);
           }
         else if (OrderType() == OP_SELL && entryPrice - marketPrice >= profitThreshold)
           {
            double newSL = marketPrice + profitThreshold;
            if (newSL < currentSL && OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0))
               Print("Trailing Stop Updated for Sell Order | New SL: ", newSL);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Place Order Function                                             |
//+------------------------------------------------------------------+
void PlaceOrder(int orderType, double price, string comment)
  {
   double sl = (orderType == OP_BUY) ? price - StopLoss * MarketInfo(Symbol(), MODE_POINT) : price + StopLoss * MarketInfo(Symbol(), MODE_POINT);
   int ticket = OrderSend(Symbol(), orderType, Lots, price, 3, sl, 0, comment, 0, clrBlue);

   if (ticket < 0)
      Print(StrategyName, ": Order failed to place. Error: ", GetLastError());
   else
      Print(StrategyName, ": Order placed successfully. Ticket #: ", ticket);
  }

//+------------------------------------------------------------------+
//| Check for Open Positions                                         |
//+------------------------------------------------------------------+
bool HasOpenPositions()
  {
   for (int i = 0; i < OrdersTotal(); i++)
     {
      if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() <= OP_SELL)
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+