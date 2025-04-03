//+------------------------------------------------------------------+
//|                       EA_Template.mq4                            |
//|          Standard Template for Expert Advisors (EA)              |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.0"
#property strict

// External Parameters
extern double Lots = 0.1;             // Lot size for trading
extern double TakeProfit = 30;        // Take profit in points
extern double StopLoss = 30;          // Stop loss in points
extern int TradeCooldown = 60;        // Cooldown between trades in seconds
extern double RiskPercent = 1.0;      // Risk percentage for dynamic lot sizing

string StrategyName = "Template Strategy"; // Strategy name for logging

// Global Variables
datetime lastTradeTime;               // Track the time of the last trade

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print(StrategyName, " Initialized.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print(StrategyName, " Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Main OnTick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Cooldown check to avoid overtrading
   if (TimeCurrent() - lastTradeTime < TradeCooldown)
   {
      return; // Skip trading during the cooldown period
   }

   // Check for existing positions
   if (HasOpenPositions())
   {
      return; // Exit if any position is already open
   }

   // Detect trading signals (replace with your conditions)
   bool isBuySignal = DetectBuySignal();
   bool isSellSignal = DetectSellSignal();

   // Execute trades based on signals
   if (isBuySignal)
   {
      PlaceOrder(OP_BUY);
   }
   else if (isSellSignal)
   {
      PlaceOrder(OP_SELL);
   }
}

//+------------------------------------------------------------------+
//| PlaceOrder Function                                              |
//| Handles order placement logic                                    |
//+------------------------------------------------------------------+
void PlaceOrder(int orderType)
{
   double entryPrice = (orderType == OP_BUY) ? Ask : Bid;
   double slPrice = (orderType == OP_BUY) ? NormalizeDouble(entryPrice - StopLoss * Point, Digits)
                                          : NormalizeDouble(entryPrice + StopLoss * Point, Digits);
   double tpPrice = (orderType == OP_BUY) ? NormalizeDouble(entryPrice + TakeProfit * Point, Digits)
                                          : NormalizeDouble(entryPrice - TakeProfit * Point, Digits);

   double lotSize = CalculateLotSize(RiskPercent);
   int ticket = OrderSend(Symbol(), orderType, lotSize, entryPrice, 3, slPrice, tpPrice,
                          StrategyName + (orderType == OP_BUY ? " Buy" : " Sell"), 0, 0,
                          (orderType == OP_BUY ? clrGreen : clrRed));
   if (ticket < 0)
   {
      Print("Error opening ", (orderType == OP_BUY ? "Buy" : "Sell"), " order: ", GetLastError());
   }
   else
   {
      lastTradeTime = TimeCurrent();
      Print("Order placed: ", (orderType == OP_BUY ? "Buy" : "Sell"),
            " | Entry: ", entryPrice, " | SL: ", slPrice, " | TP: ", tpPrice);
      DrawTradeLevels((orderType == OP_BUY ? "Buy" : "Sell"), entryPrice, tpPrice, slPrice);
   }
}

//+------------------------------------------------------------------+
//| Detect Buy Signal                                                |
//| Returns true if conditions for a buy trade are met               |
//+------------------------------------------------------------------+
bool DetectBuySignal()
{
   // Replace with your buy signal logic
   return false; // Default: No buy signal
}

//+------------------------------------------------------------------+
//| Detect Sell Signal                                               |
//| Returns true if conditions for a sell trade are met              |
//+------------------------------------------------------------------+
bool DetectSellSignal()
{
   // Replace with your sell signal logic
   return false; // Default: No sell signal
}

//+------------------------------------------------------------------+
//| Check for Open Positions                                         |
//| Returns true if any position is open for this symbol             |
//+------------------------------------------------------------------+
bool HasOpenPositions()
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol())
      {
         return true; // An open position exists
      }
   }
   return false; // No open positions
}

//+------------------------------------------------------------------+
//| Draw Trade Levels                                                |
//| Visualizes Entry, Take Profit, and Stop Loss levels              |
//+------------------------------------------------------------------+
void DrawTradeLevels(string tradeType, double entryPrice, double tpPrice, double slPrice)
{
   string prefix = "TP_SL_";

   string entryLineName = prefix + tradeType + "_Entry";
   string tpLineName = prefix + tradeType + "_TakeProfit";
   string slLineName = prefix + tradeType + "_StopLoss";

   // Delete existing objects to avoid duplicates
   ObjectDelete(0, entryLineName);
   ObjectDelete(0, tpLineName);
   ObjectDelete(0, slLineName);

   // Create or update entry price line
   if (!ObjectCreate(0, entryLineName, OBJ_HLINE, 0, 0, entryPrice))
      Print("Error creating entry line: ", GetLastError());
   else
      ObjectSetInteger(0, entryLineName, OBJPROP_COLOR, clrWhite);

   // Create or update take profit line
   if (!ObjectCreate(0, tpLineName, OBJ_HLINE, 0, 0, tpPrice))
      Print("Error creating take profit line: ", GetLastError());
   else
      ObjectSetInteger(0, tpLineName, OBJPROP_COLOR, clrGreen);

   // Create or update stop loss line
   if (!ObjectCreate(0, slLineName, OBJ_HLINE, 0, 0, slPrice))
      Print("Error creating stop loss line: ", GetLastError());
   else
      ObjectSetInteger(0, slLineName, OBJPROP_COLOR, clrRed);

   // Log visualization
   Print(tradeType, " trade levels visualized on chart. Entry: ", entryPrice,
         ", TP: ", tpPrice, ", SL: ", slPrice);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk Percentage                      |
//| Returns the lot size                                             |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskPercent)
{
   double accountRisk = AccountFreeMargin() * riskPercent / 100.0;
   double stopLossPoints = StopLoss * Point;
   double lotSize = accountRisk / (stopLossPoints * MarketInfo(Symbol(), MODE_TICKVALUE));
   return NormalizeDouble(lotSize, 2); // Adjust to broker's lot size step
}