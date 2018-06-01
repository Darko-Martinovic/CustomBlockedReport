using System;
public class UserInfo
{
    public static string InjectInformationAboutUser(string inputString)
    {
        string[] connBuilder = inputString.Split(';');
        string replacement = string.Empty;
        foreach (string s1 in connBuilder)
        {
            string s = s1;
            if (s.StartsWith("Application Name"))
            {
                //At this point user is authenticated, so you know his/hers first and last name
                Random rnd = new Random();
                int id = rnd.Next(1, 6);

                if (id == 1)
                {
                    s += "\\Greg Robinson(GRobinson)";
                }
                else if (id == 2)
                {
                    s += "\\John Smith(JSmith)";
                }
                else if (id == 3)
                {
                    s += "\\Mila Jovovic(MJovovic)";
                }
                else if (id == 4)
                {
                    s += "\\Richard Brown(RBrown)";
                }
                else if (id == 5)
                {
                    s += "\\Tom Eliot(TEliot)";
                }
                else if (id == 6)
                {
                    s += "\\Ana Richard(ARichard)";

                }
            }
            replacement += s + ";";

        }
        if (replacement.Length > 1)
        {
            replacement = replacement.Substring(0, replacement.Length - 1);
        }
        return replacement;
    }

}
