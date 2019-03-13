using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows.Threading;
using AutoShellMessaging;
using Common;
using static Common.Globals;
using GalaSoft.MvvmLight.Messaging;
using SECSInterface;
using Serilog;
using System.Text;

namespace ToolService
{
    public class ToolUtilities
    {
        public static void ReportMessageSendExceptions(string description, bool raiseError, Exception e)
        {
            if (e is BoundMessageTimeoutException)
            {
                string message = "Timeout receiving reply to " + description;
                if (raiseError) Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                MyLog.Information(message);
            }
            else { 
                 if (e is BoundMessageSendException)
                {
                    string message = "Error sending " + description + " message";
                    if (raiseError) Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
               }
                else
                {
                    string message = "Unexpected exception sending " + description + " message; details: " + e.Message;
                    if (raiseError) Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                }
            }

        }

        public static bool checkAck(string ack)
        {
            if (ack != null && (ack.Equals("00") || ack.Equals("0")))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        public static bool checkAck(string ack, string[] goodAcks)
        {
            if (ack != null) {
                foreach (string goodAck in goodAcks)
                {
                    if (goodAck == ack)
                    {
                        return true;
                    }
                }
            }
            return false;
        }
    }

}
