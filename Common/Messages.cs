using Common;
using System;
using System.Collections.Generic;
using System.Data;
using System.Windows.Controls;

namespace Common
{
    public class InitializeSystemMessage
    {
        public InitializeSystemMessage() { }
    }

    public class ReInitializeSystemMessage
    {
        // Using int for now to keep options open
        // 0 is fullReset
        // 1 is Cancel Only
        public int fullReset { get; set; }
        public ReInitializeSystemMessage(int level)
        {
            fullReset = level ; 
        }
    }

    public class InitializeWafersMessage
    {
        public bool fromCodeBehind { get; set; }
        public InitializeWafersMessage(bool fcb = false)
        {
            fromCodeBehind = fcb; 
        }
    }


    public class BusyIndicatorMessage
    {
        public bool isBusy { get; set; }
        public string busyMsg { get; set; }
        public BusyIndicatorMessage(bool busy, string busyContent)
        {
            isBusy = busy;
            busyMsg = busyContent;
        }
    }

    public class ToggleAlarmViewMessage
    {
        public bool bVisible = false;

        public ToggleAlarmViewMessage(bool? bVisible = null)
        {
            if (!bVisible.HasValue)
                this.bVisible = bVisible.GetValueOrDefault();
        }
    }

    public class EventMessage
    {
        public DateTime MsgDateTime;
        public string MsgType;      // So far only A=Alarm, C=Completed, PM=Processing are used  (A, T, L, or E  for Alarm, Trace, Log or Event or PM update)
        public string Message;      // I am going to add E=Error for all errors with the tool 
                                    // And "L" for log entries
        public bool SendEmail;
        public bool CriticalAlarm;

        public EventMessage(DateTime dt, string msgType, string message)
        {
            MsgDateTime = dt;
            MsgType = msgType;
            Message = message;
            SendEmail = false;
            CriticalAlarm = false;
        }
        public EventMessage(DateTime dt, string msgType, string message, bool alarmIsCritical) : this(dt, msgType, message)
        {
            CriticalAlarm = alarmIsCritical;
        }

        public EventMessage(LogEntry logEntry)
        {
            MsgDateTime = logEntry.EventDateTime;
            MsgType = logEntry.EventType;
            Message = logEntry.Message;
            SendEmail = logEntry.SendEmail;
        }
    }

    public class OperatorResponseMessage
    {
        public AuthorizationLevel authLevel { get; set; }
        public int PortNo { get; set; }

        public OperatorResponseMessage(int portNo, AuthorizationLevel al)
        {
            PortNo = portNo; 
            authLevel = al;
        }
    }

    public class CurrentOperatorMessage
    {
        public string OperatorID { get; set; }
        public AuthorizationLevel AuthLevel { get; set; }
        public CurrentOperatorMessage(string opId, AuthorizationLevel authorizationLevel)
        {
            OperatorID = opId;
            AuthLevel = authorizationLevel; 
        }
    }

    public class EngineerViewMessage
    {
        public int PortNo { get; set; }
        public bool IsEngineer { get; set; }
        public EngineerViewMessage(int portNo, bool engineer)
        {
            PortNo = portNo; 
            this.IsEngineer = engineer;
        }
    }

    public class CloseAlarmMessage
    {
        public CloseAlarmMessage()
        {
        }
    }

    public class ToggleLogViewMessage
    {
        public bool bVisible = false;

        public ToggleLogViewMessage(bool? bVisible = null)
        {
            if (!bVisible.HasValue)
                this.bVisible = bVisible.GetValueOrDefault();
        }
    }
  
    public class ReFocusMessage
    {
        public TextBox tb { get; set; }
        public string textbox2Focus { get; set; }

        //public ReFocusMessage(TextBox textBox)
        //{
        //    this.tb = textBox;
        //}

        public ReFocusMessage(string tbName, object e)
        {
            this.textbox2Focus = tbName; 
        }
    }
    
    public class LoadLot1Message
    {
        public DataTable dtWafers { get; set; }
        public string lotID { get; set; }
        public LoadLot1Message(DataTable dt, string lotId)
        {
            dtWafers = dt ;
            lotID = lotId;
        }
    }

    public class PromptToConfirmNextTabMessage
    {
        public int CurrentTabIndex { get; set; }
        public PromptToConfirmNextTabMessage(int curTab)
        {
            CurrentTabIndex = curTab; 
        }
    }

    public class RenumberWafersMessage
    {
        public RenumberWafersMessage()
        {
        }
    }

    public class MoveWafersMessage
    {
        public int SlotToMove { get; internal set; }

        public MoveWafersMessage(Wafer waferToMove)
        {
            SlotToMove = int.Parse(waferToMove.Slot);
        }
    }

    public class WafersConfirmedMessage
    {
        public bool Confirmed { get; internal set; }

        public WafersConfirmedMessage(bool confirmed)
        {
            this.Confirmed = confirmed;
        }
    }

    public class WafersInGridMessage
    {
        public int? NumberOfWafers { get; internal set; }

        public WafersInGridMessage(int? numWafers)
        {
            this.NumberOfWafers = numWafers.GetValueOrDefault();
        }
    }

    public class SelectedWafersInGridMessage
    {
        public List<Wafer> wafers { get; internal set; }

        public SelectedWafersInGridMessage(List<Wafer> selectedWafers)
        {
            this.wafers = selectedWafers;
        }
    }

    public class CamstarStatusMessage
    {
        public string Availability { get; private set; }
        public string ResourceName { get; private set; } = "Error";
        public string ResourceStateName { get; private set; } = "Error";
        public string ResourceSubStateName { get; private set; } = "Error";

        public bool IsAvailable => Availability == "1";

