#property copyright "Grok 3 - xAI"
#property link      "https://xai.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Indicator buffers
double SMA7Buffer[];
double SMA112Buffer[];

//--- Input parameters
int SMA7Period = 7;    // SMA7 Period
int SMA112Period = 112; // SMA112 Period

//--- Global variables
int lastBar = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Indicator buffers mapping
   SetIndexBuffer(0, SMA7Buffer);
   SetIndexBuffer(1, SMA112Buffer);
   
   //--- Set indicator styles
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrBlue);   // SMA7 - Blue line
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrRed);    // SMA112 - Red line
   
   //--- Set indicator labels
   SetIndexLabel(0, "SMA7");
   SetIndexLabel(1, "SMA112");
   
   //--- Set indicator short name
   IndicatorShortName("SMA7_SMA112_Cross");
   
   return(INIT_SUCCEEDED);
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
   //--- Calculate SMA values
   for(int i = 0; i < rates_total; i++)
   {
      SMA7Buffer[i] = iMA(Symbol(), 0, SMA7Period, 0, MODE_SMA, PRICE_CLOSE, i);
      SMA112Buffer[i] = iMA(Symbol(), 0, SMA112Period, 0, MODE_SMA, PRICE_CLOSE, i);
   }
   
   //--- Detect crossovers only on new bar
   if(prev_calculated == 0 || rates_total > lastBar)
   {
      for(int i = MathMax(1, prev_calculated); i < rates_total; i++)
      {
         //--- Golden Cross (SMA7 crosses above SMA112)
         if(SMA7Buffer[i-1] < SMA112Buffer[i-1] && SMA7Buffer[i] > SMA112Buffer[i])
         {
            ObjectCreate(0, "LONG_" + IntegerToString(time[i]), OBJ_TEXT, 0, time[i], high[i] + 10 * Point);
            ObjectSetString(0, "LONG_" + IntegerToString(time[i]), OBJPROP_TEXT, "做空");
            ObjectSetInteger(0, "LONG_" + IntegerToString(time[i]), OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, "LONG_" + IntegerToString(time[i]), OBJPROP_FONTSIZE, 10);
         }
         
         //--- Death Cross (SMA7 crosses below SMA112)
         if(SMA7Buffer[i-1] > SMA112Buffer[i-1] && SMA7Buffer[i] < SMA112Buffer[i])
         {
            ObjectCreate(0, "SHORT_" + IntegerToString(time[i]), OBJ_TEXT, 0, time[i], low[i] - 10 * Point);
            ObjectSetString(0, "SHORT_" + IntegerToString(time[i]), OBJPROP_TEXT, "做多");
            ObjectSetInteger(0, "SHORT_" + IntegerToString(time[i]), OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, "SHORT_" + IntegerToString(time[i]), OBJPROP_FONTSIZE, 10);
         }
      }
      lastBar = rates_total;
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Remove all text objects when indicator is removed
   ObjectsDeleteAll(0, "LONG_");
   ObjectsDeleteAll(0, "SHORT_");
}