using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace ToolService.UnitTests
{
    class Program
    {
        static void Main(string[] args)
        {
            Thread.Sleep(7000);
            var tool = new EvatecTests();
            tool.SetUp();
            tool.Initialize_WhenCalled_InitializationSucceeds();
            Console.WriteLine("Success!");
        }
    }
}
