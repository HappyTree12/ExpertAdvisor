//+------------------------------------------------------------------+
//|                      Merged EA: MACD_EMA + MA7                  |
//+------------------------------------------------------------------+
#property copyright "Kline"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property strict

// Adjustable Parameters and default parameter
extern double Lots1 = 1.01;           // Lot size for MACD_EMA
extern double Lots2 = 0.99;           // Lot size for MA7
extern double StopLoss1 = 2.0;        // Stop loss for MACD_EMA
extern double takeProfit = 5.0;       // Take Profit
extern int CooldownDuration = 60;     // Cooldown period in seconds
extern int Choice = 3;                // Strategy selection (1: MACD_EMA, 2: MA7, 3: Both)
extern double StopLoss2 = 5.0;        // Stop Loss for MA7
extern double TrailingStepUSD = 3.0;  // Trailing step in USD (represent how many USD market up/down)
extern double MoveStopLoss = 2.0;     // Allow user to move the stoploss

double MACD_EMA_Timeframe = 0;
double MA7_Timeframe = 0;

double LastBuyThreshold = 0.0;  // For Buy Orders
double LastSellThreshold = 0.0; // For Sell Orders

// Magic Number
int MACD_MagicNumber = 100;   // Magic number for MACD_EMA strategy
int MA7_MagicNumber = 200;    // Magic number for MA7 strategy
int timeframe;

// Global Variables
datetime CooldownEndTime = 0;        // Cooldown end time (default is 0)
datetime LastCloseTime = 0;          // Tracks the last order close time
datetime MACD_CooldownEndTime = 0;
datetime MA7_CooldownEndTime = 0;
string StrategyName = "MACD_EMA_MA7 ";

// Indicator Parameters
extern int FastEMA = 12;                    // Fast EMA for MACD
extern int SlowEMA = 26;                    // Slow EMA for MACD
extern int SignalSMA = 9;                   // Signal SMA for MACD
extern int EMA_Period = 52;                 // EMA52 for MACD_EMA
extern int MA_Period = 7;                   // EMA7 for MA7 strategy

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
   Print("Account Name : ",AccountName());
   Print("Account Balance: ",AccountBalance());
   Print(StrategyName, "EA Initialized.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("EA Deinitialized. Reason: ", reason);
   Print("Account Profit : ",AccountProfit());
   ObjectsDeleteAll(0, "SL_");
  }

//+------------------------------------------------------------------+
//| Main OnTick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //Print("PERIOD: ", Period());

// Update trailing stop loss for all active orders
   UpdateTrailingStoploss();
   MonitorClosedOrders();

