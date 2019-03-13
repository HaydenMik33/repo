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
    public class Evatec : Tool
    {
        #region Initialize events and SVID values that are always tool-specific
        private string ControlStateLocalCEID = "2";
        private string ControlStateRemoteCEID = "3";
        private string ControlStateOfflineCEID = "1";
   
        protected override void InitializeHardcodedEvents()
        {
            ProcessStateChangeCEID = "10";
            for (int ii=10; ii <= 21; ii++)
            {
                OtherProcessStateChangeCEID.Add(ii.ToString());
            }
            OtherProcessStateChangeCEID.Add("30");

            ProcessCompletedCEID.Add("101");
            ProcessStartedCEID.Add("100");
        }

        protected override void InitializeControlStates()
        {
            ControlStateDict.Add(1, new ControlState(ControlStates.OFFLINE, 
                 "Off-Line/Equipment Off-Line"));
            ControlStateDict.Add(2, new ControlState(ControlStates.OFFLINE,
                 "Off-Line/Attempt On-Line"));
            ControlStateDict.Add(3, new ControlState(ControlStates.OFFLINE,
                  "Off-Line/Host Off-Line"));
            ControlStateDict.Add(4, new ControlState(ControlStates.LOCAL,
                  "On-Line/Local"));
            ControlStateDict.Add(5, new ControlState(ControlStates.REMOTE,
                  "On-Line/Remote"));
        }
        protected override void InitializeProcessStates()
        {
            ProcessStateDict.Add(0, new ProcessState(ProcessStates.NOTREADY,
                  "Off"));
            ProcessStateDict.Add(1, new ProcessState(ProcessStates.READY,
                 "Setup"));
            ProcessStateDict.Add(2, new ProcessState(ProcessStates.READY,
                 "Ready"));
            ProcessStateDict.Add(3, new ProcessState(ProcessStates.EXECUTING,
                  "Executing"));
            ProcessStateDict.Add(4, new ProcessState(ProcessStates.WAIT,
                  "Wait"));
            ProcessStateDict.Add(5, new ProcessState(ProcessStates.ABORT,
                  "Abort"));
        }
        protected override void InitializeHostCommandAckDict()
        {
            string[] dictEntries = new string[] { "00", "OK",
                "01", "Invalid command",
                "02", "Cannot perform now",
                "03", "At least one parameter is invalid",
                "04", "Will do later",
                "05", "Already in desired position",
                "40", "Control state is local",
                "41", "Incorrect Process State for this command",
                "42", "Bad PPID",
                "43", "Process Program not found",
                "44", "Too many Lot ID Parameters specified",
                "80", "Command Confirmation Timeout",
                "81", "One or more Load ports, defined in PP-SELECT, are already in use",
                "82", "Command rejected; SECS/GEM disabled",
                "83", "No Carrier defined",
                "90", "Job with lot id not found",
                "91", "Command not allowed"};
            for (int ii = 0; ii < dictEntries.Length; ii += 2)
            {
                HostCommandAckDict.Add(dictEntries[ii], dictEntries[ii + 1]);
            }
        }
        #endregion
        public Evatec()
              : base()
        {
        }
        #region Overrides to specific SECS messages
        override protected bool SendEnableAlarms()
        {
            S5F3 s5f3 = new S5F3(CurrentToolConfig.Toolid);
            s5f3.setALED("01", DataType.BOOL);

            if (CurrentToolConfig.EnableAllAlarms)
            {
                s5f3.setALIDEmptyType(DataType.UI4);
            } else {
                foreach (var alarm in CurrentToolConfig.AlarmList)
                {
                    s5f3.addALID(alarm.id.ToString(), DataType.UI4);
                }
            }
            try
            {
                MyLog.Information("H->E Sending S5F3 to enable " + (CurrentToolConfig.EnableAllAlarms ? "all" :
                    CurrentToolConfig.AlarmList.Length.ToString()) + " alarms");
                s5f3.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                MyLog.Information("S5F3 returned ACKC5=" + s5f3.ACKC5);

                if (ToolUtilities.checkAck(s5f3.ACKC5))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("S5F3 enable alarms", false, e);
                return false;
            }

        }

        #endregion
        #region Recipe selection and start processing messages
        public override bool DoSelectRecipe(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {
            char[] trimChars = new char[] { ',' };

            if (LotIds == null || Recipe == null)
            {
                errorMessage = "HCMD for PP-SELECT cannot be run--no LotIds or Recipe were supplied";
                Messenger.Default.Send(new EventMessage(DateTime.Now, "E", errorMessage));
                MyLog.Information(errorMessage);

                return false;
            }

            Messenger.Default.Send(new ProcessStateChangeMessage(ProcessStates.READY, "Selecting recipe"));


            StringBuilder logMessage = new StringBuilder("Sending HCMD PP-SELECT with recipe " + Recipe + " lot IDs ");
            S2F41 hostCommandMessage = new S2F41(CurrentToolConfig.Toolid);
            hostCommandMessage.SetRCMD("PP-SELECT", DataType.ASC);
            hostCommandMessage.addCp("PPID", DataType.ASC, Recipe, DataType.ASC);
            hostCommandMessage.addCp("OPERATORID", DataType.ASC, Operator, DataType.ASC);

            // BatchID length must be <= 20, so remove leading "B_"
            string batch = "";
            for(int i=0; i < LotIds.Length; i++)
            {
                if (i > 0)
                    batch += "_";
                batch += LotIds[i];
            }

            //foreach (string lotId in LotIds)
            //{
            //    if (lotId != null && lotId.Trim().Length > 0)
            //    {
            //        batch += "_" + lotId;
            //    }
            //}
            MyLog.Information($"BATCHID={batch}");

            hostCommandMessage.addCp("BATCHID", DataType.ASC, batch, DataType.ASC);

            int lotSuffix = 1;
            foreach (string lotId in LotIds)
            {
                if (lotId != null && lotId.Trim().Length > 0)
                {
                    hostCommandMessage.addCp("LOTID" + lotSuffix++, DataType.ASC, lotId, DataType.ASC);
                    logMessage.Append(lotId);
                    logMessage.Append(",");
                }
            }
            try
            {
                Messenger.Default.Send(new EventMessage(new LogEntry(logMessage.ToString().TrimEnd(trimChars))));
                MyLog.Information(logMessage.ToString().TrimEnd(trimChars));

                hostCommandMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(hostCommandMessage.HCACK, new String[] { "0", "00", "04" }))
                {
                    MyLog.Information("HCMD for PP-SELECT returned good HCACK");
                    errorMessage = "";
                    return true;
                }
                else
                {
                    errorMessage = "HCMD for PP-SELECT returned bad HCACK " + hostCommandMessage.HCACK + " - " +
                        (HostCommandAckDict.ContainsKey(hostCommandMessage.HCACK) ? HostCommandAckDict[hostCommandMessage.HCACK] :
                        "Undefined HCACK");
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", errorMessage));
                    MyLog.Information(errorMessage);
                    return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("HCMD (S2F41) PP-SELECT", true, e);
                errorMessage = "Error sending HCMD (S2F41) PP-SELECT to tool";
                return false;
            }
        }
        protected override bool DoToolSpecificStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        { 
            // RCMD = START
            S2F41 hostCommandMessage = new S2F41(CurrentToolConfig.Toolid);
            hostCommandMessage.SetRCMD("START", DataType.ASC);
            try
            {
                MyLog.Information("Sending HCMD START");

                hostCommandMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(hostCommandMessage.HCACK))
                {
                    MyLog.Information("HCMD for START returned good HCACK");
                    errorMessage = "";
                }
                else
                {
                    errorMessage = "HCMD for START returned bad HCACK " + hostCommandMessage.HCACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", errorMessage));
                    MyLog.Information(errorMessage);

                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("HCMD (S2F41) START", true, e);
                errorMessage = "Error sending HCMD for START";
                return false;
            }

            return true;
        }
        #endregion

        #region React to various tool state change messages
        public override bool PossiblyHandleControlStateChangeEvent(string CEID)
        {
            ControlState newControlState = null;
            if (CEID == ControlStateLocalCEID)
            {
                newControlState = ControlStateDict[4];  //TODO: get rid of magic numbers
            } else if (CEID == ControlStateOfflineCEID)
            {
                newControlState = ControlStateDict[1];
            } else if (CEID == ControlStateRemoteCEID)
            {
                newControlState = ControlStateDict[5];
            }
            if (newControlState != null)
            {
                Messenger.Default.Send(new ControlStateChangeMessage(newControlState.State, newControlState.Description));
                MyLog.Information("Control State changed to " + newControlState.Description);
                return true;
            } else
            {
                return false;
            }
        }
        #endregion

        #region Hooks for custom code performed at process started and completed. These might be moved
        public override void DoToolSpecificProcessStarted(S6F11 eventMessage) { }

        public override void DoToolSpecificProcessCompleted(S6F11 eventMessage)
        {
            uploadData.Clear();
            // For now, I'm just handling the process completed event. Later, this will be modified ot happen with any
            // event, not just process completed.
            Dictionary<string, string> nameToCamstarName = new Dictionary<string, string>();
            foreach (ToolConfigItem configItem in CurrentToolConfig.EndOfRunDataCollectionItems)
            {
                if (configItem.type.Equals("ERDATA", StringComparison.CurrentCultureIgnoreCase))
                {
                    nameToCamstarName.Add(configItem.name, configItem.camstarName);
                }
            }
            foreach (List<SECSData> report in eventMessage.Reports.Values)
            {
                foreach (SECSData vidData in report)
                {
                    if (vidData.Name != null && nameToCamstarName.ContainsKey(vidData.Name)) { 
                        uploadData.Add(nameToCamstarName[vidData.Name], vidData.Value);
                    }
                }
            }
        }
        #endregion

    }
}
