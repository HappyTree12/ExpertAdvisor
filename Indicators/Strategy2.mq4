//+------------------------------------------------------------------+
//|                              SMA_MACD_4C_Strategy_Indicator.mq4  |
//|                  Custom Indicator with SMA 7,28,112 + MACD 4C    |
//+------------------------------------------------------------------+
#property copyright "xAI Grok 3"
#property link      "https://xai.com"
#property version   "1.00"
#property strict
#property indicator_chart_window // SMA on chart window
#property indicator_buffers 8    // 3 for SMA, 5 for MACD 4C
#property indicator_plots   8    // 3 for SMA, 5 for MACD 4C

//--- SMA Buffers (Chart Window)
double SMA7[];
double SMA28[];
double SMA112[];

//--- MACD 4C Buffers (Will be drawn below chart)
double MacdUpLime[];
double MacdDownGreen[];
double MacdDownMaroon[];
double MacdUpRed[];
double ZeroLineBuffer[];

//--- DingTalk credentials
string botToken = "94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";
string chatID = "-4759024068";

//--- Input parameters
input int SMA7_Period = 7;      // SMA 7 Period
input int SMA28_Period = 28;    // SMA 28 Period
input int SMA112_Period = 112;  // SMA 112 Period
input int FastMA = 12;          // MACD Fast EMA period
input int SlowMA = 26;          // MACD Slow EMA period
input int SignalMA = 9;         // MACD Signal line period

input bool EnableDingTalk = true; // Enable/Disable DingTalk Notifications
string DingTalkWebhook = "https://oapi.dingtalk.com/robot/send?access_token=94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- SMA Buffer mapping
   SetIndexBuffer(0, SMA7);
   SetIndexBuffer(1, SMA28);
   SetIndexBuffer(2, SMA112);
   
   //--- MACD 4C Buffer mapping (Indices 3-7)
   SetIndexBuffer(3, MacdUpLime);
   SetIndexBuffer(4, MacdDownGreen);
   SetIndexBuffer(5, MacdDownMaroon);
   SetIndexBuffer(6, MacdUpRed);
   SetIndexBuffer(7, ZeroLineBuffer);
   
   //--- SMA Plot styles
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrRed);    // SMA7 Red
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrWhite);  // SMA28 White
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, clrBlue);   // SMA112 Blue
   
   //--- MACD 4C Plot styles (Forced to chart window, scaled down)
   SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrLime);    // MACD rising above zero
   SetIndexStyle(4, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrGreen);   // MACD falling above zero
   SetIndexStyle(5, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrMaroon);  // MACD falling below zero
   SetIndexStyle(6, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrRed);     // MACD rising below zero
   SetIndexStyle(7, DRAW_LINE, STYLE_SOLID, 1, clrGray);         // Zero line
   
   //--- Set draw begin
   SetIndexDrawBegin(0, SMA7_Period);
   SetIndexDrawBegin(1, SMA28_Period);
   SetIndexDrawBegin(2, SMA112_Period);
   SetIndexDrawBegin(3, SlowMA);
   SetIndexDrawBegin(4, SlowMA);
   SetIndexDrawBegin(5, SlowMA);
   SetIndexDrawBegin(6, SlowMA);
   SetIndexDrawBegin(7, 0); // Zero line starts immediately
   
   //--- Set labels
   SetIndexLabel(0, "SMA7");
   SetIndexLabel(1, "SMA28");
   SetIndexLabel(2, "SMA112");
   SetIndexLabel(3, "MACD Up (Above)");
   SetIndexLabel(4, "MACD Down (Above)");
   SetIndexLabel(5, "MACD Down (Below)");
   SetIndexLabel(6, "MACD Up (Below)");
   SetIndexLabel(7, "Zero Line");
   
   //--- Indicator name
   IndicatorShortName("SMA_MACD_4C_Strategy");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Function to send message to DingTalk                            |