// Check for existing open positions for each strategy
   bool macdHasPosition = MACDHasOpenPositions(timeframe);  // Check if MACD_EMA strategy has an open position
   bool ma7HasPosition = MA7HasOpenPositions(timeframe);    // Check if MA7 strategy has an open position

   if(Choice == 1 && TimeCurrent() >= MACD_CooldownEndTime)   // MACD_EMA only
     {
      if(!MACDHasOpenPositions(timeframe))
         ProcessMACD_EMA();
     }
   else
      if(Choice == 2 && TimeCurrent() >= MA7_CooldownEndTime)   // MA7 only
        {
         if(!MA7HasOpenPositions(timeframe))
            ProcessMA7();
        }
      else
         if(Choice == 3)   // Both strategies
           {
            if(TimeCurrent() >= MACD_CooldownEndTime && !MACDHasOpenPositions(timeframe))
            ProcessMACD_EMA();

            if(TimeCurrent() >= MA7_CooldownEndTime && !MA7HasOpenPositions(timeframe))
            ProcessMA7();
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
//| MACD_EMA Strategy                                                |
//+------------------------------------------------------------------+
void ProcessMACD_EMA()
  {
   double EMA_Current = iMA(Symbol(), MACD_EMA_Timeframe, EMA_Period, 0, MODE_EMA, PRICE_CLOSE, 1);   // Current EMA
   double Close_FirstCandle = iClose(Symbol(), MACD_EMA_Timeframe, 1);                               // Previous candle close

   double MACD_Current = iMACD(NULL, MACD_EMA_Timeframe, FastEMA, SlowEMA, SignalSMA, PRICE_CLOSE, MODE_MAIN, 0);  // Current MACD Line
   double MACD_Previous = iMACD(NULL, MACD_EMA_Timeframe, FastEMA, SlowEMA, SignalSMA, PRICE_CLOSE, MODE_MAIN, 1); // Previous MACD Line
   double Signal_Current = iMACD(NULL, MACD_EMA_Timeframe, FastEMA, SlowEMA, SignalSMA, PRICE_CLOSE, MODE_SIGNAL, 0); // Current Signal Line
   double Signal_Previous = iMACD(NULL, MACD_EMA_Timeframe, FastEMA, SlowEMA, SignalSMA, PRICE_CLOSE, MODE_SIGNAL, 1); // Previous Signal Line

// Long Entry Condition
   if(Close_FirstCandle > EMA_Current &&
      ((MACD_Previous < 0 && Signal_Previous < 0 && MACD_Current > 0 && Signal_Current > 0) ||
       (MACD_Previous > 0 && Signal_Previous < 0 && MACD_Current > 0 && Signal_Current > 0) ||
       (MACD_Previous < 0 && Signal_Previous > 0 && MACD_Current > 0 && Signal_Current > 0)))
     {
      Print("MACD_EMA: Long condition met. Placing Buy order.");
      PlaceOrderMACD(OP_BUY, Ask, "MACD_EMA Long Entry");
      return;
     }

// Short Entry Condition
   if(Close_FirstCandle < EMA_Current &&
      ((MACD_Previous > 0 && Signal_Previous > 0 && MACD_Current < 0 && Signal_Current < 0) ||
       (MACD_Previous < 0 && Signal_Previous > 0 && MACD_Current < 0 && Signal_Current < 0) ||
       (MACD_Previous > 0 && Signal_Previous < 0 && MACD_Current < 0 && Signal_Current < 0)))
     {
      Print("MACD_EMA: Short condition met. Placing Sell order.");
      PlaceOrderMACD(OP_SELL, Bid, "MACD_EMA Short Entry");
      return;
     }
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


// Long Entry Condition
   if(Open_ThirdCandle <= MA7_ThirdCandle && Close_ThirdCandle > MA7_ThirdCandle &&
      Open_SecondCandle > MA7_SecondCandle && Close_SecondCandle > MA7_SecondCandle)
     {
      Print("MA7: Long condition met. Placing Buy order.");
      PlaceOrderMA7(OP_BUY, Ask, "MA7 Long Entry");
      return;
     }

// Short Entry Condition
   if(Open_ThirdCandle >= MA7_ThirdCandle && Close_ThirdCandle < MA7_ThirdCandle &&
      Open_SecondCandle < MA7_SecondCandle && Close_SecondCandle < MA7_SecondCandle)
     {
      Print("MA7: Short condition met. Placing Sell order.");
      PlaceOrderMA7(OP_SELL, Bid, "MA7 Short Entry");
      return;
     }
  }

//+------------------------------------------------------------------+
//| Place Order Functions for EMA MACD                               |
//+------------------------------------------------------------------+
void PlaceOrderMACD(int orderType, double price, string comment)
  {
   double sl = (orderType == OP_BUY) ? price - StopLoss1 : price + StopLoss1;
   double tp = (orderType == OP_BUY) ? price + takeProfit : price - takeProfit;
   int ticket = OrderSend(Symbol(), orderType, Lots1, price, 3, sl, tp, "MACD_EMA", MACD_MagicNumber, clrBlue);

   if(ticket < 0)
      Print("MACD_EMA: Order failed to place. Error: ", GetLastError());
   else
      Print("MACD_EMA: Order placed successfully. Ticket #: ", ticket);
  }

//+------------------------------------------------------------------+
//| Place Order Functions for EMA MACD                               |                            |
//+------------------------------------------------------------------+
void PlaceOrderMA7(int orderType, double price, string comment)
  {
   double sl = (orderType == OP_BUY) ? price - StopLoss2 : price + StopLoss2;
   int ticket = OrderSend(Symbol(), orderType, Lots2, price, 3, sl, 0, "MA7", MA7_MagicNumber, clrRed);

   if(ticket < 0)
      Print("MA7: Order failed to place. Error: ", GetLastError());
   else
      Print("MA7: Order placed successfully. Ticket #: ", ticket);
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check for Open Positions                                         |
//+------------------------------------------------------------------+
void UpdateTrailingStoploss()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      // Select the order by position
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         (OrderType() == OP_BUY || OrderType() == OP_SELL) &&
         OrderMagicNumber() == MA7_MagicNumber)
        {
         double currentSL = OrderStopLoss();       // Get the current Stop Loss
         double entryPrice = OrderOpenPrice();     // Get the entry price of the order
         double marketPrice = (OrderType() == OP_BUY) ? Bid : Ask; // Current market price
         double newSL = 0.0;

         // Trailing Stop for Buy Orders
         if(OrderType() == OP_BUY)
           {
            // Initialize the LastBuyThreshold if it's the first time
            if(LastBuyThreshold == 0.0)
               LastBuyThreshold = entryPrice;

            // Check if the market price has crossed the next threshold
            if(marketPrice >= LastBuyThreshold + TrailingStepUSD)
              {
               // Calculate the new SL based on the previous SL and MoveStopLoss
               newSL = currentSL + MoveStopLoss;

               // Only update SL if the new SL is less than the market price
               if(newSL < marketPrice)
                 {
                  // Attempt to modify the order
                  if(OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrGreen))
                    {
                     Print("Trailing Stop Updated for Buy Order | Ticket: ", OrderTicket(),
                           " | New SL: ", newSL,
                           " | Market Price: ", marketPrice,
                           " | Current SL: ", currentSL);

                     // Update the LastBuyThreshold to the next threshold
                     LastBuyThreshold += TrailingStepUSD;
                    }
                  else
                    {
                     // Log the error if OrderModify fails
                     int errorCode = GetLastError();
                     Print("Failed to update Trailing Stop for Buy Order | Ticket: ", OrderTicket(),
                           " | Error Code: ", errorCode,
                           " | Description: ", ErrorDescription(errorCode));
                    }
                 }
               else
                 {
                  // Log why the SL wasn't updated
                  Print("Trailing Stop NOT Updated for Buy Order | New SL: ", newSL,
                        " | Market Price: ", marketPrice,
                        " | Condition not met (newSL < marketPrice)");
                 }
              }
           }
         // Trailing Stop for Sell Orders
         else
            if(OrderType() == OP_SELL)
              {
               // Initialize the LastSellThreshold if it's the first time
               if(LastSellThreshold == 0.0)
                  LastSellThreshold = entryPrice;

               // Check if the market price has crossed the next threshold
               if(marketPrice <= LastSellThreshold - TrailingStepUSD)
                 {
                  // Calculate the new SL based on the previous SL and MoveStopLoss
                  newSL = currentSL - MoveStopLoss;

                  // Only update SL if the new SL is greater than the market price
                  if(newSL > marketPrice)
                    {
                     // Attempt to modify the order
                     if(OrderModify(OrderTicket(), entryPrice, newSL, OrderTakeProfit(), 0, clrRed))
                       {
                        Print("Trailing Stop Updated for Sell Order | Ticket: ", OrderTicket(),
                              " | New SL: ", newSL,
                              " | Market Price: ", marketPrice,
                              " | Current SL: ", currentSL);

                        // Update the LastSellThreshold to the next threshold
                        LastSellThreshold -= TrailingStepUSD;
                       }
                     else
                       {
                        // Log the error if OrderModify fails
                        int errorCode = GetLastError();
                        Print("Failed to update Trailing Stop for Sell Order | Ticket: ", OrderTicket(),
                              " | Error Code: ", errorCode,
                              " | Description: ", ErrorDescription(errorCode));
                       }
                    }
                  else
                    {
                     // Log why the SL wasn't updated
                     Print("Trailing Stop NOT Updated for Sell Order | New SL: ", newSL,
                           " | Market Price: ", marketPrice,
                           " | Condition not met (newSL > marketPrice)");
                    }
                 }
              }
        }
     }
  }

