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
int SMA1_Period = 7;     // SMA7 Period
int SMA2_Period = 112;   // SMA112 Period


// DingTalk Configuration
input string DingTalkWebhook = "https://oapi.dingtalk.com/robot/send?access_token=94c6a3191ea56c6745982d2febde69b55aeee6de379dfd5def55ab80db1a963b";


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
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ProcessSMA();
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
   else
      if(SMA1_Prev > SMA2_Prev && SMA1_Curr < SMA2_Curr)  // Death Cross
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
//+------------------------------------------------------------------+
