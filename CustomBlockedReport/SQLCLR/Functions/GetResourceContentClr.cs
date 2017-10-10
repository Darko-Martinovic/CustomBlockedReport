using System;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using CustomBlockedProcess;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction(
            Name = "GetResourceContentClr",
            DataAccess = DataAccessKind.Read,
            SystemDataAccess = SystemDataAccessKind.Read,
            IsDeterministic = true)]
    public static SqlString GetResourceContentClr
    (
         [SqlFacet(IsNullable = true, MaxSize = 128)]SqlString waitResource,
         [SqlFacet(IsNullable = true, MaxSize = 256)]SqlString resourceName
    )
    {
        string resourceContent = null;
        if (waitResource.ToString().StartsWith(KEY))
            resourceContent = ProcessKey(waitResource.ToString(), resourceName.ToString());
        else if (waitResource.ToString().StartsWith(PAGE))
            resourceContent = ProcessPage(waitResource.ToString(), resourceName.ToString());
        return resourceContent;
    }

    #region ProcessPage

    private static string ProcessPage(string p, string tableName)
    {
        //PAGE: 7:1:422000
        string[] helper = p.Split(':');
        string retValue = p;
        if (helper.Length >= 2)
        {
            try
            {
                string hobid = "(" + helper[2].Trim() + ":" + helper[3].Trim() + "%";
                string dbId = helper[1].Trim();
                string query = @"SELECT DB_NAME(" + dbId + ");";
                string dbName = DataAccess.GetResult(query);
                string errorMessage = string.Empty;
                string columnList = BuildColumnList(tableName, ref errorMessage);
                query = "SELECT TOP 1 " + columnList + " FROM " + dbName + "." + tableName + " (NOLOCK) " +
                         " WHERE sys.fn_PhysLocFormatter(%%physloc%%) LIKE  '" + hobid + "' FOR XML AUTO";
                
                retValue = DataAccess.GetResult(query);
            }
            catch (Exception ex)
            {
                retValue = "Error while processing page value " + ex.Message;
            }
        }
        else
            retValue = "I expected page value in form of : 'PAGE: 7:1:422000'";
        return retValue;
    }

    #endregion

    #region ProcessKey

    private static string ProcessKey(string p, string tableName)
    {
        //KEY: 21:72057594054049792 (b14200e25741)
        string[] helper = p.Split(':');
        string retValue = p;
        if (helper.Length >= 2 && helper[2].IndexOf("(") > 0)
        {
            try
            {
                string hobid = helper[2].Substring(helper[2].IndexOf("("), helper[2].Length - helper[2].IndexOf("(")).Trim();
                string dbId = helper[1].Trim();
                string query = @"SELECT DB_NAME(" + dbId + ");";
                string dbName = DataAccess.GetResult(query);
                string errorMessage = "";
                string columnList = BuildColumnList(tableName, ref errorMessage);
                //return BuildColumnList(tableName, ref errorMessage);
                query = "SELECT TOP 1 " + columnList + " FROM " + dbName + "." + tableName + " ( NOLOCK) " +
                     " WHERE %%lockres%% = '" + hobid + "' FOR XML AUTO";
                retValue = DataAccess.GetResult(query);
            }
            catch (Exception ex)
            {
                retValue = "Error while processing key value " + ex.Message;
            }
        }
        else
            retValue = "I expected key value in form of : 'KEY: 21:72057594054049792 (b14200e25741)'";
        return retValue;
    }


    /// <summary>
    /// Returns comma separated list of columns
    /// </summary>
    /// <param name="tableName">Table name in form [schema_name].[table_name]</param>
    /// <param name="errorMessage">Error message</param>
    /// <returns>Comma separated list of columns. Columns that have CLR TYPES hierarchyid,geometry and geography are skiped</returns>
    private static string BuildColumnList(string tableName,ref string errorMessage)
    {
        string columnList = "*";

        string query = @"DECLARE @columns NVARCHAR(max) = ''
                        SELECT 
                            @columns = @columns+RTRIM(c.name)+','
                        FROM sys.columns c
                        LEFT OUTER JOIN sys.tables t ON c.object_id = t.object_id
                        LEFT OUTER JOIN SYS.schemas s ON s.schema_id = t.schema_id
                        WHERE t.name = '" + tableName.Split('.')[1] + "'" +
                            @" AND c.system_type_id != " + CLR_TYPE + 
                            @"AND s.name = '" + tableName.Split('.')[0]  + "';" +
                        @"SELECT SUBSTRING(@columns, 1, LEN(@columns)-1);";
        try
        {
            columnList = DataAccess.GetResult(query);
        }
        catch ( Exception ex)
        {
            columnList = "*";
            errorMessage = ex.Message;
        }
        return columnList;
    }

    #endregion


}
