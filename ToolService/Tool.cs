using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Threading;
using System.Timers;
using Serilog;
using AutoShellMessaging;
using Common;
using GalaSoft.MvvmLight.Messaging;
using SECSInterface;
using static Common.Globals;


namespace ToolService
{
    public abstract class Tool : AshlMessageHandler
    {
        private char[] trimChars = new char[] { ',', '\n'};

        public string EqSrv { get; set; }
        private bool needCommunicate;
        private bool haveAreYouThere;
        private int communicateRate = 10000;    // X milliseconds until success, then stops
        private int areYouThereRate = 60000;   // After communicate succeeds, every X milliseconds
        private Timer toolCheckTimer;
        volatile bool inWork = false;
        protected volatile ControlStates currentControlState = ControlStates.UNDEFINED;
        protected volatile ProcessStates currentProcessState = ProcessStates.UNDEFINED;

        #region Just some convenient collections and variables to prevent having to go to configuration all the time
        protected Dictionary<int, ControlState> ControlStateDict = new Dictionary<int, ControlState>();
        protected Dictionary<int, ProcessState> ProcessStateDict = new Dictionary<int, ProcessState>();
        protected Dictionary<string, List<ToolConfigReport2>> EventReportDict = new Dictionary<string, List<ToolConfigReport2>>();
        protected Dictionary<string, string> EventIdToNameDict = new Dictionary<string, string>();
        protected Dictionary<string, ToolConfigReportVid[]> TraceReportDict = new Dictionary<string, ToolConfigReportVid[]> ();
        protected Dictionary<string, string> HostCommandAckDict = new Dictionary<string, string>();
        protected string ProcessStateChangeCEID { get; set; }
        protected List<string> OtherProcessStateChangeCEID = new List<string>();
        protected string ToolConfigProcessStateReport { get; set; }
        protected int ToolConfigProcessStateVIDIndex { get; set; }
        protected List<String> ProcessCompletedCEID = new List<string>();
        protected List<String> ProcessStartedCEID = new List<string>();
        protected Dictionary<string, string> uploadData = new Dictionary<string, string>();
        #endregion

        #region Superclass constructor and ACI comm startup, common to all tools
        /// <summary>
        /// Initialization that is probably common to all tools. I expect the tool-specific class to call
        /// this constructor.
        /// </summary>
        protected Tool()
        {
            InitializeControlStates();
            InitializeProcessStates();
            InitializeHardcodedEvents();
            InitializeHostCommandAckDict();
            InitializeConfiguredEventsAndReports();
            InitializeTraceReportDict();
            EqSrv = CurrentToolConfig.Toolid + "srv";

            SetUpComms();
        }

        // Initialize AutoShell (register my name with the nameserver). If this fails, there is no use in
        // the UI doing anything else because all of it will fail, too.
        private void SetUpComms()
        {
            string AciConf = CurrentSystemConfig.ACINameServerHost + ":" + CurrentSystemConfig.ACINameServerPort;

#if DEBUG
            AciConf = System.Environment.GetEnvironmentVariable("COMPUTERNAME") + ":1500";
#endif

            string MyName = System.Environment.GetEnvironmentVariable("COMPUTERNAME") + "FAS";
            MessagingSettings _messagingSettings = new MessagingSettings()
            {
                //TODO CHange to using SystemConfig
                AciConf = AciConf,
                CheckDuplicateRegistration = true,
                UseInterfaceSelectionMethod = InterfaceSelectionMethod.DISCOVER,                 
                Name = MyName
            };

            // Instantiate an AshlServerLite instance
            AshlServer = AshlServerLite.getInstanceUsingParameters(_messagingSettings);
            AshlServer.registerHandler(this);

            AshlMessage monitorMessage = AshlMessage.newInstanceCommand(EqSrv, "fr=" + MyName + " to=" + EqSrv + " eq=" + CurrentToolConfig.Toolid + " do=monitor all", 20);
            monitorMessage.send();

            if (!AshlServer.isActive())
            {
                Messenger.Default.Send(new EventMessage(DateTime.Now, "E", "Unable to start tool communications with name '" + MyName + "' ACI_CONF '" + AciConf));

            }
            else
            {
                MyLog.Information("Listening for tool messages as '" + MyName);
             }

        }
        #endregion

        #region Initialize tool-type specific variables; Sub-class must implement
        /// <summary>
        /// Set up the Control State dictionary
        /// </summary>
        protected abstract void InitializeControlStates();
        /// <summary>
        /// Set up the Process State dictionary
        /// </summary>
        protected abstract void InitializeProcessStates();
        protected abstract void InitializeHardcodedEvents();
        protected abstract void InitializeHostCommandAckDict();
        #endregion

