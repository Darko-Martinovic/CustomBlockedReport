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
                query = "SELECT TOP 1 * FROM " + dbName + " ." + tableName + " (NOLOCK) " +
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

    private static string ProcessKey(string p, string name)
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
                query = "SELECT TOP 1 * FROM " + dbName + " ." + name + " ( NOLOCK) " +
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

    #endregion


}
