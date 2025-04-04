//+------------------------------------------------------------------+
//|                                                    Strategy1.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict

// Strategy Configuration
string StrategyName = "Strategy 1";
input int SMA1_Period = 7;     // SMA7 Period
input int SMA2_Period = 112;   // SMA112 Period
input int SMA_Timeframe = 15;  // Timeframe in minutes
color SMA1_Color = clrBlue;    // Color for SMA7 line
color SMA2_Color = clrRed;     // Color for SMA112 line

// DingTalk Configuration
input string DingTalkWebhook = "https://oapi.dingtalk.com/robot/send?access_token=94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";

// OTP Configuration
input string UserOTP = "";     // User enters OTP here
const string HardcodedOTP = "XAI2025"; // Hardcoded OTP
bool isAuthenticated = false;  // Authentication status

// Global variables
datetime lastSignalTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Account Name: ", AccountName());
   Print(StrategyName, " Signal Generator Initialized on ", Period(), " minute chart");
   Print("Please enter the OTP in the input field to activate the EA.");
   
   if(UserOTP == HardcodedOTP)
   {
      isAuthenticated = true;
      Print("OTP Verified Successfully!");
   }
   else
   {
      Print("Invalid OTP. Please enter the correct OTP to activate the EA.");
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!isAuthenticated)
   {
      CheckOTP();
      return;
   }
   
   ProcessSMA();
   DrawSMA();
}

//+------------------------------------------------------------------+
//| Check OTP                                                        |
//+------------------------------------------------------------------+
void CheckOTP()
{
   if(UserOTP == HardcodedOTP)
   {
      isAuthenticated = true;
      Print("OTP Verified Successfully! EA is now active.");
   }
   else
   {
      Print("Invalid OTP. Please enter the correct OTP in the input field.");
   }
}

//+------------------------------------------------------------------+
//| SMA7 & SMA112 Strategy                                           |
//+------------------------------------------------------------------+
void ProcessSMA()
{
   double SMA1_Curr = iMA(Symbol(), 0, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double SMA2_Curr = iMA(Symbol(), 0, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double SMA1_Prev = iMA(Symbol(), 0, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double SMA2_Prev = iMA(Symbol(), 0, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   
   double currentPrice = Close[1];

   if(SMA1_Prev < SMA2_Prev && SMA1_Curr > SMA2_Curr)   // Golden Cross
   {
      string message = StringFormat("📈 BUY Signal - %s\nTime: %s\nPrice: %.5f\nSMA%d: %.5f\nSMA%d: %.5f",
         Symbol(), TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), currentPrice,
         SMA1_Period, SMA1_Curr, SMA2_Period, SMA2_Curr);
      
      Print(message);
      SendToDingTalk("BUY Signal", message);
      lastSignalTime = Time[1];
   }
   else if(SMA1_Prev > SMA2_Prev && SMA1_Curr < SMA2_Curr)  // Death Cross
   {
      string message = StringFormat("📉 SELL Signal - %s\nTime: %s\nPrice: %.5f\nSMA%d: %.5f\nSMA%d: %.5f",
         Symbol(), TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), currentPrice,
         SMA1_Period, SMA1_Curr, SMA2_Period, SMA2_Curr);
      
      Print(message);
      SendToDingTalk("SELL Signal", message);
      lastSignalTime = Time[1];
   }
}

//+------------------------------------------------------------------+
//| Draw SMA Lines on Chart                                         |
//+------------------------------------------------------------------+
void DrawSMA()
{
   string sma1_name = "SMA1_Line";
   string sma2_name = "SMA2_Line";
   
   if(ObjectFind(sma1_name) == -1)
   {
      ObjectCreate(0, sma1_name, OBJ_TREND, 0, 0, 0);
      ObjectSetInteger(0, sma1_name, OBJPROP_COLOR, SMA1_Color);
   }
   if(ObjectFind(sma2_name) == -1)
   {
      ObjectCreate(0, sma2_name, OBJ_TREND, 0, 0, 0);
      ObjectSetInteger(0, sma2_name, OBJPROP_COLOR, SMA2_Color);
   }
   
   for(int i = 0; i < Bars; i++)
   {
      double sma1_value = iMA(Symbol(), 0, SMA1_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      double sma2_value = iMA(Symbol(), 0, SMA2_Period, 0, MODE_SMA, PRICE_CLOSE, i);
      
      ObjectSetInteger(0, sma1_name, OBJPROP_TIME1, iTime(Symbol(), 0, i));
      ObjectSetDouble(0, sma1_name, OBJPROP_PRICE1, sma1_value);
      
      ObjectSetInteger(0, sma2_name, OBJPROP_TIME1, iTime(Symbol(), 0, i));
      ObjectSetDouble(0, sma2_name, OBJPROP_PRICE1, sma2_value);
   }
}

//+------------------------------------------------------------------+
//| Send notification to DingTalk                                    |
//+------------------------------------------------------------------+
void SendToDingTalk(string title, string text)
{
   string headers = "Content-Type: application/json\r\n";
   string msgtype = "markdown";
   
   string jsonData = StringFormat(
      "{\"msgtype\": \"%s\", \"markdown\": {\"title\": \"%s\", \"text\": \"%s\"}}",
      msgtype,
      title,
      text
   );

   char data[], result[];
   ArrayResize(data, StringToCharArray(jsonData, data, 0, WHOLE_ARRAY, CP_UTF8) - 1);

   int res = WebRequest("POST", DingTalkWebhook, headers, 5000, data, result, headers);

   if(res == -1)
   {
      Print("DingTalk WebRequest error: ", GetLastError());
   }
   else
   {
      Print("DingTalk notification sent successfully");
   }
}
