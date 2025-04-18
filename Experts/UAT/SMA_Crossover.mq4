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
//| Telegram Configuration                                           |
//+------------------------------------------------------------------+
int totalTrades = 0;
string message = "";

struct OrderData
  {
   int               ticket;
   string            symbol;
   int               interval;
   int               type;
   double            lots;
   datetime          open_time;
   double            open_price;
   double            stoploss;
   double            takeprofit;
   datetime          close_time;
   double            close_price;
   datetime          expiration;
   double            commission;
   double            swap;
   double            profit;
   string            comment;
   int               magic;
  };

OrderData positions[] = {};


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

   if(!checkPositions())
     {
      setPositions();
     }

   if(totalTrades != OrdersTotal())
     {
      getMostRecentOrder();
      totalTrades = OrdersTotal();
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

//+------------------------------------------------------------------+
//| Send notification to Telegram                                    |
//+------------------------------------------------------------------+
void notifyTelegram(string text)
  {
   string botToken = "94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";
   string chatID = "-4759024068";
   string url = "https://oapi.dingtalk.com/robot/send?access_token=" + botToken;
   string msgtype = "markdown";
   string title = "策略1";
   string headers = "Content-Type: application/json\r\n";
   
   
//string jsonData = StringFormat("{\"msgtype\": \"%s\", \"text\": \"%s\"}",
//                               chatID,
//                               text);

  string jsonData = StringFormat("{\"msgtype\": \"%s\", \"markdown\": {\"title\": \"%s\", \"text\": \"%s\" }}",
                                  msgtype,
                                  title,
                                  text);

   char data[], result[];
   ArrayResize(data, StringToCharArray(jsonData, data, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   int res = WebRequest("POST", url, headers, 5000, data, result, headers);

   if(res == -1)
     {
      Print("WebRequest error: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| Position management functions                                    |
//+------------------------------------------------------------------+
bool checkPositions()
  {
   int positionSize = ArraySize(positions);
   if(positionSize != OrdersTotal())
     {
      if(positionSize > OrdersTotal())
        {
         for(int j = 0; j < positionSize; j++)
           {
            bool orderExists = false;
            for(int i = OrdersTotal() - 1; i >= 0; i--)
              {
               if(OrderSelect(i, SELECT_BY_POS) && positions[j].ticket == OrderTicket())
                 {
                  orderExists = true;
                  break;
                 }
              }
            if(!orderExists)
              {
               string message = StringFormat("📢 %s %s 平仓",
                                             positions[j].type == OP_BUY ? "📈 多单" : "📉 空单",
                                             positions[j].symbol);
               notifyTelegram(message);
              }
           }
        }
      setPositions();
      return false;
     }
// Check for stop loss modifications
   bool slModified = false;
   for(int i = 0; i < positionSize; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         string symbol = OrderSymbol();
         int digits = (int)MarketInfo(symbol, MODE_DIGITS);
         double currentSL = NormalizeDouble(OrderStopLoss(), digits);
         double storedSL = NormalizeDouble(positions[i].stoploss, digits);

         if(currentSL != storedSL)
           {
            string direction = positions[i].type == OP_BUY ? "📈 多单" : "📉 空单";
            string msg = StringFormat("📢 %s 止损更改 %s %s\n\旧 止损: %s\n新 止损: %s",
                                      OrderComment(),
                                      direction, symbol,
                                      DoubleToString(storedSL, digits),
                                      DoubleToString(currentSL, digits));
            notifyTelegram(msg);
            positions[i].stoploss = OrderStopLoss(); // Update stored SL
            slModified = true;
           }
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Get most recent order and send notification                      |
//+------------------------------------------------------------------+
void getMostRecentOrder()
  {
   int lastOrderIndex = OrdersTotal() - 1;
   double openPrice = 0;
   datetime timeDiff;
   MqlDateTime str1;

   if(OrderSelect(lastOrderIndex, SELECT_BY_POS, MODE_TRADES))
     {
      openPrice = OrderOpenPrice();
      string currentSymbol = OrderSymbol();
      bool isBuy = (OrderType() == OP_BUY);

      timeDiff = TimeCurrent() - OrderOpenTime();
      TimeToStruct(timeDiff, str1);

      if((str1.sec + str1.min) < 4)
        {
         string message = StringFormat(
                             "📢 Expert Advisor %s📢 \n"
                             "📍 交易方向：%s\n"
                             "⏰ 交易时间:%s 分钟\n"
                             "🎯 交易品种：%s\n"
                             "📍 进场价位：%s\n"
                             "🟢 止盈设定：%s\n"
                             "🛑 止损设定：%s\n\n",
                             OrderComment(),
                             isBuy ? "📈 多单" : "📉 空单",
                             IntegerToString(Period(),(int)MarketInfo(currentSymbol, MODE_DIGITS)),
                             currentSymbol,
                             DoubleToString(openPrice, (int)MarketInfo(currentSymbol, MODE_DIGITS)),
                             DoubleToString(OrderTakeProfit(), (int)MarketInfo(currentSymbol, MODE_DIGITS)),
                             DoubleToString(OrderStopLoss(), (int)MarketInfo(currentSymbol, MODE_DIGITS))
                          );
         notifyTelegram(message);
         Print("Message sent: ", message);
         Sleep(3000);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setPositions()
  {
   ArrayResize(positions, OrdersTotal());
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         positions[i].ticket     = OrderTicket();
         positions[i].symbol     = OrderSymbol();
         positions[i].interval   = Period();
         positions[i].type       = OrderType();
         positions[i].lots       = OrderLots();
         positions[i].open_time  = OrderOpenTime();
         positions[i].open_price = OrderOpenPrice();
         positions[i].stoploss   = OrderStopLoss();
         positions[i].takeprofit = OrderTakeProfit();
         positions[i].expiration = OrderExpiration();
         positions[i].comment    = OrderComment();
         positions[i].magic      = OrderMagicNumber();
        }
     }
  }
//+------------------------------------------------------------------+
