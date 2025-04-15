//+------------------------------------------------------------------+
//|                              SMA_MACD_4C_Strategy_Indicator.mq4  |
//|                  Custom Indicator with SMA 7,28,112 + MACD 4C    |
//+------------------------------------------------------------------+
#property copyright "xAI Grok 3"
#property link      "https://xai.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   8

input int FastMA = 12;
input int SlowMA = 26;
input int SignalMA = 9;

#define TF_H4   PERIOD_H4
#define TF_M15  PERIOD_M15

double SMA7[];
double SMA28[];
double SMA112[];

double MacdUpLime[];
double MacdDownGreen[];
double MacdDownMaroon[];
double MacdUpRed[];
double ZeroLineBuffer[];

string botToken = "94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";
string chatID = "-4759024068";

input int SMA7_Period = 7;
input int SMA28_Period = 28;
input int SMA112_Period = 112;

input bool EnableDingTalk = true;
string DingTalkWebhook = "https://oapi.dingtalk.com/robot/send?access_token=94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, SMA7);
   SetIndexBuffer(1, SMA28);
   SetIndexBuffer(2, SMA112);

   SetIndexBuffer(3, MacdUpLime);
   SetIndexBuffer(4, MacdDownGreen);
   SetIndexBuffer(5, MacdDownMaroon);
   SetIndexBuffer(6, MacdUpRed);
   SetIndexBuffer(7, ZeroLineBuffer);

   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrRed);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrWhite);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, clrBlue);

   SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrLime);
   SetIndexStyle(4, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrGreen);
   SetIndexStyle(5, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrMaroon);
   SetIndexStyle(6, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrRed);
   SetIndexStyle(7, DRAW_LINE, STYLE_SOLID, 1, clrGray);

   SetIndexDrawBegin(0, SMA7_Period);
   SetIndexDrawBegin(1, SMA28_Period);
   SetIndexDrawBegin(2, SMA112_Period);
   SetIndexDrawBegin(3, SlowMA);
   SetIndexDrawBegin(4, SlowMA);
   SetIndexDrawBegin(5, SlowMA);
   SetIndexDrawBegin(6, SlowMA);
   SetIndexDrawBegin(7, 0);

   SetIndexLabel(0, "SMA7");
   SetIndexLabel(1, "SMA28");
   SetIndexLabel(2, "SMA112");
   SetIndexLabel(3, "MACD Up (Above)");
   SetIndexLabel(4, "MACD Down (Above)");
   SetIndexLabel(5, "MACD Down (Below)");
   SetIndexLabel(6, "MACD Up (Below)");
   SetIndexLabel(7, "Zero Line");

   IndicatorShortName("SMA_MACD_4C_Strategy");

   return(INIT_SUCCEEDED);
}

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
      Print("Error sending message to DingTalk: ", GetLastError());
   else
      Print("Message sent successfully to DingTalk.");
}

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

   for (int i = start; i < rates_total - 1; i++)
   {
      SMA7[i] = iMA(NULL, 0, SMA7_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA28[i] = iMA(NULL, 0, SMA28_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA112[i] = iMA(NULL, 0, SMA112_Period, 0, MODE_SMA, PRICE_CLOSE, i);

      double macdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i);
      double prevMacdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i + 1);

      MacdUpLime[i] = 0;
      MacdDownGreen[i] = 0;
      MacdDownMaroon[i] = 0;
      MacdUpRed[i] = 0;
      ZeroLineBuffer[i] = 0;

      if (macdValue > 0)
      {
         if (macdValue > prevMacdValue)
            MacdUpLime[i] = macdValue * 0.0001;
         else
            MacdDownGreen[i] = macdValue * 0.0001;
      }
      else
      {
         if (macdValue < prevMacdValue)
            MacdDownMaroon[i] = macdValue * 0.0001;
         else
            MacdUpRed[i] = macdValue * 0.0001;
      }

      if (i > 1)
      {
         string macdH4 = GetMACDState(Symbol(), TF_H4, 1);
         string macdM15 = GetMACDState(Symbol(), TF_M15, 1);

         if (close[i - 1] > SMA7[i - 1] &&
             SMA7[i - 1] > SMA28[i - 1] &&
             SMA28[i - 1] > SMA112[i - 1] &&
             macdValue > 0 &&
             macdValue > prevMacdValue &&
             macdH4 == "UpAboveZero" &&
             macdM15 == "UpAboveZero")
         {
            string buySignal = "BuySignal" + TimeToString(time[i]);
            ObjectCreate(0, buySignal, OBJ_TEXT, 0, time[i], high[i] + 10 * Point);
            ObjectSetString(0, buySignal, OBJPROP_TEXT, "买入");
            ObjectSetInteger(0, buySignal, OBJPROP_COLOR, clrLime);
            ObjectSetInteger(0, buySignal, OBJPROP_ANCHOR, ANCHOR_BOTTOM);

            SendToDingTalk("Buy Signal @ " + TimeToString(time[i]) +
                           "\nClose: " + DoubleToString(close[i - 1], 5) +
                           "\nSMA7: " + DoubleToString(SMA7[i - 1], 5) +
                           "\nSMA28: " + DoubleToString(SMA28[i - 1], 5) +
                           "\nSMA112: " + DoubleToString(SMA112[i - 1], 5) +
                           "\nMACD: " + DoubleToString(macdValue, 5) +
                           "\nMACD H4: " + macdH4 +
                           "\nMACD M15: " + macdM15);
         }

         if (close[i - 1] < SMA7[i - 1] &&
             SMA7[i - 1] < SMA28[i - 1] &&
             SMA28[i - 1] < SMA112[i - 1] &&
             macdValue < 0 &&
             macdValue < prevMacdValue &&
             macdH4 == "DownBelowZero" &&
             macdM15 == "DownBelowZero")
         {
            string sellSignal = "SellSignal" + TimeToString(time[i]);
            ObjectCreate(0, sellSignal, OBJ_TEXT, 0, time[i], low[i] - 10 * Point);
            ObjectSetString(0, sellSignal, OBJPROP_TEXT, "卖出");
            ObjectSetInteger(0, sellSignal, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, sellSignal, OBJPROP_ANCHOR, ANCHOR_TOP);

            SendToDingTalk("Sell Signal @ " + TimeToString(time[i]) +
                           "\nClose: " + DoubleToString(close[i - 1], 5) +
                           "\nSMA7: " + DoubleToString(SMA7[i - 1], 5) +
                           "\nSMA28: " + DoubleToString(SMA28[i - 1], 5) +
                           "\nSMA112: " + DoubleToString(SMA112[i - 1], 5) +
                           "\nMACD: " + DoubleToString(macdValue, 5) +
                           "\nMACD H4: " + macdH4 +
                           "\nMACD M15: " + macdM15);
         }
      }
   }

   return (rates_total);
}

//+------------------------------------------------------------------+
string GetMACDState(string symbol, int timeframe, int shift = 0)
{
   double lime = iCustom(symbol, timeframe, "MACD_4C", FastMA, SlowMA, SignalMA, 0, shift);
   double green = iCustom(symbol, timeframe, "MACD_4C", FastMA, SlowMA, SignalMA, 1, shift);
   double maroon = iCustom(symbol, timeframe, "MACD_4C", FastMA, SlowMA, SignalMA, 2, shift);
   double red = iCustom(symbol, timeframe, "MACD_4C", FastMA, SlowMA, SignalMA, 3, shift);

   if (lime > 0) return "UpAboveZero";
   if (green > 0) return "DownAboveZero";
   if (maroon < 0) return "DownBelowZero";
   if (red < 0) return "UpBelowZero";

   return "Flat";
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "BuySignal");
   ObjectsDeleteAll(0, "SellSignal");
}
 