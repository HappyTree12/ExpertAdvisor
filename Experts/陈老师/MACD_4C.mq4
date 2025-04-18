//+------------------------------------------------------------------+
//| 4-Color MACD Indicator for MT4                                   |
//+------------------------------------------------------------------+
#property copyright "Jialin"
#property version   "1.0"
#property strict

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   5

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  Lime   // MACD rising above zero
#property indicator_width1  3

#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  Green  // MACD falling above zero
#property indicator_width2  3

#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  Maroon // MACD falling below zero
#property indicator_width3  3

#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  Red    // MACD rising below zero
#property indicator_width4  3

#property indicator_type5   DRAW_LINE
#property indicator_color5  Gray   // Zero line
#property indicator_width5  1

// Input Parameters
input int FastMA = 12;   // Fast EMA period
input int SlowMA = 26;   // Slow EMA period
input int SignalMA = 9;  // Signal line period

// Indicator Buffers
double MacdUpLime[];   // MACD rising above zero (Lime)
double MacdDownGreen[]; // MACD falling above zero (Green)
double MacdDownMaroon[]; // MACD falling below zero (Maroon)
double MacdUpRed[];    // MACD rising below zero (Red)
double ZeroLineBuffer[]; // Zero reference line

//+------------------------------------------------------------------+
//| Custom Indicator Initialization                                 |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorShortName("MACD 4C");

// Assign buffers
   SetIndexBuffer(0, MacdUpLime);
   SetIndexBuffer(1, MacdDownGreen);
   SetIndexBuffer(2, MacdDownMaroon);
   SetIndexBuffer(3, MacdUpRed);
   SetIndexBuffer(4, ZeroLineBuffer);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Indicator Calculation Function                                  |
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
   if(rates_total < SlowMA)
      return 0; // Ensure enough data points

   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;

   for(int i = start; i < rates_total - 1; i++)  // Avoid out-of-range errors
     {
      // MACD Calculation
      double macdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i);
      double prevMacdValue = iMACD(NULL, 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, i + 1);

      // Reset buffers
      MacdUpLime[i] = 0;
      MacdDownGreen[i] = 0;
      MacdDownMaroon[i] = 0;
      MacdUpRed[i] = 0;

      ZeroLineBuffer[i] = 0; // Zero line reference

      // Color Logic (4-Color Histogram)
      if(macdValue > 0)
        {
         if(macdValue > prevMacdValue)
            MacdUpLime[i] = macdValue;  // Lime (MACD rising above zero)
         else
            MacdDownGreen[i] = macdValue; // Green (MACD falling above zero)
        }
      else
        {
         if(macdValue < prevMacdValue)
            MacdDownMaroon[i] = macdValue; // Maroon (MACD falling below zero)
         else
            MacdUpRed[i] = macdValue;  // Red (MACD rising below zero)
        }
     }

   return rates_total;
  }
//+------------------------------------------------------------------+