// Helper function to get error descriptions
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
//| Check for Open Positions for MACD                                  |
//+------------------------------------------------------------------+
bool MACDHasOpenPositions(int timeframe)
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        // Select the order by position
        if(OrderSelect(i, SELECT_BY_POS))
        {
            // Check if the order symbol matches the current symbol
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MACD_MagicNumber)
            {
                // Get the open time of the order
                datetime orderOpenTime = OrderOpenTime();
                
                // Check if the order is BUY and if it's for the specified timeframe
                if(OrderType() == OP_BUY && orderOpenTime >= iTime(Symbol(), timeframe, 0))
                {
                    Print("MACD LONG Positions are ongoing on timeframe ", timeframe);
                    return true; // Found an open BUY position
                }
                // Check if the order is SELL and if it's for the specified timeframe
                else if(OrderType() == OP_SELL && orderOpenTime >= iTime(Symbol(), timeframe, 0))
                {
                    Print("MACD SHORT Positions are ongoing on timeframe ", timeframe);
                    return true; // Found an open SELL position
                }
            }
        }
    }
    return false; // No matching positions found
}

//+------------------------------------------------------------------+
//| Check for Open Positions for MA7                                  |
//+------------------------------------------------------------------+
bool MA7HasOpenPositions(int timeframe)
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        // Select the order by position
        if(OrderSelect(i, SELECT_BY_POS))
        {
            // Check if the order symbol matches the current symbol
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MA7_MagicNumber)
            {
                // Get the open time of the order
                datetime orderOpenTime = OrderOpenTime();
                
                // Check if the order is SELL and if it's for the specified timeframe
                if(OrderType() == OP_SELL && orderOpenTime >= iTime(Symbol(), timeframe, 0))
                {
                    Print("MA7 SELL Positions are ongoing on timeframe ", timeframe);
                    return true; // Found an open SELL position
                }
                // Check if the order is BUY and if it's for the specified timeframe
                else if(OrderType() == OP_BUY && orderOpenTime >= iTime(Symbol(), timeframe, 0))
                {
                    Print("MA7 LONG Positions are ongoing on timeframe ", timeframe);
                    return true; // Found an open BUY position
                }
            }
        }
    }
    return false; // No matching positions found
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
         if(OrderMagicNumber() != MACD_MagicNumber && OrderMagicNumber() != MA7_MagicNumber)
            continue;

         if(OrderCloseTime() > LastCloseTime)
           {
            LastCloseTime = OrderCloseTime();

            if(OrderMagicNumber() == MACD_MagicNumber)
              {
               MACD_CooldownEndTime = TimeCurrent() + CooldownDuration;
               Print("MACD_EMA: Cooldown started. Ends at: ", TimeToString(MACD_CooldownEndTime, TIME_DATE | TIME_SECONDS));
              }
            else
               if(OrderMagicNumber() == MA7_MagicNumber)
                 {
                  MA7_CooldownEndTime = TimeCurrent() + CooldownDuration;
                  Print("MA7: Cooldown started. Ends at: ", TimeToString(MA7_CooldownEndTime, TIME_DATE | TIME_SECONDS));
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Send notification to Telegram                                    |
//+------------------------------------------------------------------+
void notifyTelegram(string text)
  {
   string botToken = "7509087473:AAGGxIvwXdTKTaGLXywjWzT6ETyp-k2Va3M";
   string chatID = "-4759024068";
   string url = "https://api.telegram.org/bot" + botToken + "/sendMessage";

   string headers = "Content-Type: application/json\r\n";
   string jsonData = StringFormat("{\"chat_id\": \"%s\", \"text\": \"%s\"}",
                                  chatID,
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
                             "平台: RockGlobal \n"
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
