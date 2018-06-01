using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace BlockedSession.ConfigHelper
{
    static class DVConfiguration
    {
        public static string myConnString = ConfigurationManager.ConnectionStrings["ConnStr"].ConnectionString;

    }
}
