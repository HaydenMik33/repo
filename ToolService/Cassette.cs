using Common;
using System.Collections.Generic;

namespace ToolService
{
    public class Cassette
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public List<Wafer> Wafers { get; set; }

    }
}