        #region Initialize dictionaries of events and traces to simplify the handling of incoming event report and trace messages
        /// <summary
        /// Reformat the reports in ToolConfig to make them indexed by event ID, for easier 
        /// use in the incoming event handler.
        /// It will also set up the ToolConfigProcessStateReport and ToolConfigProcessStateVIDIndex variables.
        /// </summary>
        private void InitializeConfiguredEventsAndReports()
        {

            foreach (ToolConfigReport2 configReport in CurrentToolConfig.eventReports)
            {
                foreach (ToolConfigReportCeid ceid in configReport.events)
                {
                    if (EventReportDict.ContainsKey(ceid.Value.ToString()))
                    {
                        EventReportDict[ceid.Value.ToString()].Add(configReport);
                    }
                    else
                    {
                        List<ToolConfigReport2> reports = new List<ToolConfigReport2>();
                        reports.Add(configReport);
                        EventReportDict.Add(ceid.Value.ToString(), reports);
                        EventIdToNameDict.Add(ceid.Value.ToString(), ceid.name);
                    }
                    try
                    {
                        // This stuff happens until we find a the ProcessStateChangeCEID. Then it is skipped.
                        if (ToolConfigProcessStateReport == null && ulong.Parse(ProcessStateChangeCEID) == ceid.Value) { }
                        {
                            foreach (ToolConfigReport2 report in EventReportDict[ceid.Value.ToString()])
                            {
                                for (int index = 0; index < report.vids.Length && ToolConfigProcessStateReport == null; index++)
                                {
                                    if (report.vids[index].Value == CurrentToolConfig.ProcessStateSVID)
                                    {
                                        ToolConfigProcessStateReport = report.id.ToString();
                                        ToolConfigProcessStateVIDIndex = index;
                                    }
                                }
                                if (ToolConfigProcessStateReport != null)
                                {
                                    break;
                                }
                            }
                        }
                    }
                    catch (Exception)
                    {
                        // Probably not interesting; we have a backup plan
                    }
                }
            }
        }
        private void InitializeTraceReportDict()
        {
            foreach (ToolConfigReport trace in CurrentToolConfig.TraceReports)
            {
                TraceReportDict.Add(trace.id.ToString(), trace.vids);
            }
        }
        #endregion

        #region Start up the timers to check the tool and, if communications are established, complete tool initialization
        /// <summary>
        /// Perform the tool initialization sequence (typically, S1F13, S1F1 and S1F3 status query for control state and process State
        /// </summary>
        /// <returns></returns>
        public virtual bool Initialize()
        {
            needCommunicate = true;
            haveAreYouThere = false;
            toolCheckTimer = new Timer(200);
            object thisClass = this;
            inWork = false;
            toolCheckTimer.Elapsed += toolCheck_Tick;
            toolCheckTimer.AutoReset = false;
            toolCheckTimer.Enabled = true;
            
             return true;
        }
        private void toolCheck_Tick(object sender, EventArgs e)
        {
            if (!inWork)    // This flag is a bit of a hack. Even though the timer has AutoReset = false, it still reenables when I change
            {               // the interval.  This hack prevents repeated sending S1F13 while the first one is timing out.
                inWork = true;
                toolCheckTimer.Enabled = false;
                if (needCommunicate)
                {
                    toolCheckTimer.Interval = communicateRate;
                    if (SendCommunicate())
                    {
                        needCommunicate = false;
                        haveAreYouThere = false;
                    }
                    else
                    {
                        Messenger.Default.Send(new ControlStateChangeMessage(ControlStates.OFFLINE, "Error communicating to tool"));
                        // Stop right here - do communicate again in 10 seconds
                        inWork = false;
                        toolCheckTimer.Enabled = true;
                        return;
                    }
                }
                if (SendAreYouThere(haveAreYouThere))   // THe argument prevents redundant logging if you already have it
                {
                    if (!haveAreYouThere)
                    {
                        // areyouthere state has changed from BAD/UNKNOWN to GOOD; finish initialization
                        haveAreYouThere = true;
                        toolCheckTimer.Interval = areYouThereRate; 
                        CompleteInitialization();
                    } else
                    {
                        // This is somewhat unnecessary, but lets us dynamically watch for state changes even if no events have been enabled.
                        QueryProcessAndControlState(out ControlState newControlState, out ProcessState newProcessState);
                    }
                }
                else
                {
                    Messenger.Default.Send(new ControlStateChangeMessage(ControlStates.OFFLINE, "Error communicating to tool"));
                    haveAreYouThere = false;
                    needCommunicate = true;
                    toolCheckTimer.Interval = communicateRate; 
                }
                inWork = false;
                toolCheckTimer.Enabled = true;
            }
        }
        private void CompleteInitialization()
        {
            ControlState controlState = null;
            ProcessState processState = null;
            if (QueryProcessAndControlState(out controlState, out processState))
            {
                if (controlState.State == ControlStates.LOCAL)
                {
                    SendGoRemote();
                }
                if (controlState.State == ControlStates.LOCAL || controlState.State == ControlStates.REMOTE)
                {
                    GetRecipeListFromTool();
                    if (SendEnableAlarms())
                    {
                         // Initialization succeeded!
                        MyLog.Information("Initialization sequence was successful.");
                    }
                    else
                    {
                        // This should already be logged so I'll let it pass here?
                    }
                }
            }
            else
            {
                Messenger.Default.Send(new ControlStateChangeMessage(ControlStates.OFFLINE, "Error getting tool status"));
            }

        }
 
