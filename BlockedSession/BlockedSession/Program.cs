using BlockedSession.ConfigHelper;
using System;
using System.Data.SqlClient;

namespace BlockedSession
{
    class Program
    {
        static void Main(string[] args)
        {
            string connectionString = UserInfo.InjectInformationAboutUser(DVConfiguration.myConnString);
            // Provide the query string with a parameter placeholder.
            string queryString = @"--Trying to select one record" + "\r\n"
                        + "SELECT * FROM Person.Person "
                    + "WHERE BusinessEntityID = @parametar";
            // Specify the parameter value.
            int paramValue = 1;
            // Create and open the connection in a using block. This
            // ensures that all resources will be closed and disposed
            // when the code exits.
            using (SqlConnection connection =
                new SqlConnection(connectionString))
            {

                // Create the Command and Parameter objects.
                SqlCommand command = new SqlCommand(queryString, connection);
                command.Parameters.AddWithValue("@parametar", paramValue);
                command.CommandTimeout = 0; //no limits
                // Open the connection in a try/catch block. 
                try
                {
                    connection.Open();
                    command.ExecuteNonQuery();
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.Message);
                }
                Console.ReadLine();
            }

        }
    }
}
