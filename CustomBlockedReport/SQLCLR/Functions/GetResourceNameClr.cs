using System;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using CustomBlockedProcess;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction(
        Name = "GetResourceNameClr",
        DataAccess = DataAccessKind.Read,
        SystemDataAccess = SystemDataAccessKind.Read,
        IsDeterministic = true)]
    public static SqlString GetResourceNameClr
    (
        [SqlFacet(IsNullable = true, MaxSize = 128)]SqlString waitResource
    )
    {
        string resourceName = null;
        if (waitResource.ToString().StartsWith(KEY))
            resourceName = ProcessKey(waitResource.ToString());
        else if (waitResource.ToString().StartsWith(PAGE))
            resourceName = ProcessPage(waitResource.ToString());
        else if (waitResource.ToString().StartsWith(OBJECT))
            resourceName = ProcessObject(waitResource.ToString());
        else
            resourceName = waitResource.ToString();
        return resourceName;
    }

    #region ProcessKey

    private static string ProcessKey(string p)
    {
        string[] helper = p.Split(':');
        string retValue = p;
        if (helper.Length >= 2 && helper[2].IndexOf("(") > 0)
        {
            try
            {
                string hobid = helper[2].Substring(0, helper[2].IndexOf("(")).Trim();
                string dbId = helper[1].Trim();
                string query = @"SELECT DB_NAME(" + dbId + ");";
                string dbName = DataAccess.GetResult(query);
                query = "SELECT sc.name + '.' +so.name + '(' + si.name + ')' FROM " + dbName + " .sys.partitions AS p " +
                        " JOIN " + dbName + ".sys.objects AS so ON p.object_id = so.object_id " +
                        " JOIN " + dbName + ".sys.indexes AS si ON p.index_id = si.index_id " +
                        "                                   AND p.object_id = si.object_id " +
                        " JOIN " + dbName + ".sys.schemas AS sc ON so.schema_id = sc.schema_id " +
                        " WHERE p.hobt_id = " + hobid + ";";
                retValue = DataAccess.GetResult(query);
            }
            catch (Exception ex)
            {
                retValue = "Error while processing key value " + ex.Message;
            }
        }
        else
            retValue = "I expected key value in form of : 'KEY: <dbId>:<hobtId> (<hashValue>)'";
        return retValue;

    }

    #endregion

    #region ProcessPage
    private static string ProcessPage(string p)
    {
        //PAGE: 7:1:422000
        string[] helper = p.Split(':');
        string retValue = p;
        if (helper.Length >= 2)
        {
            try
            {
                string pageId = helper[3].ToString().Trim();
                string dbId = helper[1].Trim();
                string fileId = helper[2].Trim();
                string query = @"SELECT DB_NAME(" + dbId + ");";
                string dbName = DataAccess.GetResult(query);
                query = "DECLARE @objectId as bigint " + Environment.NewLine +
                        "DECLARE @pagedata TABLE" + Environment.NewLine +
                         "( " + Environment.NewLine +
         "ParentObject nvarchar(256) NULL, Object nvarchar(256) NULL, Field varchar(256) NULL, ObjectValue nvarchar(max) NULL " +
                          ");" + Environment.NewLine +
                          "DBCC traceon (3604);" + Environment.NewLine +
                          "INSERT INTO @pagedata( ParentObject, Object, Field, ObjectValue ) " + Environment.NewLine +
                          "EXEC ('DBCC page (" + dbId + "," + fileId + "," + pageId + ") WITH TABLERESULTS ');" + Environment.NewLine +
                          "SELECT @objectId=objectvalue FROM @pagedata WHERE field LIKE 'Metadata: ObjectId%';" + Environment.NewLine +
                          "SELECT TOP 1 S.NAME + '.' + O.NAME FROM " + dbName + ".SYS.objects O " +
                    " INNER JOIN " + dbName + ".SYS.PARTITIONS P ON O.object_id = p.object_id " +
                    " INNER JOIN " + dbName + ".SYS.SCHEMAS S ON O.SCHEMA_ID = S.SCHEMA_ID " +
                "WHERE P.OBJECT_ID =    CAST(@objectId AS NVARCHAR(MAX));";

                retValue = query;
            }
            catch (Exception ex)
            {
                retValue = "Error while processing page value " + ex.Message;
            }
        }
        else
            retValue = "I expected page value in form of : 'PAGE: <dbId>:<fileId>:<pageId>'";
        return retValue;

    }

    #endregion

    #region ProcessObject

    private static string ProcessObject(string p)
    {
        //OBJECT: 10:1730105204:0
        string[] helper = p.Split(':');
        string retValue = p;
        if (helper.Length >= 2)
        {
            try
            {
                string objectId = helper[2].ToString().Trim();
                string dbId = helper[1].Trim();
                string partitionId = helper[3].Trim();

                string query = @"SELECT DB_NAME(" + dbId + ");";
                string dbName = DataAccess.GetResult(query);

                query = "SELECT TOP 1 S.NAME + '.' + O.NAME FROM " + dbName + ".SYS.objects O " +
                    " INNER JOIN " + dbName + ".SYS.PARTITIONS P ON O.object_id = p.object_id " +
                    " INNER JOIN " + dbName + ".SYS.SCHEMAS S ON O.SCHEMA_ID = S.SCHEMA_ID " +
                "WHERE P.OBJECT_ID = " + objectId;
                retValue = DataAccess.GetResult(query);
                //retValue = "EXEC ('" + query + "')";
            }
            catch (Exception ex)
            {
                retValue = "Error while processing object value " + ex.Message;
            }
        }
        else
            retValue = "I expected object value in form of : 'OBJECT: <dbId>:<objectId>:<lockPartitionId>'";

        return retValue;

    }

    #endregion

    #region Constants

    public const string KEY = "KEY";
    public const string PAGE = "PAGE";
    public const string OBJECT = "OBJECT";

    #endregion

}
