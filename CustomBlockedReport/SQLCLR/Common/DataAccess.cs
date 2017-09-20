//Developing
using Microsoft.SqlServer.Server;
using System;
using System.Data.SqlClient;

namespace CustomBlockedProcess
{
    public static class DataAccess
    {
        public static string GetResult(string Query)
        {
            string ds = null;
            try
            {
                using (SqlConnection cnn = new SqlConnection("context connection=true"))
                {
                    using (SqlCommand command = new SqlCommand(Query, cnn))
                    {
                        cnn.Open();
                        ds = command.ExecuteScalar().ToString();
                        cnn.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                ds = ex.Message;
            }
            return ds;
        }


        public static string[] GetData(string Query, ref string html)
        {
            string[] ds = null;
            try
            {
                using (SqlConnection cnn = new SqlConnection("context connection=true"))
                {
                    using (SqlCommand command = new SqlCommand(Query, cnn))
                    {
                        cnn.Open();
                        using (SqlDataReader dr = command.ExecuteReader())
                        {
                            while (dr.Read())
                            {
                                if (dr["Field"].ToString().IndexOf("ObjectId") >= 0)
                                {
                                    ds = new string[] { dr["Field"].ToString(), dr["Value"].ToString() };
                                    break;
                                }
                            }
                            if (dr.IsClosed == false)
                                dr.Close();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                html += ex.Message;
            }
            return ds;
        }

        public static SqlDataRecord buildRecord(SqlMetaData[] metadata, string[] entry)
        {
            SqlDataRecord record = new SqlDataRecord(metadata);
            record.SetSqlString(0, entry[1]);
            return record;
        }


    }
}
