using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common
{
    public interface IEquipmentMessages
    {
        bool AreYouThere(object equipmentId);
        void SendOnLine();
        void SendOffLine();
        DateTime GetDateTime();
        string InitiateTrace();
        void StopTrace();
        string RequestStatus();
        string ReadEquipmentConstants(); 
        // more to come

    }
}
