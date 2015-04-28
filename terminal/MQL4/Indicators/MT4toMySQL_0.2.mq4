/*
 * QUANTCONNECT.COM - Democratizing Finance, Empowering Individual.
 * Lean Algorithmic Trading Engine v2.0. Copyright 2014 QuantConnect Corporation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, softwar
 * distributed under the License is distributed on an "AS IS" BASIS
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied
 * See the License for the specific language governing permissions a
 * limitations under the Licnsense.
 *
 */

#property version "1.0"

#property indicator_chart_window

extern string host     = "localhost";
extern int    port     = 3306;
extern int    socket   = 0;
extern string user     = "root";
extern string password = "8h^=GP655@740u9";
extern string dbName   = "lean";

#include <MQLMySQL.mqh>

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
    int DB; // database identifier

    //Print (MySqlVersion());

    if (Refresh() == true)
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

        string   Query;
        string   _symbol    = Symbol();
        string   _period    = IntegerToString(Period());
        string   _tablename = "equity_" + _symbol + _period;
        int      i, Cursor, Rows;
        datetime vTime;
        int      notInTime;

        //drop table if exists for data cleari8ng purposes
        //Query = "DROP TABLE IF EXISTS `equity_" + _symbol + _period + "`";
        //MySqlExecute(DB, Query);


        //create table
        Query = "CREATE TABLE IF NOT EXISTS `" + _tablename + "` (" +
                "DATE_TIME timestamp NOT NULL default CURRENT_TIMESTAMP, " +
                "OPEN double(15,6) NOT NULL, " +
                "HIGH double(15,6) NOT NULL, " +
                "LOW double(15,6) NOT NULL, " +
                "CLOSE double(15,6) NOT NULL, " +
                "VOLUME int NOT NULL, " +
                "PRIMARY KEY  (DATE_TIME)" +
                ") ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=0";
        if (MySqlExecute(DB, Query))
        {
            Print("Table equity_" + _symbol + " is created.");
        }
        else
        {
            Print("Table equity_" + _symbol + " cannot be created. Error: ", MySqlErrorDescription);
        }

        //check how many new bars not in database
        Query = "SELECT date_time FROM `" + _tablename + "` ORDER BY date_time DESC LIMIT 1";
        Print("SQL> ", Query);
        Cursor = MySqlCursorOpen(DB, Query);

        if (Cursor >= 0)
        {
            Rows = MySqlCursorRows(Cursor);
            Print(Rows, " row(s) selected.");
            if (Rows == 0)
            {
                notInTime = Bars - 1;
                Print("We have bars available: " + notInTime);
            }
            else
            {
                for (i = 0; i < Rows; i++)
                {
                    if (MySqlCursorFetchRow(Cursor))
                    {
                        vTime = MySqlGetFieldAsDatetime(Cursor, 0); // start_time
                        //Comment(notInTime);
                    }
                    notInTime = (Time[1] - vTime) / Period();
                    Print("Rows not in: " + notInTime);
                }

                MySqlCursorClose(Cursor); // NEVER FORGET TO CLOSE CURSOR !!!
            }
        }
        else
        {
            Print("Cursor opening failed. Error: ", MySqlErrorDescription);
        }



        //insert bars that aren't in database
        if (notInTime >= 1)
        {
            //for each historical bar / delay of 1 bar forlive trading!!
            for (i = 1; i < notInTime; i++)
            {
                Print("we have bars available at 5: " + notInTime);
                //Inserting data 1 row

                Query = "INSERT INTO `" + _tablename + "` (date_time, open, high, low,close, volume) VALUES (\'" +
                        TimeToStr(Time[i], TIME_DATE | TIME_SECONDS) + "\'," +
                        NormalizeDouble(Open[i], Digits) + "," +
                        NormalizeDouble(Low[i], Digits) + "," +
                        NormalizeDouble(High[i], Digits) + "," +
                        NormalizeDouble(Close[i], Digits) + "," +
                        Volume[i] + ")";

                if (MySqlExecute(DB, Query))
                {
                    Print("Succeeded: ", Query);
                }
                else
                {
                    Print("Error: ", MySqlErrorDescription);
                    Print("Error with: ", Query);
                }
            }
        }

        MySqlDisconnect(DB);
        Print("MySQL disconnected. Bye.");
    } // end of refresh

//----
    return(0);
}
//+------------------------------------------------------------------+

//update base only once a bar
bool Refresh()
{
    static datetime PrevBar;

    if (PrevBar != iTime(NULL, Period(), 0))
    {
        PrevBar = iTime(NULL, Period(), 0);
        return(true);
    }
    else
    {
        return(false);
    }
}
