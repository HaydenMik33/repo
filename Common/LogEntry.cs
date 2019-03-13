using Serilog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Common.Globals;
using GalaSoft.MvvmLight.Messaging;


namespace Common
{
    public class LogEntry
    {
        public LogEntry() { }
        public LogEntry(string Message)
        {
            EventDateTime = DateTime.Now;
            EventType = "L";
            this.Message = Message;

            SendEmail = false;
        }
        public LogEntry(string Message, bool sendEmail) : this(Message)
        {
            SendEmail = sendEmail;
        }

        public DateTime EventDateTime { get; set; }
        public string EventType { get; set; }
        public string Message { get; set; }

        public bool SendEmail { get; set; }

    }
 
    public class FASLog
    {
        // TODO: Log naming convention
        public FASLog(string logFile = @"C:\Logs\Log.Txt")
        {
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Debug()
                .WriteTo.Console()
                .WriteTo.File(logFile,
                    rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level}] {Message}{NewLine}{Exception}",
                    rollOnFileSizeLimit: true)
                .CreateLogger();

            //Messenger.Default.Register<EventMessage>(this, EventMessageHandler);
        }

        public void Debug(string debugText)
        {
            Log.Debug(debugText);
            Messenger.Default.Send(new EventMessage(new LogEntry(debugText)));
        }
        public void Debug(string debugText, bool sendEmail)
        {
            Log.Debug(debugText);
            Messenger.Default.Send(new EventMessage(new LogEntry(debugText,sendEmail)));
        }

        public void Information(string infoText)
        {
            Log.Information(infoText);
            Messenger.Default.Send(new EventMessage(new LogEntry(infoText)));
        }

        public void Information(string infoText, bool sendEmail)
        {
            Log.Information(infoText);
            Messenger.Default.Send(new EventMessage(new LogEntry(infoText,sendEmail)));
        }

        public void Warning(string warningText)
        {
            Log.Warning(warningText);
            Messenger.Default.Send(new EventMessage(new LogEntry(warningText)));

        }
        public void Warning(string warningText, bool sendEmail)
        {
            Log.Warning(warningText);
            Messenger.Default.Send(new EventMessage(new LogEntry(warningText, sendEmail)));

        }

        public void Error(string errorText)
        {
            Log.Error(errorText);
            Messenger.Default.Send(new EventMessage(new LogEntry(errorText,true)));

        }
        public void Error(string errorText, bool sendEmail)
        {
            Log.Error(errorText);
            Messenger.Default.Send(new EventMessage(new LogEntry(errorText, sendEmail)));

        }

        public void Error(Exception ex, string errorText)
        {
            Log.Error(ex, errorText);
        }

      


        //private void EventMessageHandler(EventMessage msg)
        //{
        //    if (msg.MsgType == "L")
        //    {
        //        Log.Information(msg.Message);
        //    }
        //}

    }
    }
