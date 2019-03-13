using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Common;
using SECSInterface;
using static Common.Globals;
using GalaSoft.MvvmLight.Messaging;
using AutoShellMessaging;

namespace ToolService
{
    public class Koyo : Tool
    {
        private string ControlStateHostOfflineCEID = "10101";
        private string ControlStateLocalCEID = "10102";
        private string ControlStateRemoteCEID = "10103";
        private string ControlStateEquipmentOfflineCEID = "10104";

        public Koyo()
              : base()
        {
        }
        public override bool DoSelectRecipe(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {

            // Koyo appears to get recipe from - this call not needed???
            errorMessage = "";
            return true;
        }

        public override void DoToolSpecificProcessCompleted(S6F11 eventMessage)
        {
            // Recipe Completed 5007
            
            //TODO - verift that this is correct for Koyo - what data from their canned report needs to be uploaded
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
                    if (vidData.Name != null && nameToCamstarName.ContainsKey(vidData.Name))
                    {
                        uploadData.Add(nameToCamstarName[vidData.Name], vidData.Value);
                    }
                }
            }
        }


        
        public override void DoToolSpecificProcessStarted(S6F11 eventMessage)
        {
            //TODO - anything go here for Koyo??

            //throw new NotImplementedException();
        }

        protected override void InitializeControlStates()
        {
            ControlStateDict.Add(1, new ControlState(ControlStates.OFFLINE,
                "Off-Line/Equipment Off-Line"));

            // No #2 for Koyo
            // ControlStateDict.Add(2, new ControlState(ControlStates.OFFLINE,
            //      "Off-Line/Attempt On-Line"));

            ControlStateDict.Add(3, new ControlState(ControlStates.OFFLINE,
                  "Off-Line/Host Off-Line"));
            ControlStateDict.Add(4, new ControlState(ControlStates.LOCAL,
                  "On-Line/Local"));
            ControlStateDict.Add(5, new ControlState(ControlStates.REMOTE,
                  "On-Line/Remote"));
        }

        public override bool PossiblyHandleControlStateChangeEvent(string CEID)
        {
            // TODO - check these for Koyo
            ControlState newControlState = null;
            if (CEID == ControlStateLocalCEID)
            {
                newControlState = ControlStateDict[4];  //TODO: get rid of magic numbers
            }
            else if (CEID == ControlStateEquipmentOfflineCEID)
            {
                newControlState = ControlStateDict[1];
            }
            else if (CEID == ControlStateRemoteCEID)
            {
                newControlState = ControlStateDict[5];
            }
            else if (CEID == ControlStateHostOfflineCEID)
            {
                newControlState = ControlStateDict[3];
            }
            if (newControlState != null)
            {
                Messenger.Default.Send(new ControlStateChangeMessage(newControlState.State, newControlState.Description));
                MyLog.Information("Control State changed to " + newControlState.Description);
                return true;
            }
            else
            {
                return false;
            }
        }

