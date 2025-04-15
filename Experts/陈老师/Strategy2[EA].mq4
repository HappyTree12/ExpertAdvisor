//+------------------------------------------------------------------+
//|                                                Strategy2[EA].mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern string MACD4C_Name = "MACD_4C";  // Name of the MACD 4C indicator file (without .ex4)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   string symbol = Symbol();
      //--- Read MACD 4C buffer from both H4 and M15
   string macdStateH4 = GetMACDState(symbol, PERIOD_H4, 1);
   string macdStateM15 = GetMACDState(symbol, PERIOD_M15, 1);

   Print("MACD State: " ,macdStateH4);
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Read MACD 4C State using iCustom                                 |
//+------------------------------------------------------------------+
string GetMACDState(string symbol, int tf, int shift) {
   double green = iCustom(symbol, tf, MACD4C_Name, 0, shift);   // Lime (Up above 0)
   double red   = iCustom(symbol, tf, MACD4C_Name, 3, shift);   // Red (Up below 0)

   if (green > 0) return "Green";
   if (red < 0) return "Red";

   return "Neutral";
}