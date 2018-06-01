using BlockingSession.ConfigHelper;
using System;
using System.Data.SqlClient;
using System.Diagnostics;

namespace BlockingSession
{
    class Program
    {
        static void Main(string[] args)
        {
            string connectionString = UserInfo.InjectInformationAboutUser(DVConfiguration.myConnString);
     
            // Provide the query string with a parameter placeholder.
            string queryString =
                ""
                    + "UPDATE PERSON.PERSON "
                    + "SET LastName = LastName "
                    + "WHERE BusinessEntityID = @parametar";

            // Specify the parameter value.
            int paramValue = 1;
            // Create and open the connection in a using block. This
            // ensures that all resources will be closed and disposed
            // when the code exits.
            SqlTransaction trn = null;
            using (SqlConnection connection =
                new SqlConnection(connectionString))
            {
                // Create the Command and Parameter objects.
                SqlCommand command = new SqlCommand(queryString, connection);
                command.Parameters.AddWithValue("@parametar", paramValue);
                // Open the connection in a try/catch block. 
                try
                {
                    connection.Open();
                    trn = connection.BeginTransaction(System.Data.IsolationLevel.ReadCommitted);
                    command.Transaction = trn;
                    command.CommandTimeout = 0; //no limits
                    command.ExecuteNonQuery();
                    if ( Debugger.IsAttached)
                        Debugger.Break();
                    //running transaction
                    trn.Commit();
                }
                catch (Exception ex)
                {
                    trn.Rollback();
                    Console.WriteLine(ex.Message);
                }
                Console.ReadLine();
            }

        }

    }
}