        /// <summary>
        /// This method will work for any tools that have one variable for control state and one for process state.
        /// If you need more than one, you will need to override it.
        /// </summary>
        /// <param name="newControlState"></param>
        /// <param name="newProcessState"></param>
        /// <returns></returns>
        public virtual bool QueryProcessAndControlState(out ControlState newControlState, out ProcessState newProcessState)
        {
            newControlState = new ControlState(ControlStates.UNDEFINED, "Undefined");
            newProcessState = new ProcessState(ProcessStates.UNDEFINED, "Undefined");
            S1F3 s1f3 = new S1F3(CurrentToolConfig.Toolid);
            s1f3.addSVID(CurrentToolConfig.ControlStateSVID.ToString(), DataType.U4, "ControlStateSVID");
            s1f3.addSVID(CurrentToolConfig.ProcessStateSVID.ToString(), DataType.U4, "ProcessStateSVID");
            try
            {
                MyLog.Information("Sending tool status query for SVID " + CurrentToolConfig.ControlStateSVID + ", " +
                    CurrentToolConfig.ProcessStateSVID);
                s1f3.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                int controlState;
                int processState;

                if (s1f3.SV.Count != 2)
                {
                    MyLog.Warning("Status query response did not include expected values.");
                    return false;
                }

                if (s1f3.SV[0].Type == DataType.L)
                {
                    MyLog.Warning("The configured SVID '" + CurrentToolConfig.ControlStateSVID + "' for Control State is not recognized by the tool");
                    return false;
                }
                else
                {
                    controlState = Int32.Parse(s1f3.SV[0].Value);
                }

                if (s1f3.SV[1].Type == DataType.L)
                {
                    MyLog.Warning("The configured SVID '" + CurrentToolConfig.ProcessStateSVID + "' for Process State is not recognized by the tool");
                    return false;
                }
                else
                {
                    processState = Int32.Parse(s1f3.SV[1].Value);
                }

                if (ControlStateDict.ContainsKey(controlState))
                {
                    newControlState = ControlStateDict[controlState];
                    if (newControlState.State != currentControlState)
                    {
                        Messenger.Default.Send(new ControlStateChangeMessage(newControlState.State, newControlState.Description));
                        MyLog.Debug("Control State changed to " + newControlState.Description);
                        currentControlState = newControlState.State;
                    }
                }
                else
                {
                    MyLog.Warning("Control State changed to undefined state " + controlState);
                    currentControlState = ControlStates.UNDEFINED;
                }
                if (ProcessStateDict.ContainsKey(processState))
                {
                    newProcessState = ProcessStateDict[processState];
                    if (newProcessState.State != currentProcessState)
                    {
                        Messenger.Default.Send(new ProcessStateChangeMessage(newProcessState.State, newProcessState.Description));
                        currentProcessState = newProcessState.State;
                    }
                }
                else
                {
                    MyLog.Warning("Process State changed to undefined state " + processState);
                    currentProcessState = ProcessStates.UNDEFINED;
                }
                MyLog.Debug("Status query returned Control State '" + controlState + "' Process State '" + processState + "'");
                return true;
            }
            catch (BoundMessageTimeoutException)
            {
                MyLog.Warning("Tool status query (S1F3) timed out.");
            }
            catch (BoundMessageSendException e)
            {
                MyLog.Warning("Tool status query (S1F3) failed - " + e.Message);
            }
            catch (Exception e)
            {
                MyLog.Warning("Unexpected error in tool status query (S1F3); " + e.Message);
            }
            return false;
        }
        #endregion
 
        #region Methods called from the UI as defined in ISECSHandler
        public virtual bool ReadyToStart()
        {
            ControlState controlState = null;
            ProcessState processState = null;
            if (QueryProcessAndControlState(out controlState, out processState))
            {
                return (controlState.State == ControlStates.REMOTE) && (processState.State == ProcessStates.READY);
            }
            else
            {
                return false;
            }
        }
 
        public virtual bool SendGoLocal()
        {
            return sendRemoteCommand("LOCAL");
        }

        public virtual bool SendGoRemote()
        {
            return sendRemoteCommand("REMOTE");
        }

        public virtual bool SendPause()
        {
            return sendRemoteCommand("WAIT");
        }

        public virtual bool SendResume()
        {
            return sendRemoteCommand("CONTINUE");
        }
        public virtual bool SendNext()
        {
            return sendRemoteCommand("NEXT");
        }
        public virtual bool SendReload()
        {
            return sendRemoteCommand("RELOAD");
        }

        /// <summary>
        /// Can be overridden if this is not the normal behavior.
        /// </summary>
        /// <returns></returns>
        public virtual bool SendStop()
        {
            return sendRemoteCommand("STOP");
        }
        /// <summary>
        /// Can be overridden if this is not the normal behavior.
        /// </summary>
        /// <returns></returns>
        public virtual bool SendAbort()
        {
            return sendRemoteCommand("ABORT");
        }

