//+------------------------------------------------------------------+
//|                      Merged EA: SMA                              |
//+------------------------------------------------------------------+
#property copyright "Jialin"
#property link      "https://www.mql5.com"
#property version   "1.0"
#property strict

// Adjustable Parameters
extern double Lots = 1.00;           // Lot size
extern int CooldownDuration = 60;    // Cooldown period in seconds
double SMA_Timeframe = 0;   // Timeframe for SMA calculations

// Unused parameters (kept for reference but not used)
extern double StopLoss = 5.0;        // Stop loss (not used)
extern double takeProfit = 10.0;     // Take Profit (not used)
extern double TrailingStepUSD = 3.0; // Trailing step in USD (not used)
extern double MoveStopLoss = 2.0;    // Move stop loss (not used)
double LastBuyThreshold = 0.0;       // For Buy Orders (not used)
double LastSellThreshold = 0.0;      // For Sell Orders (not used)

// Magic Number
int SMA_MagicNumber = 300;           // Magic number for SMA strategy

// Global Variables
datetime LastCloseTime = 0;          // Tracks the last order close time
datetime SMA_CooldownEndTime = 0;    // Cooldown end time for SMA strategy
string StrategyName = "SMA Crossover";

// Indicator Parameters
extern int SMA1_Period = 7;          // SMA7 for SMA Crossover
extern int SMA2_Period = 112;        // SMA112 for SMA Crossover

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Account Name: ", AccountName());
   Print("Account Balance: ", AccountBalance());
   Print(StrategyName, " EA Initialized , and it is running on %d.",Period());
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("EA Deinitialized. Reason: ", reason);
   Print("Account Profit: ", AccountProfit());
   ObjectsDeleteAll(0, "SL_");
  }

//+------------------------------------------------------------------+
//| Main OnTick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   MonitorClosedOrders();

   if(SMAHasOpenPositions())
     {
      CheckSMAExit();
     }
   else
      if(TimeCurrent() >= SMA_CooldownEndTime)
        {
         ProcessSMA();
        }
  }

//+------------------------------------------------------------------+
//| SMA7 & SMA112 Strategy                                           |
//+------------------------------------------------------------------+
void ProcessSMA()
  {
   double SMA1_Prev = iMA(Symbol(), SMA_Timeframe, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 2);  // 3rd candle SMA7
   double SMA2_Prev = iMA(Symbol(), SMA_Timeframe, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 2);  // 3rd candle SMA112
   double SMA1_Curr = iMA(Symbol(), SMA_Timeframe, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 1);  // 2nd candle SMA7
   double SMA2_Curr = iMA(Symbol(), SMA_Timeframe, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 1);  // 2nd candle SMA112

// Check for crossover conditions
   if(SMA1_Prev < SMA2_Prev && SMA1_Curr > SMA2_Curr)   // Golden Cross (Buy Signal)
     {
      Print("SMA Crossover: Bullish Signal Detected.");
      PlaceOrderSMA(OP_BUY, Ask, "SMA Long Entry");
     }
   else
      if(SMA1_Prev > SMA2_Prev && SMA1_Curr < SMA2_Curr)  // Death Cross (Sell Signal)
        {
         Print("SMA Crossover: Bearish Signal Detected.");
         PlaceOrderSMA(OP_SELL, Bid, "SMA Short Entry");
        }
  }

//+------------------------------------------------------------------+
//| Place Order Function for SMA                                     |
//+------------------------------------------------------------------+
void PlaceOrderSMA(int orderType, double price, string comment)
  {
// Place order without SL and TP (set to 0)
   int ticket = OrderSend(Symbol(), orderType, Lots, price, 3, 0, 0, "SMA CrossOver", SMA_MagicNumber, 0, clrRed);
   if(ticket < 0)
      Print("SMA: Order failed to place. Error: ", GetLastError());
   else
      Print("SMA: Order placed successfully. Ticket #: ", ticket);
  }

//+------------------------------------------------------------------+
//| Check for Open Positions for SMA                                 |
//+------------------------------------------------------------------+
bool SMAHasOpenPositions()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         (OrderType() == OP_BUY || OrderType() == OP_SELL) &&
         OrderMagicNumber() == SMA_MagicNumber)
        {
         return true; // Found an open position
        }
     }
   return false; // No open positions found
  }

//+------------------------------------------------------------------+
//| Check for Exit Conditions for SMA                                |
//+------------------------------------------------------------------+
void CheckSMAExit()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == SMA_MagicNumber &&
            (OrderType() == OP_BUY || OrderType() == OP_SELL))
           {
            int orderType = OrderType();
            double SMA1_Prev = iMA(Symbol(), SMA_Timeframe, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 2);
            double SMA2_Prev = iMA(Symbol(), SMA_Timeframe, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 2);
            double SMA1_Curr = iMA(Symbol(), SMA_Timeframe, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
            double SMA2_Curr = iMA(Symbol(), SMA_Timeframe, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 1);

            if(orderType == OP_BUY && SMA1_Prev > SMA2_Prev && SMA1_Curr < SMA2_Curr) // Death Cross
              {
               Print("Death Cross detected. Closing long position.");
               if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3))
                  Print("Error closing buy order: ", GetLastError());
              }
            else
               if(orderType == OP_SELL && SMA1_Prev < SMA2_Prev && SMA1_Curr > SMA2_Curr) // Golden Cross
                 {
                  Print("Golden Cross detected. Closing short position.");
                  if(!OrderClose(OrderTicket(), OrderLots(), Ask, 3))
                     Print("Error closing sell order: ", GetLastError());
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Monitor Closed Orders                                            |
//+------------------------------------------------------------------+
void MonitorClosedOrders()
  {
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         if(OrderMagicNumber() != SMA_MagicNumber)
            continue;

         if(OrderCloseTime() > LastCloseTime)
           {
            LastCloseTime = OrderCloseTime();
            SMA_CooldownEndTime = TimeCurrent() + CooldownDuration;
            Print("SMA: Cooldown started. Ends at: ", TimeToString(SMA_CooldownEndTime, TIME_DATE | TIME_SECONDS));
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Helper Function to Get Error Descriptions                        |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode)
  {
   switch(errorCode)
     {
      case ERR_NO_ERROR:
         return "No error";
      case ERR_INVALID_TICKET:
         return "Invalid ticket";
      case ERR_TRADE_MODIFY_DENIED:
         return "Modify denied";
      case ERR_TRADE_TIMEOUT:
         return "Trade timeout";
      case ERR_INVALID_STOPS:
         return "Invalid stops";
      default:
         return "Unknown error";
     }
  }
