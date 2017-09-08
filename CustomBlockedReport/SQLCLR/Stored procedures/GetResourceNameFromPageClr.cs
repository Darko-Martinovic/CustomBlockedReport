using System;
using System.Data;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using CustomBlockedProcess;

public partial class StoredProcedures
{
    [SqlProcedure]
    public static void GetResourceNameFromPageClr(
            SqlInt16 dbid,
            SqlInt32 fileId,
            SqlInt64 pageId
        )
    {
        string html = string.Empty;
        SqlMetaData[] metadata = new SqlMetaData[1];
        metadata[0] = new SqlMetaData("Value", SqlDbType.NVarChar, 256);

        string[] objId = DataAccess.GetData("DBCC traceon (3604);" + Environment.NewLine +
       "DBCC page (" + dbid.Value.ToString() + "," + fileId.Value.ToString() + "," + pageId.Value.ToString() + ") WITH TABLERESULTS ;", ref html);
        if (objId != null)
        {
            string dbName = DataAccess.GetResult("SELECT DB_NAME(" + dbid + ")");

            string query = "SELECT TOP 1 S.NAME + '.' + O.NAME Value, 'ObjectId' Field FROM " + dbName + ".SYS.objects O " +
                    " INNER JOIN " + dbName + ".SYS.PARTITIONS P ON O.object_id = p.object_id " +
                    " INNER JOIN " + dbName + ".SYS.SCHEMAS S ON O.SCHEMA_ID = S.SCHEMA_ID " +
                "WHERE P.OBJECT_ID = " + objId[1];

            objId = DataAccess.GetData(query, ref html);
        }
        else
        {
            objId = new string[] { "Error", html };

        }
        SqlDataRecord result = DataAccess.buildRecord(metadata, objId);
        SqlContext.Pipe.SendResultsStart(result);
        SqlContext.Pipe.SendResultsRow(result);
        SqlContext.Pipe.SendResultsEnd();
    }



}
