
using System.Collections.Generic;

namespace ToolService
{
    public class Port
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public List<Cassette> Cassettes { get; set; }

        public List<Slot> Slots { get; set; }

    }
}