        public override bool QueryProcessAndControlState(out Globals.ControlState newControlState, out Globals.ProcessState newProcessState)
        {
            //TODO - look at evatec example - this could possible be moved to Tool.cs
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

        protected override bool DoToolSpecificStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {
            // TODO startbatch then start lot for each lot/port 


            // RCMD = START
            S2F41 hostCommandMessage = new S2F41(CurrentToolConfig.Toolid);
            hostCommandMessage.SetRCMD("LotStart", DataType.ASC);                // TODO change this when S2F41 supports string sizes
            hostCommandMessage.addCp("Port", DataType.ASC, Port, DataType.ASC);  // TODO change this when S2F41 supports string sizes
            try
            {
                MyLog.Information("Sending HCMD LotStart");

                hostCommandMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(hostCommandMessage.HCACK))
                {
                    MyLog.Information("HCMD for LotStart returned good HCACK");
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

       

        protected override void InitializeHardcodedEvents()
        {
            // Koyo specific CEIDs

            // TODO - this is from Evatec - need to update for Koyo
            ProcessStateChangeCEID = "5001";      // Koyo Manual Proc State
       
            //for (int ii = 10; ii <= 21; ii++)
            //{
            //    OtherProcessStateChangeCEID.Add(ii.ToString());
            //}
            //OtherProcessStateChangeCEID.Add("????");    // What is this for Koyo

            ProcessCompletedCEID.Add("5007");   // Named Recipe Completed in Koyo manual
            ProcessStartedCEID.Add("5006");     // Named Recipe Started in Koyo manual
        }

        protected override void InitializeHostCommandAckDict()
        {
            //TODO fix for Koyo
            string[] dictEntries = new string[] { "0", "Accepted", "1", "Undefined", "2", "Denied"};
            for (int ii = 0; ii < dictEntries.Length; ii += 2)
            {
                HostCommandAckDict.Add(dictEntries[ii], dictEntries[ii + 1]);
            }
        }

        protected override void InitializeProcessStates()
        {
            // From Brock's log comments: Equipment Status values
            //0 : Setup  (VF-1000/VF-3000) 
            //1 : Ready  (Common) 
            //2 : Run  (Common) 
            //3 : Hold  (VF-1000/VF-3000) 
            //4 : End  (VF-1000/VF-3000) 
            //5 : Int-Run  (VF-1000/VF-3000) 
            //6 : Int-End  (VF-1000/VF-3000) 
            //7 : Test  (Common) 
            //8 : Alarm  (VF-1000/VF-3000) 
            //11 : Ready_ALARM  (RSC) 
            //12 : Run_ALARM  (Common) 
            //13 : Hold_ALARM  (VF-1000/VF-3000) 
            //14 : End_ALARM  (VF-1000/VF-3000) 
            //15 : Int-Run_ALARM  (VF-1000/VF-3000) 
            //16 : Int-End_ALARM  (VF-1000/VF-3000) 
            //17 : Test_ALARM  (RSC) ##

            //TODO - verify for Koyo specific (VF3000)...
            ProcessStateDict.Add(0, new ProcessState(ProcessStates.NOTREADY,
                  "Setup"));
            ProcessStateDict.Add(1, new ProcessState(ProcessStates.READY,
                 "Ready"));
            ProcessStateDict.Add(2, new ProcessState(ProcessStates.NOTREADY,
                 "Run"));
            ProcessStateDict.Add(3, new ProcessState(ProcessStates.NOTREADY,
                  "Hold"));
            ProcessStateDict.Add(4, new ProcessState(ProcessStates.NOTREADY,
                  "End"));
            ProcessStateDict.Add(5, new ProcessState(ProcessStates.EXECUTING,
                  "Int-Run"));
            ProcessStateDict.Add(6, new ProcessState(ProcessStates.NOTREADY,
                  "Int-End"));
            ProcessStateDict.Add(7, new ProcessState(ProcessStates.NOTREADY,
                 "Test"));
            ProcessStateDict.Add(8, new ProcessState(ProcessStates.NOTREADY,
                 "Alarm"));
            ProcessStateDict.Add(11, new ProcessState(ProcessStates.NOTREADY,
                  "Ready_ALARM"));
            ProcessStateDict.Add(12, new ProcessState(ProcessStates.NOTREADY,
                  "Run_ALARM"));
            ProcessStateDict.Add(13, new ProcessState(ProcessStates.NOTREADY,
                  "Hold_ALARM"));
            ProcessStateDict.Add(14, new ProcessState(ProcessStates.NOTREADY,
                  "End_ALARM"));
            ProcessStateDict.Add(15, new ProcessState(ProcessStates.NOTREADY,
                  "Int-Run_ALARM"));
            ProcessStateDict.Add(16, new ProcessState(ProcessStates.NOTREADY,
                  "Int-End_ALARM"));
            ProcessStateDict.Add(17, new ProcessState(ProcessStates.NOTREADY,
                  "Test_ALARM"));
        }

        public override bool CreateBatch(string BatchId, string PPID, int ProcessTime, string TableNumber,
            string CarrierID, string MaterialType, int CarrierLocation, int[] SlotStatus)
        {
            S2F65 createBatchMessage = new S2F65(CurrentToolConfig.Toolid);
            createBatchMessage.SetBatchId(BatchId, 16);
            createBatchMessage.SetPPID(PPID, 16);
            DateTime dt = new DateTime(0);
            dt.AddSeconds(ProcessTime);
            createBatchMessage.SetProcessTime(dt.ToString("HHmmss"));
            createBatchMessage.SetTableNumber(TableNumber);
            createBatchMessage.SetSlotStatusType(DataType.U1);
            List<int> temporary = new List<int>();      //TODO fix this when API fixed
            temporary.AddRange(SlotStatus); 
            createBatchMessage.AddCarrier(CarrierID, 20, MaterialType, CarrierLocation, DataType.UI1, temporary);

              try
            {
                MyLog.Information("H->E Sending create batch ");

                createBatchMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(createBatchMessage.ACK))
                {
                    MyLog.Information("Create batch command returned good ACK");
                    return true;
                }
                else
                {
                    string message = "Create batch command returned bad ACK " + createBatchMessage.ACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", message));
                    MyLog.Information(message);
                    return false;
                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("Create batch command (S2F65) failed: ", true, e);
                return false;
            }
        }

        public  bool DeleteBatch(string BatchId, out string errorMessage)
        {
            S2F41 deleteBatchMessage = new S2F41(CurrentToolConfig.Toolid);
            deleteBatchMessage.SetRCMD("DELBATCH  ", DataType.ASC);                // TODO change this when S2F41 supports string sizes
            deleteBatchMessage.addCp("BATCHID", DataType.ASC, BatchId, DataType.ASC);  // TODO change this when S2F41 supports string sizes

            try
            {
                MyLog.Information("Sending HCMD DELBATCH");

                deleteBatchMessage.send(EqSrv, CurrentToolConfig.CommunicationTimeout);
                if (ToolUtilities.checkAck(deleteBatchMessage.HCACK))
                {
                    MyLog.Information("HCMD for DELBATCH returned good HCACK");
                    errorMessage = "";
                }
                else
                {
                    errorMessage = "HCMD for DELBATCH returned bad HCACK " + deleteBatchMessage.HCACK;
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", errorMessage));
                    MyLog.Information(errorMessage);

                }
            }
            catch (Exception e)
            {
                ToolUtilities.ReportMessageSendExceptions("HCMD (S2F41) START", true, e);
                errorMessage = "Error sending HCMD for DELBATCH";
                return false;
            }

            return true;
        }
    }
}
