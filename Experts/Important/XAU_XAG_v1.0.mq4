//+------------------------------------------------------------------+
//|                                                 XAU_XAG_v1.0.mq4 |
//|                                           Copyright 2024, Jialin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jialin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


// Always based on iHigh and Ilow
// PTP (Few Positions )
// Need to apply TrailingStoploss but with few tp
// Move to next entry when hit the tp.
// Short XAU and XAG
// Divergence can be apply to both pairing.
string const Strategy_Name = "XAU_XAG Divergence";
extern int TotalOrders = 5;
extern double TotalLots = 1.0;
extern double TakeProfit = 1.2;
extern int MA_Period = 7;

int MA7_Timeframe = PERIOD_M5;
int XAU_XAG_Timeframe = PERIOD_M5;
int XAU_XAG_Magic_Number = 1000;
int LookbackBars = 20;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print(Strategy_Name, " Initialized");
   Print("Account Name : ",AccountName());
   Print("Account Balance: ",AccountBalance());
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(Strategy_Name, " Deinitialized");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Xau();
   Xag();

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBearishDivergence()
  {
   double highestXAU = iHigh("XAUUSD", PERIOD_M5, iHighest("XAUUSD", PERIOD_M5, MODE_HIGH, LookbackBars, 1));
   double highestXAG = iHigh("XAGUSD", PERIOD_M5, iHighest("XAGUSD", PERIOD_M5, MODE_HIGH, LookbackBars, 1));

   double currentHighXAU = iHigh("XAUUSD", PERIOD_M5, 1);
   double currentHighXAG = iHigh("XAGUSD", PERIOD_M5, 1);

   return (currentHighXAU > highestXAU) && (currentHighXAG < highestXAG);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBullishDivergence()
  {
   double lowestXAU = iLow("XAUUSD", PERIOD_M5, iLowest("XAUUSD", PERIOD_M5, MODE_LOW, LookbackBars, 1));
   double lowestXAG = iLow("XAGUSD", PERIOD_M5, iLowest("XAGUSD", PERIOD_M5, MODE_LOW, LookbackBars, 1));

   double currentLowXAU = iLow("XAUUSD", PERIOD_M5, 1);
   double currentLowXAG = iLow("XAGUSD", PERIOD_M5, 1);

   return (currentLowXAU < lowestXAU) && (currentLowXAG > lowestXAG);
  }


//+------------------------------------------------------------------+
//| MA7 Strategy                                                     |
//+------------------------------------------------------------------+
void ProcessMA7()
  {
   double MA7_ThirdCandle = iMA(Symbol(),MA7_Timeframe, MA_Period, 0, MODE_EMA, PRICE_CLOSE, 2);  // 3rd candle MA7
   double MA7_SecondCandle = iMA(Symbol(), MA7_Timeframe, MA_Period, 0, MODE_EMA, PRICE_CLOSE, 1); // 2nd candle MA7

   double Open_ThirdCandle = iOpen(Symbol(), MA7_Timeframe, 2);   // 3rd candle open
   double Close_ThirdCandle = iClose(Symbol(), MA7_Timeframe, 2); // 3rd candle close
   double Open_SecondCandle = iOpen(Symbol(), MA7_Timeframe, 1);  // 2nd candle open
   double Close_SecondCandle = iClose(Symbol(), MA7_Timeframe, 1); // 2nd candle close
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|   Place Multiple Orders                                          |
//+------------------------------------------------------------------+
void PlaceMultipleOrders(int orderType, double slippage, double stopLoss, double takeProfit)
  {
   double lotSize = TotalLots / TotalOrders;

   for(int i = 0; i < TotalOrders; i++)
     {
      double price = (orderType == OP_BUY) ? Ask : Bid;
      double sl = 0;
      double tp = 0;

      // Calculate Stop Loss and Take Profit prices
      if(orderType == OP_BUY)
        {
         sl = stopLoss > 0 ? price - stopLoss * Point : 0;
         tp = takeProfit > 0 ? price + takeProfit * Point : 0;
        }
      else
         if(orderType == OP_SELL)
           {
            sl = stopLoss > 0 ? price + stopLoss * Point : 0;
            tp = takeProfit > 0 ? price - takeProfit * Point : 0;
           }

      int ticket = OrderSend(Symbol(), orderType, lotSize, price, slippage, sl, tp, "MultiOrder", 0, 0, clrBlue);
      if(ticket < 0)
        {
         Print("OrderSend failed");
        }
      else
        {
         Print("Order opened: ", ticket);
        }
      Sleep(1000); // Optional: wait 1 second between orders to reduce risk of rejection
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FixedTPAndSL()
  {

  }


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TrailingStoploss()
  {

  }
//+------------------------------------------------------------------+