        /// <summary>
        /// Send an HCMD and return good if success.
        /// </summary> 
        /// <remarks>
        /// I'm not sure if this will need to be overridden for specific tools yet.
        /// </remarks>
        /// <param name="command"></param>
        /// <returns></returns>
        protected virtual bool sendRemoteCommand(string command)
        {
             S2F41 hostCommandMessage = new S2F41(CurrentToolConfig.Toolid);
            hostCommandMessage.SetRCMD(command, DataType.ASC);
            try
            {
                MyLog.Information("H->E Sending HCMD " + command);
 
                hostCommandMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(hostCommandMessage.HCACK))
                {
                    MyLog.Information("HCMD for " + command + " returned good HCACK");
                    return true;
                }
                else
                {
                    string message = "HCMD for " + command + " returned bad HCACK " + hostCommandMessage.HCACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                     return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("HCMD (S2F41) " + command + " failed: ", true, e);
                return false;
            }
        }
        public bool DoPreprocessing()
        {
            Messenger.Default.Send(new ProcessStateChangeMessage(ProcessStates.READY, "Setting up tool"));

            uploadData.Clear();
            SendEnableAlarms();

            return DoEventReportSetup(true);
        }
        public abstract bool DoSelectRecipe(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage);
        public virtual bool CreateBatch(string BatchId, string PPID, int ProcessTime, string TableNumber,
           string CarrierID, string MaterialType, int CarrierLocation, int[] SlotStatus) { throw new NotImplementedException("Subclasses must override if needed"); }

        public bool DoStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {
            // This should not be here--leftover debugging? Messenger.Default.Send(new ProcessStateChangeMessage(ProcessStates.READY, "Starting tool"));
            bool reply = DoToolSpecificStartProcessing(Port, LotIds, Recipe, Operator, out errorMessage);
            if (reply) { 
                StartOrStopToolTraces(Port, LotIds, Recipe, true);
            }
           return reply;
        }