//+------------------------------------------------------------------+
void SendToDingTalk(string message)
{
   if (!EnableDingTalk) return;
   
   string headers = "Content-Type: application/json\r\n";
   string jsonPayload = "{\"msgtype\": \"text\", \"text\": {\"content\": \"" + message + "\"}, \"chatid\": \"" + chatID + "\"}";
   
   char postData[];
   char result[];
   string result_headers;
   
   ArrayResize(postData, StringToCharArray(jsonPayload, postData, 0, WHOLE_ARRAY, CP_UTF8) - 1);
   
   ResetLastError();
   int res = WebRequest("POST", 
                       DingTalkWebhook,
                       headers,
                       NULL,
                       10000,
                       postData,
                       ArraySize(postData),
                       result,
                       result_headers);
                       
   if (res == -1)
   {
      Print("Error sending message to DingTalk: ", GetLastError());
   }
   else
   {
      Print("Message sent successfully to DingTalk.");
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
                const int &spread[])
{
   if (rates_total < MathMax(SMA112_Period, SlowMA)) return 0;
   
   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
   
   //--- Calculate SMAs and MACD
   for(int i = start; i < rates_total-1; i++)
   {
      // Calculate SMAs (Chart Window)
      SMA7[i] = iMA(NULL, 0, SMA7_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA28[i] = iMA(NULL, 0, SMA28_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA112[i] = iMA(NULL, 0, SMA112_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      
      // Calculate MACD for 15M
      double macdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i);
      double prevMacdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i + 1);
      
      
      
      // Reset MACD buffers
      MacdUpLime[i] = 0;
      MacdDownGreen[i] = 0;
      MacdDownMaroon[i] = 0;
      MacdUpRed[i] = 0;
      ZeroLineBuffer[i] = 0;
      
      // MACD 4C Logic (Scaled down to fit below chart)
      if (macdValue > 0)
      {
         if (macdValue > prevMacdValue)
            MacdUpLime[i] = macdValue * 0.0001;  // Scale down to avoid overlap
         else
            MacdDownGreen[i] = macdValue * 0.0001; // Scale down to avoid overlap
      }
      else
      {
         if (macdValue < prevMacdValue)
            MacdDownMaroon[i] = macdValue * 0.0001; // Scale down to avoid overlap
         else
            MacdUpRed[i] = macdValue * 0.0001;  // Scale down to avoid overlap
      }
      
      //--- Check entry conditions with MACD confirmation
      if (i > 1)
      {
         // LONG: SMA alignment + MACD confirmation
         if(close[i-1] > SMA7[i-1] &&           // Price above SMA7
            SMA7[i-1] > SMA28[i-1] &&          // SMA7 above SMA28
            SMA28[i-1] > SMA112[i-1] &&        // SMA28 above SMA112
            macdValue > 0 &&                    // MACD above zero
            macdValue > prevMacdValue)         // MACD rising
         {
            string buySignal = "BuySignal" + TimeToString(time[i]);
            ObjectCreate(0, buySignal, OBJ_TEXT, 0, time[i], high[i] + 10 * Point);
            ObjectSetString(0, buySignal, OBJPROP_TEXT, "买入");
            ObjectSetInteger(0, buySignal, OBJPROP_COLOR, clrLime);
            ObjectSetInteger(0, buySignal, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
            
            SendToDingTalk("Buy Signal detected at " + TimeToString(time[i]) + 
                          "\nClose: " + DoubleToString(close[i-1], 5) +
                          "\nSMA7: " + DoubleToString(SMA7[i-1], 5) +
                          "\nSMA28: " + DoubleToString(SMA28[i-1], 5) +
                          "\nSMA112: " + DoubleToString(SMA112[i-1], 5) +
                          "\nMACD: " + DoubleToString(macdValue, 5));
         }
         
         // SHORT: SMA alignment + MACD confirmation
         if(close[i-1] < SMA7[i-1] &&           // Price below SMA7
            SMA7[i-1] < SMA28[i-1] &&          // SMA7 below SMA28
            SMA28[i-1] < SMA112[i-1] &&        // SMA28 below SMA112
            macdValue < 0 &&                    // MACD below zero
            macdValue < prevMacdValue)         // MACD falling
         {
            string sellSignal = "SellSignal" + TimeToString(time[i]);
            ObjectCreate(0, sellSignal, OBJ_TEXT, 0, time[i], low[i] - 10 * Point);
            ObjectSetString(0, sellSignal, OBJPROP_TEXT, "卖出");
            ObjectSetInteger(0, sellSignal, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, sellSignal, OBJPROP_ANCHOR, ANCHOR_TOP);
            
            SendToDingTalk("Sell Signal detected at " + TimeToString(time[i]) + 
                          "\nClose: " + DoubleToString(close[i-1], 5) +
                          "\nSMA7: " + DoubleToString(SMA7[i-1], 5) +
                          "\nSMA28: " + DoubleToString(SMA28[i-1], 5) +
                          "\nSMA112: " + DoubleToString(SMA112[i-1], 5) +
                          "\nMACD: " + DoubleToString(macdValue, 5));
         }
      }
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "BuySignal");
   ObjectsDeleteAll(0, "SellSignal");
}