        public CamstarStatusMessage(string availability, string resourceName, string resourceSubstateName)
        {
            this.Availability = availability;
            this.ResourceName = resourceName;
            this.ResourceSubStateName = resourceSubstateName;
        }

        public CamstarStatusMessage(DataTable dtCamstar)
        {
            try
            {
                Availability = dtCamstar.Rows[0]["Availability"].ToString();
                ResourceName = dtCamstar.Rows[0]["ResourceName"].ToString();
                ResourceStateName = dtCamstar.Rows[0]["ResourceStateName"].ToString();
                ResourceSubStateName = dtCamstar.Rows[0]["ResourceSubStateName"].ToString();
            }
            catch
            {

            }
        }
    }

    public class ControlStateChangeMessage
    {
       public Globals.ControlStates ControlState { get; private set; }
        public string Description { get; private set; }

        public ControlStateChangeMessage (Globals.ControlStates newState, string description)
        {
            this.ControlState = newState;
            this.Description = description;
         }
    }
     public class ProcessStateChangeMessage
    {
        public int PortNo { get; private set; }
        public Globals.ProcessStates ProcessState { get; private set; }
        public string Description { get; private set; }

        public ProcessStateChangeMessage(Globals.ProcessStates newState, string description, int portNo = -1)
        {
            this.PortNo = portNo;
            this.ProcessState = newState;
            this.Description = description;
        }
    }
    public class ProcessCompletedMessage
    {
        public int PortNo { get; set; }
        public string Description { get; private set; }

        public ProcessCompletedMessage(string description, int portNo=-1)
        {
            this.PortNo = portNo; 
            this.Description = description;
        }
    }

    public class ProcessWaitMessage
    {
        public int PortNo { get; set; }
        public string DisplayText { get; set; }
    
        public ProcessWaitMessage(int portNo, string displayText)
        {
            this.PortNo = portNo; 
            this.DisplayText = displayText;
        }
    }

    public class ProcessContinueMessage
    {
        public int PortNo { get; set; }
        public ProcessContinueMessage(int portNo)
        {
            this.PortNo = portNo;
        }
    }

    public class ProcessAbortMessage
    {
        public int PortNo { get; set; }
        public ProcessAbortMessage(int portNo)
        {
            this.PortNo = portNo; 
        }
    }
    public class RecipeListAvailableMessage
    {
        public RecipeListAvailableMessage()
        {
        }
    }


    public class CloseAndSendEmailMessage
    {
        public string SendTo { get; private set; } = "";
        public string Subject { get; private set; } = "";
        public string EmailBody { get; private set; } = "";

        public CloseAndSendEmailMessage(string sendTo, string subject, string emailBody)
        {
            this.SendTo = sendTo;
            this.Subject = subject;
            this.EmailBody = emailBody;
        }
    }  

    #region OPERATOR TOOL LOT 

    public class SetAllWafersRecipeMessage
    {
        public string Recipe;

        public SetAllWafersRecipeMessage(string newRecipe)
        {
            this.Recipe = newRecipe; 
        }
    }

    //public class SetAllWafersRecipeMessage
    //{
    //    public string Recipe;

    //    public SetAllWafersRecipeMessage(string newRecipe)
    //    {
    //        this.Recipe = newRecipe;
    //    }
    //}

    public class SetAllWafersStatusMessage
    {
        public int Port { get; set; }
        public string LotId { get; set; }
        public string WaferStatus { get; set; }
        public string TabProcessingColor { get; set; }

        public SetAllWafersStatusMessage(int portNo, string lotId, string waferStatus, string lotStatusColor="")
        {
            this.Port = portNo;
            this.LotId = lotId;
            this.WaferStatus = waferStatus;
            this.TabProcessingColor = lotStatusColor;
        }
    }

    public class PortStartedMessage
    {
        public int PortNo { get; set; }
        //public string Recipe;

        public PortStartedMessage(int portNo)
        {
            this.PortNo = portNo; 
        }
    }

    public class MoveInWafersMessage
    {
        public int PortNo { get; set; }

        public MoveInWafersMessage(int portNo)
        {
            this.PortNo = portNo;
        }
    }

    public class MoveInResponseMessage
    {
        public int PortNo { get; set; }
        public bool Result { get; set; }

        public MoveInResponseMessage(int portNo, bool result)
        {
            this.PortNo = portNo;
            this.Result = result; 
        }
    }

    public class LoadingWafersMessage
    {
        public int Port { get; set; }
        public bool LoadingWafers { get; set; }
        public string TimerText { get; set; }

        public LoadingWafersMessage(int portNo, bool loadingWafers, string timerText)
        {
            this.Port = portNo;
            this.LoadingWafers = loadingWafers;
            this.TimerText = timerText;
        }
    }

    public class DeleteLotMessage
    {
        public int PortNo { get; set; }
        public string LotToDelete { get; set; }

        public DeleteLotMessage(int portNo, string lotId)
        {
            this.PortNo = portNo;
            this.LotToDelete = lotId; 
        }
    }


    public class UpdateRecipeAndRunTypeMessage
    {
        public int PortNo { get; set; }
        public List<Wafer> listWafers { get; set; }

        public UpdateRecipeAndRunTypeMessage(int portNo, List<Wafer> wafers)
        {
            PortNo = portNo;
            listWafers = wafers;
        }
    }

    public class AddWafersToGridMessage
    {
        public int PortNo { get; set; }
        public List<Wafer> listWafers { get; private set;  }

        public AddWafersToGridMessage(int portNo, List<Wafer> wafers)
        {
            PortNo = portNo; 
            listWafers = wafers; 
        }
    }



    #endregion

}