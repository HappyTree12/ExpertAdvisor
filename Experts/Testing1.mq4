//+------------------------------------------------------------------+
//|                                                Strategy2[EA].mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

string MACD4C_Name = "MACD_4C";  // Name of the MACD 4C indicator file (without .ex4)
string OrderBlock = "LuxAlgo - Smart Money Concepts"; // Name of the Smart Money Concept 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   EventSetTimer(30);  // Sets the timer to 30 seconds
   return(0);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
EventKillTimer();   // Always clean up!

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   string symbol = Symbol();
//--- Read MACD 4C buffer from both H4 and M15
   string macdStateM1 = GetMACDState(symbol,PERIOD_M1,1);
   string macdStateH4 = GetMACDState(symbol, PERIOD_H4, 1);
   string macdStateM15 = GetMACDState(symbol, PERIOD_M15, 1);
   double nearestDemand = GetNearestOrderBlockPrice(false); // Below price
double nearestSupply = GetNearestOrderBlockPrice(true);  // Above price


   
Print ("SMC Demand :" , nearestDemand);
Print ("SMC Supply :" , nearestSupply);
   Print("1M MACD State: ",macdStateM1);
   Print("4H MACD State: ",macdStateH4);
   Print("15M MACD State: ",macdStateM15);

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Read MACD 4C State using iCustom                                 |
//+------------------------------------------------------------------+
string GetMACDState(string symbol, int tf, int shift)
  {
   double lime = iCustom(symbol, tf, MACD4C_Name, 0, shift);  // Up above 0
   double green = iCustom(symbol, tf, MACD4C_Name, 1, shift); // Down above 0
   double maroon = iCustom(symbol, tf, MACD4C_Name, 2, shift); // Down below 0
   double red = iCustom(symbol, tf, MACD4C_Name, 3, shift);   // Up below 0

   if(lime > 0)
      return "Lime";
   if(green > 0)
      return "Green";
   if(maroon < 0)
      return "Maroon";
   if(red < 0)
      return "Red";

   return "Neutral";
  }
//+------------------------------------------------------------------+


double GetNearestOrderBlockPrice(bool isAbove = false) {
    double nearestPrice = 0;
    double price = Bid;  // or use Close[0] or Ask, depending on your logic
    double distance = 100000;  // just a large number for comparison

    int total = ObjectsTotal();
    for (int i = 0; i < total; i++) {
        string name = ObjectName(i);

        if (ObjectType(name) == OBJ_RECTANGLE) {
            // Get top and bottom price of the rectangle
            double price1 = ObjectGet(name, OBJPROP_PRICE1);
            double price2 = ObjectGet(name, OBJPROP_PRICE2);

            double top = MathMax(price1, price2);
            double bottom = MathMin(price1, price2);
            double mid = (top + bottom) / 2;

            // If block is above/below price and closer than previous
            if (isAbove && mid > price && (mid - price) < distance) {
                nearestPrice = mid;
                distance = mid - price;
            } else if (!isAbove && mid < price && (price - mid) < distance) {
                nearestPrice = mid;
                distance = price - mid;
            }
        }
    }
    return nearestPrice;
}
