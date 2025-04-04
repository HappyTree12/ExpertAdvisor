//+------------------------------------------------------------------+
//|                        Trade Manager Panel                      |
//|                       Enhanced Version                         |
//|------------------------------------------------------------------+
#property copyright "Jialin"
#property version   "1.0"
#property strict

// Panel Coordinates and Dimensions
#define PANEL_X          20
#define PANEL_Y          40
#define PANEL_WIDTH      250
#define PANEL_HEIGHT     300
#define BUTTON_CORNER    4     // Corner radius
#define FONT_SIZE        9
#define FONT             "Arial Bold"

// Colors
#define CLR_PANEL_BG     clrDarkSlateGray
#define CLR_BORDER       clrSilver
#define CLR_TEXT         clrWhite
#define CLR_BUY          C'0,150,0'
#define CLR_SELL         C'150,0,0'
#define CLR_NEUTRAL      clrDarkGray

// Global Variables
input double LotSize = 1.0;
input double StopLoss = 20.0;
input double TakeProfit = 20.0;
input double RiskPercent = 2.0;

//+------------------------------------------------------------------+
//| Create Trade Panel                                              |
//+------------------------------------------------------------------+
void OnInit()
{
   CreatePanel();
   Comment("Enhanced Trade Manager Panel Initialized");
}

//+------------------------------------------------------------------+
//| OnTick Function                                                 |
//+------------------------------------------------------------------+
void OnTick()
{
   UpdatePanelInfo();
}

//+------------------------------------------------------------------+
//| Create Main Panel                                               |
//+------------------------------------------------------------------+
void CreatePanel()
{
   // Panel Background
   ObjectCreate(0, "PanelBG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "PanelBG", OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, "PanelBG", OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, "PanelBG", OBJPROP_XSIZE, PANEL_WIDTH);
   ObjectSetInteger(0, "PanelBG", OBJPROP_YSIZE, PANEL_HEIGHT);
   ObjectSetInteger(0, "PanelBG", OBJPROP_BGCOLOR, CLR_PANEL_BG);
   ObjectSetInteger(0, "PanelBG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "PanelBG", OBJPROP_COLOR, CLR_BORDER);
   
   // Title
   ObjectCreate(0, "PanelTitle", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "PanelTitle", OBJPROP_XDISTANCE, PANEL_X + 10);
   ObjectSetInteger(0, "PanelTitle", OBJPROP_YDISTANCE, PANEL_Y + 10);
   ObjectSetString(0, "PanelTitle", OBJPROP_TEXT, "Trade Manager");
   ObjectSetInteger(0, "PanelTitle", OBJPROP_COLOR, CLR_TEXT);
   ObjectSetString(0, "PanelTitle", OBJPROP_FONT, FONT);
   ObjectSetInteger(0, "PanelTitle", OBJPROP_FONTSIZE, FONT_SIZE + 1);
   
   // Create Buttons
   CreateStyledButton("BUY", "Buy Market", PANEL_X + 20, PANEL_Y + 40, 100, 40, CLR_BUY);
   CreateStyledButton("SELL", "Sell Market", PANEL_X + 130, PANEL_Y + 40, 100, 40, CLR_SELL);
   CreateStyledButton("CLOSE", "Close All", PANEL_X + 20, PANEL_Y + 90, 210, 35, CLR_NEUTRAL);
   CreateStyledButton("BE", "Break Even", PANEL_X + 20, PANEL_Y + 135, 210, 35, C'0,100,150');
   
   // Info Display
   CreateInfoLabel("LotInfo", "Lot Size: " + DoubleToString(LotSize, 2), PANEL_X + 20, PANEL_Y + 180);
   CreateInfoLabel("RiskInfo", "Risk: " + DoubleToString(RiskPercent, 1) + "%", PANEL_X + 20, PANEL_Y + 200);
}

//+------------------------------------------------------------------+
//| Create Styled Button                                            |
//+------------------------------------------------------------------+
void CreateStyledButton(string name, string text, int x, int y, int width, int height, color btnColor)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, BUTTON_CORNER);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, btnColor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, CLR_TEXT);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhiteSmoke);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, FONT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE);
}

//+------------------------------------------------------------------+
//| Create Info Label                                               |
//+------------------------------------------------------------------+
void CreateInfoLabel(string name, string text, int x, int y)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, CLR_TEXT);
   ObjectSetString(0, name, OBJPROP_FONT, FONT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE - 1);
}

//+------------------------------------------------------------------+
//| Update Panel Information                                        |
//+------------------------------------------------------------------+
void UpdatePanelInfo()
{
   ObjectSetString(0, "LotInfo", OBJPROP_TEXT, "Lot Size: " + DoubleToString(LotSize, 2));
   ObjectSetString(0, "RiskInfo", OBJPROP_TEXT, "Risk: " + DoubleToString(RiskPercent, 1) + "%");
}

//+------------------------------------------------------------------+
//| Handle Button Clicks                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (id == CHARTEVENT_OBJECT_CLICK)
   {
      if (sparam == "BUY") 
      {
         OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, "Buy Order", 0, 0, CLR_BUY);
      }
      if (sparam == "SELL") 
      {
         OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, "Sell Order", 0, 0, CLR_SELL);
      }
      if (sparam == "CLOSE") CloseAllOrders();
      if (sparam == "BE") MoveStopToBreakEven();
   }
}

//+------------------------------------------------------------------+
//| Close All Orders                                                |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderType() == OP_BUY)
            OrderClose(OrderTicket(), OrderLots(), Bid, 3, CLR_NEUTRAL);
         if (OrderType() == OP_SELL)
            OrderClose(OrderTicket(), OrderLots(), Ask, 3, CLR_NEUTRAL);
      }
   }
}

//+------------------------------------------------------------------+
//| Move Stop Loss to Break Even                                    |
//+------------------------------------------------------------------+
void MoveStopToBreakEven()
{
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         double entryPrice = OrderOpenPrice();
         if (OrderType() == OP_BUY)
            OrderModify(OrderTicket(), entryPrice, entryPrice, OrderTakeProfit(), 0, C'0,100,150');
         else if (OrderType() == OP_SELL)
            OrderModify(OrderTicket(), entryPrice, entryPrice, OrderTakeProfit(), 0, C'0,100,150');
      }
   }
}

//+------------------------------------------------------------------+
//| Deinitialization                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll();
   Comment("");
}