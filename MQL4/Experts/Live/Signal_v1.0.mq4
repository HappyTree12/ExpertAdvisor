//+------------------------------------------------------------------+
//|                                                  Signal_v1.0.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

struct SymbolTP
  {
   string            symbol;
   double            tp1;
   double            tp2;
  };

SymbolTP symbolTPs[] =
  {
     {"AUDUSD", 0.15, 0.35},
     {"EURUSD", 0.08, 0.16},
     {"GBPUSD", 0.12, 0.24},
     {"NZDUSD", 0.10, 0.20},
     {"USDCAD", 0.11, 0.22},
     {"USDCHF", 0.10, 0.20},
     {"USDJPY", 0.13, 0.26},
     {"AUDCAD", 0.15, 0.30},
     {"AUDCHF", 0.08, 0.16},
     {"EURJPY", 0.17, 0.34},
     {"EURNZD", 0.10, 0.20},
     {"GBPAUD", 0.11, 0.22},
     {"GBPNZD", 0.12, 0.24},
     {"AUDNZD", 0.07, 0.14},
     {"EURCAD", 0.09, 0.18},
     {"GBPJPY", 0.13, 0.26},
     {"GBPCAD", 0.12, 0.24},
     {"XAUUSD", 0.07, 0.17},
  };

int totalTrades = 0;
string message = "";

struct OrderData
  {
   int               ticket;
   string            symbol;
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
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   setPositions();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
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
      double tp1Percent = 0.0, tp2Percent = 0.0;

      // Find TP values for current symbol
      for(int i = 0; i < ArraySize(symbolTPs); i++)
        {
         if(symbolTPs[i].symbol == currentSymbol)
           {
            tp1Percent = symbolTPs[i].tp1;
            tp2Percent = symbolTPs[i].tp2;
            break;
           }
        }

      bool isBuy = (OrderType() == OP_BUY);
      double TP1 = 0, TP2 = 0;
      int digits = (int)MarketInfo(currentSymbol, MODE_DIGITS);

      if(tp1Percent > 0 && tp2Percent > 0)
        {
         if(isBuy)
           {
            TP1 = openPrice + (openPrice * tp1Percent / 100);
            TP2 = openPrice + (openPrice * tp2Percent / 100);
           }
         else
           {
            TP1 = openPrice - (openPrice * tp1Percent / 100);
            TP2 = openPrice - (openPrice * tp2Percent / 100);
           }
         TP1 = NormalizeDouble(TP1, digits);
         TP2 = NormalizeDouble(TP2, digits);
        }

      timeDiff = TimeCurrent() - OrderOpenTime();
      TimeToStruct(timeDiff, str1);

      if((str1.sec + str1.min) < 4)
        {
         string message = StringFormat(
                             "📢 K线实战交易讯号 📢\n"
                             "📍 交易方向：%s\n"
                             "🎯 交易品种：%s\n"
                             "📍 进场价位：%s\n"
                             "🎯 止盈目标：\n"
                             "- TP1：%s\n"
                             "- TP2：%s\n"
                             "- TP3：%s\n"
                             "🛑 止损设定：%s\n\n"
                             "⚠️ 重要提醒：\n"
                             "✅ 请根据钱包资金大小合理分配仓位，控制风险，避免过度杠杆！\n"
                             "⏳ 此交易讯号有时效性，超时请勿进场，以免错失最佳机会！\n"
                             "📢 资深策略老师带单，稳健出击！ 祝大家交易顺利 💰！",
                             isBuy ? "📈 多单" : "📉 空单",
                             currentSymbol,
                             DoubleToString(openPrice, digits),
                             DoubleToString(TP1, digits),
                             DoubleToString(TP2, digits),
                             "等待策略老师指示",
                             DoubleToString(OrderStopLoss(), digits)
                          );
         notifyTelegram(message);
         Print("Message sent: ", message);
         Sleep(3000);
        }
     }
  }

//+------------------------------------------------------------------+
//| Send notification to Telegram                                    |
//+------------------------------------------------------------------+
void notifyTelegram(string text)
  {
   string botToken = "7912129051:AAGRxWQH8_tTeT6v5t8Q8owf-kOiI0Mnrrg";
   string chatID = "-1002384381919_26";
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
   for(int i = 0; i < positionSize; i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         string symbol = OrderSymbol();
         int digits = (int)MarketInfo(symbol, MODE_DIGITS);
         double currentSL = NormalizeDouble(OrderStopLoss(), digits);
         double storedSL = NormalizeDouble(positions[i].stoploss, digits);
         
         if(currentSL != storedSL) {
             string direction = positions[i].type == OP_BUY ? "📈 多单" : "📉 空单";
             string msg = StringFormat("📢 止损更改 %s %s\n\旧 止损: %s\n新 止损: %s",
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
