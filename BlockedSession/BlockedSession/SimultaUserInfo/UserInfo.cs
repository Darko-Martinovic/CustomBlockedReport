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
                    s += "\\Luka Modric(LModric)";
                }
                else if (id == 2)
                {
                    s += "\\Ivan Perisic(IPerisic)";
                }
                else if (id == 3)
                {
                    s += "\\Sandra Perkovic(SPerkovic)";
                }
                else if (id == 4)
                {
                    s += "\\Sara Kolak(SKolak)";
                }
                else if (id == 5)
                {
                    s += "\\Blanka Vlasic(BVlasic)";
                }
                else if (id == 6)
                {
                    s += "\\Stipe Zunic(SZunic)";

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
