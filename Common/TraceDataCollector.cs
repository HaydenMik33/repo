using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Common.Globals;
using SECSInterface;
using GalaSoft.MvvmLight.Messaging;

namespace Common
{
    public class TraceDataCollector
    {



        public string OutFileName { get; set; }
        public FileStream TraceFile { get; set; }

        public bool HeaderWritten { get; set; }

        public long EpochTime { get { return CurrentMillis.Millis; } }

        protected TraceDataCollector()
        {
            HeaderWritten = false;
        }
        public TraceDataCollector(string Port, string[] LotIds, string recipe) : this()
        {

            string path = CurrentToolConfig.TraceLogFilesPath;
            if (path == null || recipe == null || LotIds.Length < 1)
            {
                MyLog.Error("Missing port, or lotIds or recipe name for creating trace data filename");
                return;
            }

            string timeString = DateTime.Now.ToString("yyyyMMddHHmmss");

            string traceLogFileName = timeString + "-";
            foreach (var lot in LotIds)
                { if (lot != null)
                        traceLogFileName = traceLogFileName + lot + "-";
                }

            traceLogFileName = traceLogFileName + recipe + ".csv";

            OutFileName = path + "\\" + traceLogFileName;

            try
            {   FileStream fs = new FileStream(OutFileName, FileMode.Create);
                TraceFile = fs;
            }
            catch (Exception ex)
            {
                string message = "Trace Data Collector: " + ex.Message;
                Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                MyLog.Information(message);
            }

        }

       
        public void AddData(S6F1 traceReport, ToolConfigReportVid[] vids)
        {
            if (traceReport == null)
                return;

            if (TraceFile == null)
                return;

            string traceId = traceReport.TRID;

            if (!HeaderWritten)
                WriteHeader(vids);
      
            string lineToWrite = EpochTime.ToString();
            for (int index = 0; index < traceReport.SV.Count; index++)
            {
                string dataVal = traceReport.SV[index].Value;
                if (dataVal == null)
                    dataVal = "";
                lineToWrite = lineToWrite + "," + dataVal.ToString();
            }
            lineToWrite = lineToWrite + "\n";

            Byte[] byteArr = Encoding.UTF8.GetBytes(lineToWrite);
            int len = Encoding.UTF8.GetByteCount(lineToWrite);

            TraceFile.Write(byteArr, 0, len);

        }

        public void WriteHeader(ToolConfigReportVid[] vids)
        {
            string headerString = "TimeStamp";
            for (int index = 0; index < vids.Length; index++)
            {
                headerString = headerString + "," + vids[index].name;
             }
            headerString = headerString + "\n";

            Byte[] byteArr = Encoding.UTF8.GetBytes(headerString);
            int len = Encoding.UTF8.GetByteCount(headerString);

            TraceFile.Write(byteArr, 0, len);

            HeaderWritten = true;
        }

        public void CloseDataFile()
        {
            if (TraceFile != null)
            {
                TraceFile.Close();
                TraceFile = null;
            }
        }

    }


    static class CurrentMillis
    {
        private static readonly DateTime Jan1St1970 = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        /// <summary>Get extra long current timestamp</summary>
        public static long Millis { get { return (long)((DateTime.UtcNow - Jan1St1970).TotalMilliseconds); } }
    }

}

