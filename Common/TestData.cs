using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common
{
    public class TestData
    {
        private string TestWords = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum";
        private List<string> words;
        private int maxword;
        private System.Random random;

        public TestData()
        {
            random = new Random();
            words = TestWords.Split(' ').ToList();
            maxword = words.Count - 1;
        }

        public LogEntry GetNewLogEntry(string eventType = "L")
        {
            return new LogEntry()
            {
                EventDateTime = DateTime.Now,
                EventType = eventType,
                Message = string.Join(" ", Enumerable.Range(5, random.Next(10, 50))
                                                     .Select(x => words[random.Next(0, maxword)]).ToArray()),
            };
        }
    }
}
