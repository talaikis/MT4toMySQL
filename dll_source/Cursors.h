#include "mysql.h"

// cursor definition
#define MAX_CURSORS 1024
struct CURSOR
      {
       int Id;
	   MYSQL* Connection;
	   MYSQL_RES* RecordSet;
       MYSQL_ROW CurrentRow;
      };

CURSOR Cursors[MAX_CURSORS];


// return free id in cursor's list
int GetNewCursorId()
{
	for (int i=0; i<MAX_CURSORS; i++)
		if (Cursors[i].Id == -1) return (i);
	return(-1);
}

// should be called from MySqlCursorOpen() ony when opening was succeded
// return value is CURSOR IDENTIFIER (not real address pointer)
int AddCursor(MYSQL* pConnection, MYSQL_RES* pRecordSet)
{
	int Result = GetNewCursorId();
	if (Result>=0)
	{
		Cursors[Result].Id = Result;
		Cursors[Result].Connection = pConnection;
		Cursors[Result].RecordSet = pRecordSet;
		Cursors[Result].CurrentRow = 0;
	}
	return (Result);
}

// should be called from MySqlCursorClose() ony when closing was succeded
// parameter pId - is CURSOR IDENTIFIER (was returned by AddCursor)
void DeleteCursor(int pId)
{
	if ((pId>=0) && (pId<MAX_CURSORS))
	{
		Cursors[pId].Id = -1;
	}
}

// initialization of all cursors
void CursorsInit()
{
 for (int i=0; i<MAX_CURSORS; i++)
     {
	  Cursors[i].Id = -1;
	 }
}

// close all opened cursors
void CursorsDeinit()
{
	for (int i=0; i<MAX_CURSORS; i++)
	{
		if (Cursors[i].Id != -1)
		{
			mysql_free_result(Cursors[i].RecordSet);
			DeleteCursor(i);
		}
	}

}