        public List<String> RecipeList { get; protected set; }
        public virtual Dictionary<string, string> UploadData()
        {
            List<KeyValuePair<string, string>> ecid = new List<KeyValuePair<string, string>>();
            List<KeyValuePair<string, string>> svid = new List<KeyValuePair<string, string>>();
            foreach (ToolConfigItem configItem in CurrentToolConfig.EndOfRunDataCollectionItems)
            {
                if (configItem.type.Equals("ECID", StringComparison.CurrentCultureIgnoreCase))
                {
                    ecid.Add(new KeyValuePair<string, string>(configItem.id.ToString(), configItem.camstarName));
                }
                else if (configItem.type.Equals("SVID", StringComparison.CurrentCultureIgnoreCase))
                {
                    svid.Add(new KeyValuePair<string, string>(configItem.id.ToString(), configItem.camstarName));
                }
            }

            if (svid.Count > 0)
            {
                S1F3 s1f3 = new S1F3(CurrentToolConfig.Toolid);
                foreach (KeyValuePair<string, string> idAndName in svid)
                {
                    s1f3.addSVID(idAndName.Key, DataType.U4, idAndName.Value);
                }
                try
                {
                    MyLog.Information("Sending tool status query");
                    s1f3.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                    if (s1f3.SV.Count != svid.Count)
                    {
                        MyLog.Warning("Status query response did not include expected values.");
                    }
                    else
                    {
                        int positionInSVIDList = 0;
                        foreach (SECSData toolData in s1f3.SV)
                        {
                            if (toolData.Type == DataType.L)
                            {
                                MyLog.Warning("The configured SVID '" + svid[positionInSVIDList].Key + " is not recognized by the tool");
                            }
                            else
                            {
                                if (!uploadData.ContainsKey(toolData.Name))     // In case they put the same name in configuration twice
                                {
                                    uploadData.Add(toolData.Name, toolData.Value);
                                }
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    ToolUtilities.ReportMessageSendExceptions("S1F3 (status query)", false, e);
                }
            }
            if (ecid.Count > 0)
            {
                S2F13 s2f13 = new S2F13(CurrentToolConfig.Toolid);
                foreach (KeyValuePair<string, string> idAndName in ecid)
                {
                    s2f13.addECID(idAndName.Key, DataType.U4, idAndName.Value);
                }
                try
                {
                    MyLog.Information("Sending tool equipment constant request");
                    s2f13.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                    if (s2f13.ECV.Count != ecid.Count)
                    {
                        MyLog.Warning("Equipment constant response did not include expected values.");
                    }
                    else
                    {
                        int positionInECIDList = 0;
                        foreach (SECSData toolData in s2f13.ECV)
                        {
                            if (toolData.Type == DataType.L)
                            {
                                MyLog.Warning("The configured ECID '" + ecid[positionInECIDList].Key + " is not recognized by the tool");
                            }
                            else
                            {
                                if (!uploadData.ContainsKey(toolData.Name))
                                { // In case they put the same name in configuration twice
                                    uploadData.Add(toolData.Name, toolData.Value);
                                }
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    ToolUtilities.ReportMessageSendExceptions("S2F13 (equipment constant request)", false, e);
                }
            }

            return uploadData;
        }

        #endregion

        #region tooltype-specific behavior to make things happen on the tool
        protected abstract bool DoToolSpecificStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage);
        #endregion

        #region Send Specific SECS messages to the tool and handle replies; can be overridden by tool type but seldom will need to
        protected bool SendAreYouThere(bool isAlreadyLogged)
        {
            S1F1 areYouThereMessage = new S1F1(CurrentToolConfig.Toolid);
            if (! isAlreadyLogged) MyLog.Information("H->E Sending S1F1(areyouthere)");
  
            try
            {
                areYouThereMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);

                if (string.IsNullOrWhiteSpace(areYouThereMessage.MDLN) && !string.IsNullOrWhiteSpace(areYouThereMessage.SOFTREV))
                {
                    if (! isAlreadyLogged) MyLog.Information("S1F1 returned no values for MDLN or SOFTREV");
                 }
                else
                {
                    if (! isAlreadyLogged) MyLog.Information("S1F1 returned MDLN '" + areYouThereMessage.MDLN + "' SOFTREV '" + areYouThereMessage.SOFTREV + "'");
 
                }
                return true;
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("S1F1 (areyouthere)", false, e);
                return false;
            }

        }
        protected bool SendCommunicate()
        {
            S1F13 communicateMessage = new S1F13(CurrentToolConfig.Toolid);
            MyLog.Information("H->E Sending S1F13 (communicate request)");
            try
            {
                communicateMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(communicateMessage.COMMACK))
                {
                    if (string.IsNullOrWhiteSpace(communicateMessage.MDLN) && !string.IsNullOrWhiteSpace(communicateMessage.SOFTREV))
                    {
                        MyLog.Information("S1F13 returned no values for MDLN or SOFTREV");
                     }
                    else
                    {
                        MyLog.Information("S1F13 returned MDLN '" + communicateMessage.MDLN + "' SOFTREV '" + communicateMessage.SOFTREV + "'");
                    }
                    return true;
                }
                else
                {
                    MyLog.Information("S1F13 returned COMMACK=" + communicateMessage.COMMACK);
                    return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("S1F13 (communicate)", false, e);
                return false;
            }
        }
        virtual protected bool SendEnableAlarms()
        {
            S5F3 s5f3 = new S5F3(CurrentToolConfig.Toolid);
            s5f3.setALED("01", DataType.BOOL);

            if (!CurrentToolConfig.EnableAllAlarms)
            {
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
         /// <summary>
        /// Defines, links and optionally enables events and reports
        /// </summary>
        /// <param name="EnableEvents">Set to false to define and link reports but not enable events</param>
        /// <returns>always true for now; we will ignore failures.</returns>
        private bool DoEventReportSetup(bool EnableEvents)
        {
            enableOrDisableEvents("disable events", false);
            linkOrUnlinkEventReports("unlink event reports", false);
            defineOrUndefineReports("undefine event reports", false);
            defineOrUndefineReports("define event reports", true);
            linkOrUnlinkEventReports("link event reports", true);
            if (EnableEvents)
            {
                enableOrDisableEvents("enable events", true);
            }
            return true;
         }
        private bool enableOrDisableEvents(string whereAmI, bool enable)
        {
            StringBuilder logMessage = new StringBuilder();
            S2F37 enableDisableEvents = new S2F37(CurrentToolConfig.Toolid);
            logMessage.Append("H->E Sending " + whereAmI + "; CEID=");
            if (enable)
            {
                enableDisableEvents.setCEED("10", DataType.BOOL);
            }
            else
            {
                enableDisableEvents.setCEED("00", DataType.BOOL);
            }
            foreach (string ceid in EventReportDict.Keys)
            {
                enableDisableEvents.addCEID(ceid, DataType.UI4);
                logMessage.Append(ceid);
                logMessage.Append(",");
            }
            MyLog.Information(logMessage.ToString().TrimEnd(trimChars));
            try
            {
                enableDisableEvents.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(enableDisableEvents.ERACK))
                {
                    return true;
                }
                else
                {
                    string message = "Tool command to " + whereAmI + " (S2F37) returned bad ACK " + enableDisableEvents.ERACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                    return false;
                } 
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions(whereAmI, true, e);
                return false;
            }
        }
        private bool linkOrUnlinkEventReports(string whereAmI, bool link) { 
            StringBuilder logMessage = new StringBuilder();
            S2F35 linkOrUnlinkReports = new S2F35(CurrentToolConfig.Toolid);
            linkOrUnlinkReports.setDATAID("1", DataType.UI4);
            logMessage.Append("H->E Sending " + whereAmI + "; CEID=");
            foreach (string ceid in EventReportDict.Keys)
            {
                List<string> reportIds = new List<string>();
                if (link)
                {
                    foreach (ToolConfigReport2 report in EventReportDict[ceid])
                    {
                        reportIds.Add(report.id.ToString());
                    }
                }
                linkOrUnlinkReports.addCEID(ceid, DataType.UI4, reportIds, DataType.UI4);
                logMessage.Append(ceid);
                logMessage.Append(",");
             }
            try
            {
                linkOrUnlinkReports.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                MyLog.Information(logMessage.ToString().TrimEnd(trimChars));
                if (ToolUtilities.checkAck(linkOrUnlinkReports.LRACK))
                {
                    return true;
                }
                else
                {
                    string message = "Tool command to " + whereAmI + " (S2F35) returned bad ACK " + linkOrUnlinkReports.LRACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                    return false;
                }
            } 
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions(whereAmI, true, e);
                return false;
            }

        }
        private bool defineOrUndefineReports(string whereAmI, bool define)
        {
            StringBuilder logMessage = new StringBuilder();
            S2F33 defineOrUndefineReports = new S2F33(CurrentToolConfig.Toolid);
            defineOrUndefineReports.setDATAID("1", DataType.UI4);
            logMessage.Append("H->E Sending " + whereAmI + "; RPTID=");
            foreach (ToolConfigReport2 eventReport in CurrentToolConfig.eventReports)
            {
                List<string> vids = new List<string>();
                if (define)
                {
                    foreach (ToolConfigReportVid1 vid in eventReport.vids)
                    {
                        vids.Add(vid.Value.ToString());
                    }
                }
                defineOrUndefineReports.addReport(eventReport.id.ToString(), DataType.UI4, vids, DataType.UI4);
                logMessage.Append(eventReport.id);
                logMessage.Append(",");
            }
            try {
                defineOrUndefineReports.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                MyLog.Information(logMessage.ToString().TrimEnd(trimChars));
                if (ToolUtilities.checkAck(defineOrUndefineReports.DRACK))
                {
                    return true;
                }
                else
                {
                    string message = "Tool command to " + whereAmI + " (S2F33) returned bad ACK " + defineOrUndefineReports.DRACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                    return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions(whereAmI, true, e);
                return false;
            }
        }


        private bool StartOrStopToolTraces(string Port, string[] LotIds, string Recipe, bool start)
        {
            foreach (ToolConfigReport trace in CurrentToolConfig.TraceReports)
            {
                S2F23 startTraceMessage = new S2F23(CurrentToolConfig.Toolid);
                startTraceMessage.SetTRID(trace.id.ToString(), DataType.UI4);
                startTraceMessage.SetDSPER(String.Format("{0,6:D6}", trace.dsper), DataType.ASC);  //TODO fix this when tool config corrected
                startTraceMessage.SetREPGSZ("1", DataType.UI4);
                if (start)
                {
                    startTraceMessage.SetTOTSMP(trace.totsmp.ToString(), DataType.UI4);
                    foreach (ToolConfigReportVid vid in trace.vids)
                    {
                        startTraceMessage.addSVID(vid.Value.ToString(), DataType.UI4);
                    }
                }
                else
                {
                    startTraceMessage.SetTOTSMP("0", DataType.UI4);
                }

                string logStartStop = start ? "Start" : "Stop";
                MyLog.Information("H->E " + logStartStop + " trace ID " + trace.id + " with " + trace.vids.Length + " SVIDs");
                try
                {
                    startTraceMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                    if (ToolUtilities.checkAck(startTraceMessage.TIAACK))
                    {
                        MyLog.Information(logStartStop + " Trace ID " + trace.id + " returned good ACK");
  
                    }
                    else
                    {
                        string message = logStartStop + " Trace ID " + trace.id + " failed with ACK=" + startTraceMessage.TIAACK;
                        Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                        MyLog.Information(message);
                        return false;
                    }
                } 
                catch (Exception e)
                {
                   ToolUtilities.ReportMessageSendExceptions(logStartStop, true, e);
                    return false;
                }
            }

            if (start)
                {
                if (TheTraceDataCollector == null)
                    TheTraceDataCollector = new TraceDataCollector(Port, LotIds, Recipe);
                }
            else
                 if (TheTraceDataCollector != null)
                    {
                        TheTraceDataCollector.CloseDataFile();
                        TheTraceDataCollector = null;
                    }

            return true;
        }

        public virtual void GetRecipeListFromTool()
        {
            S7F19 recipeListRequest = new S7F19(CurrentToolConfig.Toolid);
            MyLog.Information("H->E Sending recipe list request");
            try
            {
                recipeListRequest.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (recipeListRequest.PPID == null)
                {
                    MyLog.Warning("Tool returned no recipes to S7F19 query");
                }
                else
                {
                    RecipeList = new List<string>();
                    foreach (SECSData secsData in recipeListRequest.PPID)
                    {
                        RecipeList.Add(secsData.Value);
                    }
                     MyLog.Information("Tool returned " + RecipeList.Count + " recipe names");
                     Messenger.Default.Send(new RecipeListAvailableMessage());
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("recipe list request (S7F19)", true, e);
             }

        }
        #endregion

        #region React to events sent from the tool: Tooltype-specific code that must be implemneted.
        public abstract bool PossiblyHandleControlStateChangeEvent(string CEID);
        public abstract void DoToolSpecificProcessCompleted(S6F11 eventMessage);
        public abstract void DoToolSpecificProcessStarted(S6F11 eventMessage);
        #endregion

        #region React to events sent from the tool: generic code that may or may not need to be overridden
        /// <summary>
        /// See if this CEID is a process state change CEID; if so, see if it has a report that gives us the new
        /// process state; if yes, send notification to the UI.
        /// If it doesn't have a report, query the tool for process state so that the query can send notification to the UI.
        /// <br/><br/>
        /// This can be overridden for tools that have more than one process state change CEID.
        /// </summary>
        /// <param name="CEID"></param>
        /// <param name="eventMessage"></param>
        /// <returns></returns>
        protected virtual bool PossiblyHandleProcessStateChangeEvents(string CEID, S6F11 eventMessage)
        {
            // If this is the CEID for ProcessStateChanged, go see if it has a report containing the processstate
            if (CEID.Equals(ProcessStateChangeCEID) || OtherProcessStateChangeCEID.Contains(CEID))
            {
                string newProcessState = null;

                if (eventMessage.Reports.Count > 0)     //Okay, we have some reports--are any of them the one we want
                {
                    if (ToolConfigProcessStateReport != null && eventMessage.Reports.ContainsKey(ToolConfigProcessStateReport))
                    {
                        if (eventMessage.Reports[ToolConfigProcessStateReport].Count > ToolConfigProcessStateVIDIndex)
                        {
                            SECSData vidValue = eventMessage.Reports[ToolConfigProcessStateReport][ToolConfigProcessStateVIDIndex];
                            newProcessState = vidValue.Value;
                        }
                    }
                }
                // If, after all that, you don't have a newProcessState, you'll have to query the tool.
                if (newProcessState == null)
                {
                    ControlState controlState = null;
                    ProcessState processState = null;
                    QueryProcessAndControlState(out controlState, out processState);  // TODO the code below can be cleaned up now since I'm already checking the dict
                }
                else
                {
                    try
                    {
                        int processState = Int32.Parse(newProcessState);
                        if (ProcessStateDict.ContainsKey(processState))
                        {
                            ProcessState newValue = ProcessStateDict[processState];
                            Messenger.Default.Send(new ProcessStateChangeMessage(newValue.State, newValue.Description));
                            MyLog.Information("Process State changed to " + newValue.Description);
                        }
                        else
                        {
                            string message = "Process State changed to undefined state " + newProcessState;
                            Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                            MyLog.Information(message);

                        }
                    }
                    catch (Exception)
                    {
                        string message = "Process State changed to undefined state " + newProcessState;
                        Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                        MyLog.Information(message);
                    }
                }
                return true;
            }
            else
            {
                return false;
            }
        }
        protected virtual bool PossiblyHandleProcessStartedEvent(string CEID, S6F11 eventMessage)
        {
            if (ProcessStartedCEID.Contains(CEID)) 
            {
                addDvidNames(CEID, eventMessage);
                logEventReportData(CEID, eventMessage);
                Messenger.Default.Send(new ProcessStateChangeMessage(ProcessStates.EXECUTING, "Executing"));
                DoToolSpecificProcessStarted(eventMessage);
                return true;
             }
                else
                {
                return false;
                }
          }
        protected virtual bool PossiblyHandleProcessCompletedEvent(string CEID, S6F11 eventMessage)
        {
            // If this is the CEID for Completed
            if (ProcessCompletedCEID.Contains(CEID))
            {
                MyLog.Information("Processing Completed event (" + CEID + ") received");
  
                StartOrStopToolTraces(null, null, null, false);  // I can do this for Evatec because it only has a single port.

                addDvidNames(CEID, eventMessage);
                logEventReportData(CEID, eventMessage);
                DoToolSpecificProcessCompleted(eventMessage);
                Messenger.Default.Send(new ProcessCompletedMessage("Processing Completed"));
                return true;
            }
            else
            {
                return false;
            }
        }
 
 
        /// <summary>
        /// Adds a name to each DVID in the eventMessage if the DVID was configured in the toolConfig.
        /// This is possible because the DVID is an instance of SECSData which has an optional field, name.
        /// Any code which makes use of these names need to check for null value.
        /// </summary>
        /// <param name="CEID"></param>
        /// <param name="eventMessage"></param>
        private void addDvidNames(string CEID, S6F11 eventMessage)
        {
            if (EventReportDict.ContainsKey(CEID) && eventMessage.Reports != null)
            {
                foreach (KeyValuePair<String, List<SECSData>> toolReport in eventMessage.Reports)
                {
                    // Find the matching report in the configuration
                    foreach (ToolConfigReport2 configReport in EventReportDict[CEID])
                    {
                        if (configReport.id.ToString() == toolReport.Key)
                        {
                             //Found it!  (If not found, just ignore it and leave the name undefined)
                            for (int toolDvidIndex = 0; toolDvidIndex < toolReport.Value.Count && toolDvidIndex < configReport.vids.Length; toolDvidIndex++)
                            {
                                toolReport.Value[toolDvidIndex].Name = configReport.vids[toolDvidIndex].name;
                            }
                            break;
                        }
                    }
                }
            }
        }
        private void logEventReportData(string CEID, S6F11 eventMessage)
        {
            if (EventReportDict.ContainsKey(CEID) && eventMessage.Reports != null)
            {
                StringBuilder stringBuilder = new StringBuilder("H<-E Received event " + CEID + " " + EventIdToNameDict[CEID] + " variables:\n");
                foreach (KeyValuePair<String, List<SECSData>> toolReport in eventMessage.Reports)
                {
                    List<ToolConfigReport2> configReports = EventReportDict[CEID];
                    // Find the matching report in the configuration
                    foreach (ToolConfigReport2 configReport in configReports)
                    {
                        if (configReport.id.ToString() == toolReport.Key)
                        {
                            //Found it!  (If not found, just ignore it. You could log the data but it is meaningless)
                            for (int toolDvidIndex = 0; toolDvidIndex < toolReport.Value.Count && toolDvidIndex < configReport.vids.Length; toolDvidIndex++)
                            {
                                stringBuilder.Append('\t');
                                stringBuilder.Append(String.Format("{0,-8}", configReport.vids[toolDvidIndex].Value));
                                stringBuilder.Append(' ');
                                stringBuilder.Append(String.Format("{0,-28}", configReport.vids[toolDvidIndex].name));
                                stringBuilder.Append(' ');
                                stringBuilder.Append(String.Format("{0,-20}", toolReport.Value[toolDvidIndex].Value));
                                stringBuilder.Append('\n');
                            }
                            break;
                        }
                    }
                }
                MyLog.Information(stringBuilder.ToString().TrimEnd(trimChars));
             }
            else
            {
                MyLog.Information("Received event " + CEID);
            }
        }
        #endregion

        #region Entry point for all incoming messages--sort them out and send them to appropriate handlers
        /// <summary>
        /// This is the entry point for all unsolicited messages from the tool: events, reports, alarms.
        /// </summary>
        /// <param name="message"></param>
        void AshlMessageHandler.handleDataMessage(DecodedMsg message)
        {
            string streamFunction = message.GetValue("SF");
            if (streamFunction != null) {
                switch (streamFunction)
                {
                    case "S5F1":
                        handleAlarm(message);
                        break;
                    case "S6F11":
                        handleEvent(message);
                        break;
                    case "S6F1":
                        handleTrace(message);
                        break;
                    default:
                        //Do nothing
                        break;
                }
            }
        }
        protected virtual void handleAlarm(DecodedMsg message)
        {
            S5F1 alarm = new S5F1(message);
            Messenger.Default.Send(new EventMessage(DateTime.Now, "A", alarm.ALTX + " (alarm ID " + alarm.ALID + ", " + (alarm.ALCD == "80" ? "On)" : "Off)")));
        }
        protected virtual void handleEvent(DecodedMsg message)
        {
            S6F11 eventMessage = new S6F11(message);
            string CEID = eventMessage.CEID;
            // If it's a control state change, handle it below and quit
            if (PossiblyHandleControlStateChangeEvent(CEID))
            {
                return;
            }
            if (PossiblyHandleProcessStateChangeEvents(CEID, eventMessage))
            {
                return;
            }
            if (PossiblyHandleProcessStartedEvent(CEID, eventMessage))
            {
                return;
            }
            if (PossiblyHandleProcessCompletedEvent(CEID, eventMessage))
            {
                return;
            }
            logEventReportData(CEID, eventMessage);

        }
        protected virtual void handleTrace(DecodedMsg message)
        {
            S6F1 traceReport = new S6F1(message);
            string traceId = traceReport.TRID;
            string sampleNumber = traceReport.SMPLN;
            string sampleTimeFromTool = traceReport.STIME;   // We typically ignore this becuase tool clocks drift

            if (TraceReportDict.ContainsKey(traceId))
            {
                ToolConfigReportVid[] vids = TraceReportDict[traceId];
                if (vids.Length != traceReport.SV.Count)
                {
                    MyLog.Information("Trace report " + traceId + " contained invalid SV count; ignoring");
 
                }
                else
                {
                    if (TheTraceDataCollector != null)
                    {
                        TheTraceDataCollector.AddData(traceReport, vids);
                    }
                }

            }
        }


        void AshlMessageHandler.handleUnsolicitedReplyMessage(DecodedMsg message)
        {
            //TODO: log and ignore
        }
        string AshlMessageHandler.handleCommandMessage(DecodedMsg message)
        {
            return "";
        }
        #endregion
    }
   
}

