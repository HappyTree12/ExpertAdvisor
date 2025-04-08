//+------------------------------------------------------------------+
//|                                      OrderBlockIndicator.mq4     |
//|                        Copyright 2023, MetaTrader Developer      |
//|                                             https://www.example.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaTrader Developer"
#property link      "https://www.example.com"
#property version   "1.00"
#property indicator_chart_window

//--- Input Parameters
input int ConsecutiveCandles = 3;    // Number of consecutive candles to confirm OB
input color BullishColor = clrGreen; // Color for bullish Order Blocks
input color BearishColor = #2;   // Color for bearish Order Blocks

//--- Global Variables
string orderBlocks[5];    // Array to store Order Block object names
datetime obTimes[5];      // Array to store Order Block times
int obCount = 0;          // Number of Order Blocks currently stored

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   obCount = 0; // Initialize count
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Clean up all Order Block objects
   for (int i = 0; i < obCount; i++) {
      ObjectDelete(0, orderBlocks[i]);
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
   int start = (prev_calculated == 0) ? rates_total - ConsecutiveCandles - 2 : rates_total - 1;

   // Declare objName once outside the loop
   string objName;

   // Process bars
   for (int i = start; i >= 0; i--) {
      if (IsBullishOrderBlock(i, close, open)) {
         objName = "OrderBlock_Bullish_" + TimeToString(time[i]); // Assign value
         DrawOrderBlock(objName, low[i], high[i], time[i], BullishColor);
         AddOrderBlock(objName, time[i]);
      }
      else if (IsBearishOrderBlock(i, close, open)) {
         objName = "OrderBlock_Bearish_" + TimeToString(time[i]); // Assign value
         DrawOrderBlock(objName, low[i], high[i], time[i], BearishColor);
         AddOrderBlock(objName, time[i]);
      }
   }
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Function to detect Bullish Order Block                           |
//+------------------------------------------------------------------+
bool IsBullishOrderBlock(int index, const double &close[], const double &open[]) {
   if (index < ConsecutiveCandles + 1) return false;
   if (close[index] < open[index]) { // Bearish candle after bullish sequence
      bool isBullishSequence = true;
      for (int j = 1; j <= ConsecutiveCandles; j++) {
         if (close[index - j] <= open[index - j]) {
            isBullishSequence = false;
            break;
         }
      }
      return isBullishSequence;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Function to detect Bearish Order Block                           |
//+------------------------------------------------------------------+
bool IsBearishOrderBlock(int index, const double &close[], const double &open[]) {
   if (index < ConsecutiveCandles + 1) return false;
   if (close[index] > open[index]) { // Bullish candle after bearish sequence
      bool isBearishSequence = true;
      for (int j = 1; j <= ConsecutiveCandles; j++) {
         if (close[index - j] >= open[index - j]) {
            isBearishSequence = false;
            break;
         }
      }
      return isBearishSequence;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Function to draw Order Block rectangle indefinitely to the right |
//+------------------------------------------------------------------+
void DrawOrderBlock(string objName, double low, double high, datetime timeStart, color col) {
   datetime extendedEndTime = TimeCurrent() + 1000000000; // Extend far into the future
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, timeStart, high, extendedEndTime, low);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, col);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true); // Draw behind price
}

//+------------------------------------------------------------------+
//| Function to add Order Block and manage the list                  |
//+------------------------------------------------------------------+
void AddOrderBlock(string objName, datetime obTime) {
   if (obCount < 5) {
      orderBlocks[obCount] = objName;
      obTimes[obCount] = obTime;
      obCount++;
   } else {
      ObjectDelete(0, orderBlocks[0]);
      for (int j = 1; j < 5; j++) {
         orderBlocks[j - 1] = orderBlocks[j];
         obTimes[j - 1] = obTimes[j];
      }
      orderBlocks[4] = objName;
      obTimes[4] = obTime;
   }
}

//+------------------------------------------------------------------+