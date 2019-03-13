using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common
{
    public class Lot
    {
        public Lot()
        {
            Id = 0;
            Lot1Name = "";
            LotInfo = ""; 
        }

        public int Id { get; set; }
        public string Lot1Name { get; set; }
        public string Lot2Name { get; set; }
        public string LotInfo { get; set; }
    }
}
