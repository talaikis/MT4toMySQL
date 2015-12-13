/*
 * Created by Tadas Talaikis
 * TALAIKIS.COM.
 * Copyright 2015 Quantrade Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 */

#property version "2.0"

#property indicator_chart_window

extern string host     = "localhost";
extern int    port     = 3306;
extern int    socket   = 0;
extern string user     = "root";
extern string password = "Hg#1F8h^=GP5@4v0u9";
extern string dbName   = "lean";

int           _period = Period();

#include <MQLMySQL.mqh>
#include <Symbols.mqh>

static string   sSymbols[100];
static int      iSymbols;
static datetime tPreviousTime;
//double dMA;
int             DB; // database identifier
int             s;
int             i;
string          sPeriod = "," + PeriodToStr();

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
{
//---- indicators

//----
    return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----

//----
    return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
    int bars = IndicatorCounted() - 1;

    // only load the Symbols once into the array "sSymbols"
    if (iSymbols == 0)
        iSymbols = Symbols(sSymbols);

    //Print (MySqlVersion());

    if (Refresh(1440) == true)
    {
        // open database connection
        Print("Connecting...");

        //connect to database
        DB = MySqlConnect(host, user, password, dbName, port, socket, CLIENT_MULTI_STATEMENTS);

        if (DB == -1)
        {
            Print("Connection to MySQL database failed! Error: " + MySqlErrorDescription);
        }
        else
        {
            Print("Connected! DB_ID#", DB);
        }
        DoExport();
        MySqlDisconnect(DB);
        Print("MySQL disconnected. Bye.");
    }

//----
    return(0);
}
//+------------------------------------------------------------------+

//update base only once a bar
bool Refresh(int _per)
{
    static datetime PrevBar;
    //Print("Refresh times. PrevBar: "+PrevBar);

    if (PrevBar != iTime(NULL, _per, 0))
    {
        PrevBar = iTime(NULL, _per, 0);
        return(true);
    }
    else
    {
        return(false);
    }
}

void DoExport()
{
    for (s = 0; s < iSymbols; s++)
    {
        string   Query;
        int      i, Cursor, Rows;
        datetime vTime;
        int      notInTime;

        //create table
        Query = "CREATE TABLE IF NOT EXISTS `" + sSymbols[s] + "` (" +
                "DATE_TIME timestamp NOT NULL, " +
                "PERIOD int NOT NULL, " +
                "SPREAD double(15,6) NOT NULL, " +
                "OPEN double(15,6) NOT NULL, " +
                "HIGH double(15,6) NOT NULL, " +
                "LOW double(15,6) NOT NULL, " +
                "CLOSE double(15,6) NOT NULL, " +
                "VOLUME int NOT NULL, " +
                "PRIMARY KEY  (DATE_TIME)" +
                ") ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=0";
        if (MySqlExecute(DB, Query))
        {
            Print("Table " + sSymbols[s] + " is created.");
        }
        else
        {
            Print("Table " + sSymbols[s] + " cannot be created. Error: ", MySqlErrorDescription);
        }

        //for each historical bar / delay of 1 bar forlive trading!!
        for (i = 1; i < (Bars - 1); i++)
        {
            if (iClose(sSymbols[s], PERIOD_D1, i) != 0)
            {
                //for not available data, to avoid confusion didn't used by default
                //int shift = iBarShift(sSymbols[s], PERIOD_D1, iTime(sSymbols[s], PERIOD_D1, i), false);
                double _spread = MarketInfo(sSymbols[s], MODE_SPREAD) * MarketInfo(sSymbols[s], MODE_POINT);

                Query = "INSERT INTO `" + sSymbols[s] + "` (date_time, period, spread, open, high, low,close, volume) VALUES (\'" +
                        TimeToStr(iTime(sSymbols[s], _period, i), TIME_DATE | TIME_MINUTES | TIME_SECONDS) + "\'," +
                        Period() + "," +
                        NormalizeDouble(_spread, 6) + "," +
                        NormalizeDouble(iOpen(sSymbols[s], _period, i), 6) + "," +
                        NormalizeDouble(iHigh(sSymbols[s], _period, i), 6) + "," +
                        NormalizeDouble(iLow(sSymbols[s], _period, i), 6) + "," +
                        NormalizeDouble(iClose(sSymbols[s], _period, i), 6) + "," +
                        iVolume(sSymbols[s], _period, i) + ")";

                if (MySqlExecute(DB, Query))
                {
                    Print("Succeeded: ", Query);
                }
                else
                {
                    Print("Error: ", MySqlErrorDescription);
                    Print("Error with: ", Query);
                }
            } // end of check if there is data
        }
    }         // end of for each symbol
}             // end of do export
