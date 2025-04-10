//+------------------------------------------------------------------+
//|                            Strategy 1.mq4                        |
//|                            Custom Indicator with SMA 7 & 112     |
//+------------------------------------------------------------------+
#property copyright "Jialin"
#property version   "1.02"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Indicator buffers
double SMA7[];
double SMA112[];

//--- Input parameters
input int  SMA7_Period    = 7;        // SMA 7 Period
input int  SMA112_Period  = 112;      // SMA 112 Period
input bool EnableDingTalk = true;     // Enable DingTalk Notifications

string message = "";

//--- Data Structure for Order Information
struct OrderData {
   int      ticket;
   string   symbol;
   int      interval;
   int      type;
   double   lots;
   datetime open_time;
   double   open_price;
   double   stoploss;
   double   takeprofit;
   datetime close_time;
   double   close_price;
   datetime expiration;
   double   commission;
   double   swap;
   double   profit;
   string   comment;
   int      magic;
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   SetIndexBuffer(0, SMA7);
   SetIndexBuffer(1, SMA112);
   
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrRed);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrBlue);
   
   SetIndexDrawBegin(0, SMA7_Period);
   SetIndexDrawBegin(1, SMA112_Period);
   
   SetIndexLabel(0, "SMA7");
   SetIndexLabel(1, "SMA112");
   
   IndicatorShortName("SMA_Cross_7_112");
   
   // Test DingTalk connection on initialization
   if(EnableDingTalk) {
      notifyDingTalk("Indicator Started - SMA Cross Indicator");
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Helper Function to Get Error Descriptions                        |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode) {
   switch(errorCode) {
      case ERR_NO_ERROR:            return "No error";
      case ERR_INVALID_TICKET:      return "Invalid ticket";
      case ERR_TRADE_MODIFY_DENIED: return "Modify denied";
      case ERR_TRADE_TIMEOUT:       return "Trade timeout";
      case ERR_INVALID_STOPS:       return "Invalid stops";
      case ERR_FUNCTION_NOT_CONFIRMED: return "Function not confirmed (WebRequest failed)";
      default:                      return "Unknown error: " + IntegerToString(errorCode);
   }
}

//+------------------------------------------------------------------+
//| Send notification to DingTalk                                    |
//+------------------------------------------------------------------+
void notifyDingTalk(string text)
  {
   string botToken = "94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";
   string chatID = "-4759024068";
   string url = "https://oapi.dingtalk.com/robot/send?access_token=" + botToken;
   string msgtype = "markdown";
   string title = "策略1";
   string headers = "Content-Type: application/json\r\n";
   
   

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
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   static bool firstRun = true;
   static datetime lastNotification = 0; // Throttle notifications
   
   // Calculate SMA values
   for(int i = 0; i < rates_total; i++) {
      SMA7[i] = iMA(NULL, 0, SMA7_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA112[i] = iMA(NULL, 0, SMA112_Period, 0, MODE_SMA, PRICE_CLOSE, i);
   }
   
   // Check for crossovers
   for(int i = 1; i < rates_total-1; i++) {
      // Golden Cross (LONG)
      if(SMA7[i-1] < SMA112[i-1] && SMA7[i] > SMA112[i]) {
         string longSignal = "LongSignal" + TimeToString(time[i]);
         ObjectCreate(0, longSignal, OBJ_TEXT, 0, time[i], high[i]);
         ObjectSetString(0, longSignal, OBJPROP_TEXT, "Long");
         ObjectSetInteger(0, longSignal, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, longSignal, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
         
         if(EnableDingTalk && (TimeCurrent() - lastNotification > 60)) { // Throttle to 60 seconds
            notifyDingTalk("【Buy Signal】Golden Cross at " + TimeToString(time[i]) + 
                          " - SMA7 crossed above SMA112");
            lastNotification = TimeCurrent();
         }
      }
      
      // Death Cross (SHORT)
      if(SMA7[i-1] > SMA112[i-1] && SMA7[i] < SMA112[i]) {
         string shortSignal = "ShortSignal" + TimeToString(time[i]);
         ObjectCreate(0, shortSignal, OBJ_TEXT, 0, time[i], low[i]);
         ObjectSetString(0, shortSignal, OBJPROP_TEXT, "Short");
         ObjectSetInteger(0, shortSignal, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, shortSignal, OBJPROP_ANCHOR, ANCHOR_TOP);
         
         if(EnableDingTalk && (TimeCurrent() - lastNotification > 60)) { // Throttle to 60 seconds
            notifyDingTalk("【Sell Signal】Death Cross at " + TimeToString(time[i]) + 
                          " - SMA7 crossed below SMA112");
            lastNotification = TimeCurrent();
         }
      }
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "LongSignal");
   ObjectsDeleteAll(0, "ShortSignal");
}