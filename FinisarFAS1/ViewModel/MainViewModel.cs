using Common;
using FinisarFAS1.Utility;
using FinisarFAS1.View;
using GalaSoft.MvvmLight;
using GalaSoft.MvvmLight.Command;
using GalaSoft.MvvmLight.Messaging;
using GalaSoft.MvvmLight.Views;
using MESCommunications;
using MESCommunications.Utility;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;
using System.Reflection;
using ToolService;
using static Common.Globals;
using Serilog;
using System.Net.Mail;
using System.Net;
using System.Text.RegularExpressions;
using System.ComponentModel;
using System.Text;

namespace FinisarFAS1.ViewModel
{
    /// <summary>
    /// This class contains properties that the main View can data bind to.
    /// <para>
    /// Use the <strong>mvvminpc</strong> snippet to add bindable properties to this ViewModel.
    /// </para>
    /// <para>
    /// You can also use Blend to data bind with the tool's support.
    /// </para>
    /// <para>
    /// See http://www.galasoft.ch/mvvm
    /// </para>
    /// </summary>
    public class MainViewModel : ViewModelBase
    {
        private readonly IDialogService2 dialogService;
        private MESService _mesService;

        // private Evatec currentEquipment;
        SECSHandler<Tool> currentTool;
        bool EquipmentNotTalking;

        DispatcherTimer dispatcherTimer = new DispatcherTimer();
        DispatcherTimer processingTimer = new DispatcherTimer();
        DispatcherTimer mainTimer = new DispatcherTimer();
        int mesCheckInSeconds = 10;
        int mainTick = 0;

        // Test data
        private string thisHostName = "";  // "TEX-L10015200" 
        string factoryName = "factoryName";

        private DataTable dtCamstar;

        private OperatorToolLotViewModel portLotInfo;

        public OperatorToolLotViewModel PortLotInfo {
            get { return portLotInfo; }
            set {
                portLotInfo = value;
                RaisePropertyChanged(nameof(PortLotInfo));
            }
        }

        Dictionary<int, OperatorToolLotViewModel> PortLotList = new Dictionary<int, OperatorToolLotViewModel>();

        private WaferGridViewModel waferGrid;

        public WaferGridViewModel WaferGridInfo {
            get { return waferGrid; }
            set {
                waferGrid = value;
                RaisePropertyChanged(nameof(WaferGridInfo)); 
            }
        }

        Dictionary<int, WaferGridViewModel> WaferGridList = new Dictionary<int, WaferGridViewModel>();
        /// TODO: This is for testing
        /// 
        bool doPortCheck = false; 



        /// <summary>
        /// Initializes a new instance of the MainViewModel class.
        /// </summary>
        public MainViewModel()
        {
            MyLog = new FASLog();
            // Initialize DI objects
            IDialogService2 dialogService1 = new MyDialogService(null);
            dialogService1.Register<DialogViewModel, DialogWindow>();
            dialogService = dialogService1;

            PortLotInfo = new OperatorToolLotViewModel(0, UsingMoq);
            PortLotList.Add(0, PortLotInfo);

            WaferGridInfo = new WaferGridViewModel(0);
            WaferGridList.Add(0, WaferGridInfo);
            
            if (Globals.UsingMoq)
                _mesService = new MESService(new MoqMESService());
            else
                _mesService = new MESService(new MESDLL());

            RegisterForMessages();
        }

        #region INITIALIZE SYSTEM CHECK CAMSTAR AND CHECK EQUIPMENT TIMERS 

        private async void ReInitializeSystemHandler(ReInitializeSystemMessage msg)
        {
            Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Processing..."));
            //await Task.Run(() =>
            await Task.Delay(2000).ContinueWith(_ =>
            {
                // MoveInComplete = false;            
                Completed = false;
                Aborted = Started = false;                
                TabProcessingColor = "Ready";
                CurrentRecipe = CurrentRunType = "";
            });
        }

        private void InitializeSystemHandler(InitializeSystemMessage msg)
        {
            MyLog.Debug("Starting InitializeSystem()...");
            CurrentControlstate = ControlStates.UNDEFINED;

            MyLog.Debug("GetConfigurationValues()...");
            GetConfigurationValues();
            thisHostName = CurrentSystemConfig.ACINameServerHost;

            MyLog.Debug("Starting SetupMESCommunication()...");
            SetupMESCommunication();

            MyLog.Debug("Starting SetupEquipment()...");
            EquipmentNotTalking = false;
            SetupEquipment();
            MyLog.Debug("Done SetupEquipment()...");

            MyLog.Debug("Starting Timer to check for Camstar and Equipment updates...");
            mainTimer.Tick += new EventHandler(mainTimer_Tick);
            mainTimer.Interval = new TimeSpan(0, 0, 1);
            mainTimer.Start();

            // Initialize some UI vlaues
            CamstarStatusText = CurrentToolConfig.CamstarString;
            Title = "Factory Automation System: " + CurrentToolConfig.Toolid;

            // Set UI bindings
            Started = false;
            IsProcessing = false;
            Engineer = false; 
        }

        private void GetConfigurationValues()
        {
            //Steve - Made change to  read XML configs in App.xaml.cs
            int idx = 0; 
            LoadPortNames = new ObservableCollection<string>();
            foreach (string portName in CurrentToolConfig.Loadports)
            {
                LoadPortNames.Add(portName);
                // We already added the first one
                if (++idx > 1)
                { 
                    OperatorToolLotViewModel otlVM = new OperatorToolLotViewModel(idx-1, UsingMoq);                    
                    PortLotList.Add(idx-1, otlVM);                                   }
            }
            if (LoadPortNames.Count>3)
                PortDActive = true; 
            else
            {
                PortDActive = false;
                if (LoadPortNames.Count > 2)
                    PortCActive = true; 
                else
                {
                    PortCActive = false;
                    if (LoadPortNames.Count > 1)
                        PortBActive = true;
                    else
                        PortBActive = false; 
                }
            }
            RaisePropertyChanged(null);
            RaisePropertyChanged("LoadPortNames");

            factoryName = CurrentToolConfig.FactoryName;
        }

        static void CallWithTimeout(Action<MainViewModel> action, MainViewModel mdl, int timeoutMilliseconds)
        {
            Thread threadToKill = null;
            Action wrappedAction = () =>
            {
                threadToKill = Thread.CurrentThread;
                action(mdl);
            };
            IAsyncResult result = wrappedAction.BeginInvoke(null, null);
            if (result.AsyncWaitHandle.WaitOne(timeoutMilliseconds))
            {
                wrappedAction.EndInvoke(result);
            }
            else
            {
                threadToKill.Abort();
                //throw new TimeoutException();
            }
        }

        private void SetupMESCommunication()
        {
            var q = _mesService.Initialize(MESDefaultConfigDir + MESDefaultConfigFile, thisHostName);

            // Update CamStar first       
            CallWithTimeout(CamstarCall, this, 4000);

            Messenger.Default.Send(new CamstarStatusMessage(dtCamstar));
        }

        private void mainTimer_Tick(object sender, EventArgs e)
        {
            if (++mainTick % mesCheckInSeconds == 0)
            {
                //MyLog.Debug("mainTimer_Tick->Start...");
                CallWithTimeout(CamstarCall, this, 3000);
                Messenger.Default.Send(new CamstarStatusMessage(dtCamstar));

                // TODO: I would prefer currentTool == null here....
                if (EquipmentStatus == "Offline" && EquipmentNotTalking)
                {
                    SetupEquipment();
                }
                //MyLog.Debug("mainTimer_Tick->End...");
            }
        }

        public void CamstarCall(MainViewModel mdl)
        {
            dtCamstar = GetCamstarStatus();
        }

        public DataTable GetCamstarStatus()
        {
            try
            {
                return _mesService.GetResourceStatus(CurrentToolConfig.Toolid);
            }
            catch { return null; }
            finally { }
        }

        private void SetupEquipment()
        {
            // Get ToolID status #2 with the ToolService project
            string _eq = CurrentToolConfig.Toolid;
            try
            {

                try {
                    MyLog.Debug($"SetupEquipment->GetType('ToolService.{CurrentToolConfig.ToolType}')");

                    currentTool = new SECSHandler<Tool>((Tool)Activator.CreateInstance(Assembly.Load("ToolService").GetType("ToolService." + CurrentToolConfig.ToolType), true));
                }
                catch (Exception ex)
                {
                    MyLog.Error(ex, $"Unable to start application: make sure the configured tool type {CurrentToolConfig.ToolType} in toolConfig.xml is supported");
                    Messenger.Default.Send(new EventMessage(DateTime.Now, "E", "Unable to start application for tool type '" + CurrentToolConfig.ToolType) + "'");
                    return;
                }

                MyLog.Debug($"SetupEquipment->InitializeTool...");
                currentTool.InitializeTool();
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "SetupEquipment()");
            }
        }

        #endregion

        #region MESSAGE HANDLERS 
        private void RegisterForMessages()
        {
            Messenger.Default.Register<InitializeSystemMessage>(this, InitializeSystemHandler);
            Messenger.Default.Register<ReInitializeSystemMessage>(this, ReInitializeSystemHandler);

            Messenger.Default.Register<CamstarStatusMessage>(this, UpdateCamstarStatusHandler);
            Messenger.Default.Register<ControlStateChangeMessage>(this, UpdateControlStateHandler);
            Messenger.Default.Register<ProcessStateChangeMessage>(this, UpdateProcessStateHandler);

            Messenger.Default.Register<CloseAndSendEmailMessage>(this, CloseEmailResponseMsgHandler);
            Messenger.Default.Register<EventMessage>(this, EventMessageHandler);
            Messenger.Default.Register<ProcessCompletedMessage>(this, ProcessingCompleteMsgHandler);
            Messenger.Default.Register<ProcessWaitMessage>(this, ProcessWaitMsgHandler);
            Messenger.Default.Register<ProcessContinueMessage>(this, ProcessContinueMsgHandler);
            Messenger.Default.Register<ProcessAbortMessage>(this, ProcessAbortMsgHandler);
            Messenger.Default.Register<PromptToConfirmNextTabMessage>(this, PromptForNextTabMsgHandler);

            Messenger.Default.Register<UpdateRecipeAndRunTypeMessage>(this, updateRecipeAndRunTypeMsgHandler);
            Messenger.Default.Register<EngineerViewMessage>(this, engineerViewMsgHandler);
        }

        private void UpdateCamstarStatusHandler(CamstarStatusMessage msg)
        {
            string tempStatus = "Offline";
            string tempColor = "Red";

            if (msg != null)
            {
                tempColor = msg.IsAvailable ? "Lime" : "Yellow";
                tempStatus = msg.ResourceStateName;
            }
            else
            {
                tempStatus = "Offline";
                tempColor = "Red";
            }
            // Only update at end so the colors are not flashing...
            CamstarStatus = tempStatus;
            CamstarStatusColor = tempColor;
        }
        private void UpdateControlStateHandler(ControlStateChangeMessage msg)
        {
            string tempStatus = msg.Description;
            string tempColor;
            ControlStates oldcs = CurrentControlstate;

            if (msg.ControlState == ControlStates.REMOTE)
            {
                tempStatus = "Online: Remote";
                tempColor = "Lime";
                EquipmentNotTalking = false; 
                LocalMode = false; 
            }
            else
            if (msg.ControlState == ControlStates.LOCAL)
            {
                tempStatus = "Online: Local";
                tempColor = "Yellow";
                EquipmentNotTalking = false;
                LocalMode = true;
            }
            else
            if (msg.ControlState == ControlStates.OFFLINE)
            {
                tempStatus = "Offline";
                tempColor = "Red";
                LocalMode = true;
            }
            else
            {
                tempStatus = "Unknown";
                tempColor = "DodgerBlue";
            }

            CurrentControlstate = msg.ControlState;
            EquipmentStatus = tempStatus;
            EquipmentStatusColor = tempColor;
        }
        /// <summary>
        ///  Internal field just in case we need to know 
        /// </summary>
        private bool ProcessStateReady = false; 
        private void UpdateProcessStateHandler(ProcessStateChangeMessage msg)
        {
            if (doPortCheck && msg.PortNo!=thisPortNo) return; 

            ProcessStateReady = msg.ProcessState == ProcessStates.READY;
        }

        private void updateRecipeAndRunTypeMsgHandler(UpdateRecipeAndRunTypeMessage msg)
        {
            try
            {
                CurrentRecipe = msg.listWafers[0].Recipe;
                CurrentRunType = msg.listWafers[0].ContainerType;
                if (msg.listWafers[0].ContainerType == "T" || msg.listWafers[0].ContainerType == "R")
                    EngineeringRun = true;
                else
                    EngineeringRun = false;
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "updateRecipeAndRunTypeMsgHandler()");
            }
        }

        private void engineerViewMsgHandler(EngineerViewMessage msg)
        {
            Engineer = msg.IsEngineer;
        }

        

        private void PromptForNextTabMsgHandler(PromptToConfirmNextTabMessage msg)
        {
            var vm = new DialogViewModel($"Do you want to load Port 2/ Other Port?", "Ok", "Cancel");
            var result = dialogService.ShowDialog(vm);
            if (result.HasValue && result.Value==true)
            {
                CurrentTab = CurrentTab==1? 0 : 1 ; 
            }
        }

         private void ProcessAbortMsgHandler(ProcessAbortMessage msg)
        {
            MyLog.Information($"SECS->SendSECSAbort()");
            currentTool.SendSECSAbort();
            Started = false;
            Aborted = true;            
            IsProcessing = false;
            HoldWafers("Aborted by Factory Automation for " + PortLotInfo.OperatorID);
        }

        private void ProcessingCompleteMsgHandler(ProcessCompletedMessage msg)
        {
            if (Aborted) return;    // Do not Complete Aborted wafers... this happened in Simbut prob not real life
            TabProcessingColor = "Complete";
            Completed = true;
            Application.Current.Dispatcher.Invoke((Action)delegate
            {
                MoveOutWafers();
                UploadData();
            });
        }

        private void ProcessWaitMsgHandler(ProcessWaitMessage msg) => Messenger.Default.Send(new ProcessWaitMessage("Wait"));

        private void ProcessContinueMsgHandler(ProcessContinueMessage msg) => Messenger.Default.Send(new ProcessStateChangeMessage(ProcessStates.READY, "Ready"));

       

        int numCannotCommunicateMES = 0; 

        private void EventMessageHandler(EventMessage msg)
        {
            // TODO: Make sure all these are still valid and in use
            if (msg.MsgType == "A")
            {
                int len = msg.Message.Length > 80 ? 80 : msg.Message.Length;
                string s = msg.Message.Substring(0, len);
                CurrentAlarm = msg.MsgDateTime + "-" + s;

                if (msg.CriticalAlarm)
                    alarmEmailHandler(msg.MsgDateTime, "TOOLID: " + PortLotInfo.ToolID + " CRITICAL ALARM: " + s);
            }
            else if (msg.MsgType == "PM")
            {
                if (msg.Message.Contains("Processing"))
                {
                    // UpdateWaferStatus("In Processing");
                    TabProcessingColor = "Processing";
                }
            }
            else if (msg.MsgType == "E")
            {
                string s = "CRITICAL ERROR: " + msg.Message;
                var vm = new DialogViewModel(s, "", "Ok");

                Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, "", "Critical Error"));

                TabProcessingColor = "CRITICAL ERROR";
                if (msg.Message.Contains("Unable to start AutoShell comm"))
                {
                    // Only show cannot comm with Camstar at beginning then every 10 times
                    if (++numCannotCommunicateMES == 1 || numCannotCommunicateMES % 10 == 0)
                    {
                        Application.Current.Dispatcher.Invoke((Action)delegate
                        {
                            dialogService.ShowDialog(vm);
                        });
                        vm = null; 
                    }
                    EquipmentNotTalking = true;
                }
                else // Show all Critical Errors 
                {
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    vm = null;  
                }

                errorEmailHandler(msg.Message);
            }
            else if (msg.MsgType == "L")
            {
                if (msg.SendEmail)
                {
                    logEmailHandler(msg);
                }
            }
        }
        
        private void abortCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSAbort()", true);
            currentTool.SendSECSAbort();
        }
        private void goLocalCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSGoLocal()", true);
            if (currentTool.SendSECSGoLocal())
                LocalMode = true;
        }
        private void goRemoteCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSGoRemote()", true);
            if (currentTool.SendSECSGoRemote())
                LocalMode = false;
        }

        #endregion

        private List<string> recipeList;
        public List<string> RecipeList
        {
            get { return recipeList; }
            set { recipeList = value; RaisePropertyChanged(nameof(RecipeList)); }
        }

        private bool engineer;
        public bool Engineer
        {
            get { return engineer; }
            set
            {
                engineer = value;
                RaisePropertyChanged(nameof(Engineer));                
            }
        }

        private bool engineeringRun;
        public bool EngineeringRun
        {
            get { return engineeringRun; }
            set
            {
                engineeringRun = value;
                RaisePropertyChanged(nameof(EngineeringRun));
            }
        }

        #region GRID MANIPULATION
     
        int thisPortNo = 0;

        #endregion GRID MANIP

        #region FLOW STATUSES
        // Flow statuses
        // PORT 1

        //private bool _timeToProcess;
        //public bool MoveInComplete
        //{
        //    get { return _timeToProcess; }
        //    set
        //    {
        //        _timeToProcess = value;
        //        RaisePropertyChanged(nameof(MoveInComplete));
        //        Messenger.Default.Send(new WafersConfirmedMessage(value && AreThereWafers));
        //    }
        //}

        private bool _started;
        public bool Started
        {
            get { return _started; }
            set
            {
                _started = value;
                RaisePropertyChanged(nameof(Started));
                //RaisePropertyChanged(nameof(IsStoppable));
                //RaisePropertyChanged(nameof(ShowStartButton));
                // TODO: Message to 
                //RaisePropertyChanged(nameof(DisabledAfterStart));
                //if (value == true)
                //    IsRecipeOverridable = false; 
            }
        }       


        private bool _aborted;
        public bool Aborted
        {
            get { return _aborted; }
            set
            {
                _aborted = value;
                RaisePropertyChanged(nameof(Aborted));
                //RaisePropertyChanged(nameof(IsStoppable));
                //RaisePropertyChanged(nameof(ShowStartButton));
            }
        }

        private bool _isProcessing;
        public bool IsProcessing
        {
            get { return _isProcessing; }
            set
            {
                _isProcessing = value;
                RaisePropertyChanged(nameof(IsProcessing));
                // RaisePropertyChanged(nameof(IsStoppable));
            }
        }        
        
        private bool _localMode;
        public bool LocalMode
        {
            get { return _localMode; }
            set
            {
                _localMode = value;
                RaisePropertyChanged(nameof(LocalMode));
                RaisePropertyChanged(nameof(IsLocal));
				//ButtonEnabledIfOnline = !value;
    //            RaisePropertyChanged(nameof(ButtonEnabledIfOnline));
            }
        }

        public bool IsLocal => LocalMode;
       
        #endregion
       
        private string _currentRecipe;
        public string CurrentRecipe {
            get { return _currentRecipe; }
            set {
                if (_currentRecipe != value)
                {
                    // Change receip no matter what
                    _currentRecipe = value;
                    // TODO: Is this correct?
                    // Only change wafer recipes if the length is > 3
                    if (!string.IsNullOrEmpty(value)) // && value.Length > 3)
                    {
                        Messenger.Default.Send(new SetAllWafersRecipeMessage(value));
                    }
                    else
                    {
                        // TODO: Bad recipe dialog?
                    }
                }
                RaisePropertyChanged("CurrentRecipe");
            }
        }

        private string currentRunType;
        public string CurrentRunType {
            get { return currentRunType; }
            set { currentRunType = value; RaisePropertyChanged(nameof(CurrentRunType)); }
        }

     
#region STATES: CONTROL AND PROCESS / TOP LEFT

        private string _camstarStatus;
        public string CamstarStatus {
            get { return _camstarStatus; }
            set {
                _camstarStatus = value;
                RaisePropertyChanged(nameof(CamstarStatus));
            }
        }
        private ControlStates CurrentControlstate { get; set; }
     
        private string _equipmentStatus;
        public string EquipmentStatus {
            get { return _equipmentStatus; }
            set {
                _equipmentStatus = value;
                RaisePropertyChanged(nameof(EquipmentStatus));
            }
        }      

        private string _camstarStatusText;
        public string CamstarStatusText
        {
            get { return _camstarStatusText; }
            set
            {
                _camstarStatusText = value;
                RaisePropertyChanged(nameof(CamstarStatusText));
            }
        }

        private string _camstarStatusColor;
        public string CamstarStatusColor {
            get { return _camstarStatusColor; }
            set {
                _camstarStatusColor = value;
                RaisePropertyChanged("CamstarStatusColor");
            }
        }

        private string _equipmentStatusColor;
        public string EquipmentStatusColor {
            get { return _equipmentStatusColor; }
            set {
                _equipmentStatusColor = value;
                RaisePropertyChanged("EquipmentStatusColor");
            }
        }
        #endregion

        private string _title;
        public string Title
        {
            get { return _title; }
            set
            {
                _title = value;
                RaisePropertyChanged(nameof(Title));
            }
        }

		private int currentTab;

        public int CurrentTab {
            get { return currentTab; }
            set {
                currentTab = value;   
                // in case value (new tab index) is out of range
                if (PortLotList.Count > value)
                {
                    PortLotInfo = PortLotList[value];
                    RaisePropertyChanged(nameof(CurrentTab));
                    RaisePropertyChanged(nameof(PortLotInfo));
                }
                else
                {
                    // TODO : Show dialog 
                }
            }
        }

        private string _lotStatusColor; 
        public string TabProcessingColor
        {
            get { return _lotStatusColor; }
            set
            {
                string processingStep = value; 
                _lotStatusColor = Globals.GetColor(processingStep);
                RaisePropertyChanged(nameof(TabProcessingColor));
            }
        }
  
        private string _lotStatusColor2;
        public string TabProcessingColor2 {
            get { return _lotStatusColor2; }
            set {
                string processingStep = value;
                _lotStatusColor2 = Globals.GetColor(processingStep);
                RaisePropertyChanged(nameof(TabProcessingColor2));
            }
        }

        private ObservableCollection<string> _loadPortNames;
        public ObservableCollection<string> LoadPortNames
        {
            get { return _loadPortNames; }
            set
            {
                _loadPortNames = value;
            }
        }

        private bool _portBActive;
        public bool PortBActive
        {
            get { return _portBActive; }
            set { _portBActive = value; RaisePropertyChanged(nameof(PortBActive)); }
        }

        private bool _portCActive;
        public bool PortCActive
        {
            get { return _portCActive; }
            set { _portCActive = value; RaisePropertyChanged(nameof(PortCActive)); }
        }

        private bool _portDActive;
        public bool PortDActive
        {
            get { return _portDActive; }
            set { _portDActive = value; RaisePropertyChanged(nameof(PortDActive)); }
        }

        private string _currentAlarm;
        public string CurrentAlarm
        {
            get { return _currentAlarm; }
            set
            {
                _currentAlarm = value;
                RaisePropertyChanged("CurrentAlarm");
            }
        }

        private bool _completed;
        public bool Completed
        {
            get { return _completed; }
            set { _completed = value; RaisePropertyChanged(nameof(Completed)); }
        }

        private bool toolBusy;
        public bool ToolBusy {
            get { return toolBusy; }
            set { toolBusy = value; RaisePropertyChanged(nameof(ToolBusy)); }
        }

        #region MES CALLS FOR MOVEIN, MOVEOUT and HOLD

        private void moveInWafersMsgHandler(MoveInWafersMessage msg)
        {
            string errMessage = "";
            string errMessage2 = "";
            string comment = "Moved in through Factory Automation";
            const string ALREADYMOVEDIN = "MOVE-IN HAS ALREADY";
            bool movedIn1 = false;
            bool movedIn2 = false;
            bool requiredCertification = CurrentToolConfig.MoveInRequireCertification;

            int portNo = 0; // TOOD: msg.PortNo;

            // Thread.Sleep(3000);
            // Try to movein lot1
            // if there is an error, display and return 
            // if ok, then display moved in for lot1, and try to move in lot2
            // if there is an error, display error 
            // return from method
            //
            //SHMMoveIn(string sContainer, ref string strErrMsg, 
            //                  bool RequiredCertification, string sEmployee = "", 
            //                  string sComments = "", string sResource = "", string sFactory = "");
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot1))
            {
                if (!CheckForMovedInAlready(PortLotInfo.Port1Lot1))
                {
                    MyLog.Information($"MES->MoveIn(Lot1={PortLotInfo.Port1Lot1},  ref errMsg, {requiredCertification}, {PortLotInfo.OperatorID}, {comment}, {PortLotInfo.ToolID}, {factoryName})");
                    movedIn1 = _mesService.MoveIn(PortLotInfo.Port1Lot1, ref errMessage, requiredCertification, PortLotInfo.OperatorID, comment, PortLotInfo.ToolID, factoryName);
                    MyLog.Information($"MES->MoveIn returned: movedIn={movedIn1},  errMsg={errMessage}");
                    // Per ZH on 2/22 - If lot already moved in then keep on going
                    if (!movedIn1 && errMessage.ToUpper().Contains(ALREADYMOVEDIN))
                        movedIn1 = true;
                }
                else
                {
                    MyLog.Information($"MES->MoveIn {PortLotInfo.Port1Lot1} was ALREADY MovedIn");
                    movedIn1 = true;
                }
                if (movedIn1 == false)
                {
                    PortLotInfo.Port1Lot1Color = "Red";
                    string errString = $"MES->MoveIn:Error moving in lot #{PortLotInfo.Port1Lot1}: {errMessage}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    Messenger.Default.Send(new SetAllWafersStatusMessage(portNo, PortLotInfo.Port1Lot1, "ERROR on MoveIn"));
                    MyLog.Error(errString);
                    //return false;
                    Messenger.Default.Send(new MoveInResponseMessage(portNo, false));
                    return;
                }
                else
                {
                    Messenger.Default.Send(new SetAllWafersStatusMessage(portNo, PortLotInfo.Port1Lot1, WaferStatus.MovedIn.ToString()));
                    TabProcessingColor = "MovedIn";
                }
            }
            else
                MyLog.Information($"MES->MoveIn Lot1 is empty, so it was bypassed");

            Thread.Sleep(1000);

            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2))
            {
                if (!CheckForMovedInAlready(PortLotInfo.Port1Lot2))
                {
                    MyLog.Information($"MES->MoveIn2(Lot2={PortLotInfo.Port1Lot2},  ref errMsg, {requiredCertification}, {PortLotInfo.OperatorID}, {comment}, {PortLotInfo.ToolID}, {factoryName})");
                    movedIn2 = _mesService.MoveIn(PortLotInfo.Port1Lot2, ref errMessage2, requiredCertification, PortLotInfo.OperatorID, comment, PortLotInfo.ToolID, factoryName);
                    MyLog.Information($"MES->MoveIn2 returned: movedIn={movedIn2},  errMsg={errMessage2}");
                    if (!movedIn2 && errMessage2.ToUpper().Contains(ALREADYMOVEDIN))
                        movedIn2 = true;
                }
                else
                {
                    MyLog.Information($"MES->MoveIn {PortLotInfo.Port1Lot2} was ALREADY MovedIn");
                    movedIn2 = true;
                }

                if (movedIn2 == false)
                {
                    PortLotInfo.Port1Lot2Color = "Red";
                    string errString = $"MES->MoveIn2:Error moving in lot #{PortLotInfo.Port1Lot2}: {errMessage2}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    Messenger.Default.Send(new SetAllWafersStatusMessage(portNo, PortLotInfo.Port1Lot2, "ERROR on MoveIn"));
                    MyLog.Error(errString);
                    //return false;
                    Messenger.Default.Send(new MoveInResponseMessage(portNo, false));
                    return;
                }
                else
                {
                    Messenger.Default.Send(new SetAllWafersStatusMessage(portNo, PortLotInfo.Port1Lot2, WaferStatus.MovedIn.ToString()));
                    TabProcessingColor = "MovedIn";
                }
            }
            else
                MyLog.Information($"MES->MoveIn Lot2 is empty, so it was bypassed");
            // If no error up to this point, then return true
            // return true;
            
            Messenger.Default.Send(new MoveInResponseMessage(portNo, true));
        }

        private bool CheckForMovedInAlready(string lot)
        {
            bool bRet = false;
            if (lot == null) return false;
            var p1l1Wafers = WaferGridInfo.Port1Wafers.Where(w => w.ContainerName == lot);
            if (p1l1Wafers == null || p1l1Wafers.Count() == 0)
                return true;
            foreach (Wafer w in p1l1Wafers)
            {
                string status = w.Status.ToUpper();
                if (status.Contains("MOVED IN") || status.Contains("MOVEDIN"))
                    bRet = true;
            }
            return bRet;
        }

        private bool MoveOutWafers()
        {
            // Sometimes as an edge test, this call comes in in the middle of a manual run..so we did not start it! 
            // So we have no lots, so bad things happen! 
            // So let's check! And just return true t okeep on flowing. 
            if (WaferGridInfo.Port1Wafers == null || WaferGridInfo.Port1Wafers.Count == 0)
                return true;

            string errMessage = "";
            string errMessage2 = "";
            string comment = "MoveOut at Complete for Lot #" + PortLotInfo.Port1Lot1 + " by Factory Automation";
            bool movedOut1 = false;
            bool movedOut2 = false;
            bool validateData = CurrentToolConfig.MoveOutValidateData;

            // Try to moveout lot1
            // if there is an error, display and return 
            // if ok, then display moved out for lot1, and try to move out lot2
            // if there is an error, display error 
            // return from method
            //
            //SHMMoveOut(string sContainer, ref string strErrMsg, 
            //                  bool RequiredCertification, string sEmployee = "", 
            //                  string sComments = "");
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot1))
            {
                MyLog.Information($"MES->MoveOut(Lot1={PortLotInfo.Port1Lot1},  ref errMsg, {validateData}, {PortLotInfo.OperatorID}, {comment})");
                movedOut1 = _mesService.MoveOut(PortLotInfo.Port1Lot1, ref errMessage, validateData, PortLotInfo.OperatorID, comment);
                MyLog.Information($"MES->MoveOut returned: movedOut={movedOut1},  errMsg={errMessage}");
                if (movedOut1 == false)
                {
                    string errString = $"MES->MoveOut:Error moving out lot #{PortLotInfo.Port1Lot1}: {errMessage}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot1, "ERROR on MoveOut"));
                    MyLog.Error(errString);
                    return false;
                }
                else
                {
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot1, WaferStatus.MovedOut.ToString()));
                }
            }
            else
                MyLog.Information($"MES->MoveOut Lot1 is empty, so it was bypassed");


            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2))
            {
                comment = "MoveOut at complete for Lot #" + PortLotInfo.Port1Lot2;
                MyLog.Information($"MES->MoveOut2(Lot2={PortLotInfo.Port1Lot2},  ref errMessage2, {validateData}, {PortLotInfo.OperatorID}, {comment})");
                movedOut2 = _mesService.MoveOut(PortLotInfo.Port1Lot2, ref errMessage2, validateData, PortLotInfo.OperatorID, comment);
                MyLog.Information($"MES->MoveOut2 returned: movedOut={movedOut2},  errMsg={errMessage2}");
                if (movedOut2 == false)
                {
                    string errString = $"Error moving out lot #{PortLotInfo.Port1Lot2}: {errMessage2}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot2, "ERROR on MoveOut"));
                    MyLog.Error(errString);
                    return false;
                }
                else
                {
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot2, WaferStatus.MovedOut.ToString()));
                }
            }
            else
                MyLog.Information($"MES->MoveOut2 Lot2 is empty, so it was bypassed");
            return true;
        }

        private bool HoldWafers(string comment)
        {
            string errMessage = "";
            string holdReason = "Other"; // Peer ZH 3/3/19
            bool holdLot1 = false;
            bool holdLot2 = false;

            // Try to hold lots
            // if there is an error, display and return 
            // if ok, then display Hold for lot1, and try to Hold lot2
            // if there is an error, display error 
            // return from method
            //
            // bool SHMHold(string container, string holdReason, ref string errorMsg,
            //              string comment, string factory, string employee, string resourceName);
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot1))
            {
                MyLog.Information($"MES->HoldWafer(Lot1={PortLotInfo.Port1Lot1},  {holdReason}, ref errMsg, {comment}, {factoryName}, {PortLotInfo.OperatorID}, {PortLotInfo.ToolID})");
                holdLot1 = _mesService.Hold(PortLotInfo.Port1Lot1, holdReason, ref errMessage, comment, factoryName, PortLotInfo.OperatorID, PortLotInfo.ToolID);
                MyLog.Information($"MES->HoldWafer1 returned: holdLot1={holdLot1},  errMsg={errMessage}");
                if (holdLot1 == false)
                {
                    string errString = $"MES->HoldWafers2:Error putting lot #{PortLotInfo.Port1Lot1} on Hold: {errMessage}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    //SetAllWafersStatus(PortLotInfo.Port1Lot1, "ERROR on HOLD request to Camstar, Lot Aborted");
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot1, "ERROR on HOLD request to Camstar, Lot Aborted"));
                    MyLog.Error(errString);
                    return false;
                }
                else
                {
                    //SetAllWafersStatus(PortLotInfo.Port1Lot1, WaferStatus.Hold.ToString());
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot1, WaferStatus.Hold.ToString()));
                }
            }
            else
                MyLog.Information($"MES->HoldWafers Lot1 is empty, so it was bypassed");

            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2))
            {
                MyLog.Information($"MES->HoldWafer2(Lot2={PortLotInfo.Port1Lot2},  {holdReason}, ref errMsg, {comment}, {factoryName}, {PortLotInfo.OperatorID}, {PortLotInfo.ToolID})");
                holdLot2 = _mesService.Hold(PortLotInfo.Port1Lot2, holdReason, ref errMessage, comment, factoryName, PortLotInfo.OperatorID, PortLotInfo.ToolID);
                MyLog.Information($"MES->HoldWafer2 returned: holdLot2={holdLot2},  errMsg={errMessage}");

                if (holdLot2 == false)
                {
                    string errString = $"MES->HoldWafers2:Error putting lot #{PortLotInfo.Port1Lot2} on Hold: {errMessage}";
                    var vm = new DialogViewModel(errString, "", "Ok");
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        dialogService.ShowDialog(vm);
                    });
                    //SetAllWafersStatus(PortLotInfo.Port1Lot2, "ERROR on HOLD request to Camstar, Lot Aborted");
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot2, "ERROR on HOLD request to Camstar, Lot Aborted"));
                    MyLog.Error(errString);
                    return false;
                }
                else
                {
                    //SetAllWafersStatus(PortLotInfo.Port1Lot2, WaferStatus.Hold.ToString());
                    Messenger.Default.Send(new SetAllWafersStatusMessage(0, PortLotInfo.Port1Lot2, WaferStatus.Hold.ToString()));
                }
            }
            else
                MyLog.Information($"MES->HoldWafers Lot2 is empty, so it was bypassed");

            return true;
        }

        private bool UploadData()
        {
            // Sometimes as an edge test, this call comes in in the middle of a manual run..so we did not start it! 
            // So we have no lots, so bad things happen! 
            // So let's check! And just return true t okeep on flowing. 
            if (WaferGridInfo.Port1Wafers == null || WaferGridInfo.Port1Wafers.Count == 0)
                return true;

            bool goodUpload = true;
            try
            {
                Dictionary<string, string> dataToUpload = currentTool.UploadData();
                //string[] uploadArray = dataToUpload?.Values.ToArray();
                if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot1))
                {
                    MyLog.Information($"MES->ExecuteDC(Lot1={PortLotInfo.Port1Lot1}, WF_FMT_P_DATA, WF_FMT_P_DATA, {dataToUpload}, {PortLotInfo.OperatorID}, Data Upload for {PortLotInfo.ToolID} by Factory Automation)");
                    string uploadString = $"Uploading Data({CurrentToolConfig.Loadports[0]}, Lot1:{PortLotInfo.Port1Lot1} and Lot2:{PortLotInfo.Port1Lot2}, {CurrentRecipe}, {PortLotInfo.OperatorID})";
                    uploadString += Environment.NewLine + "\t\t\t\t\t" + "Uploaded Data:";
                    foreach (var entry in dataToUpload)
                    {
                        uploadString += (Environment.NewLine + "\t\t\t\t\t" + entry.Key + ": " + entry.Value);
                    }
                    MyLog.Information(uploadString);

                    string retString1 = _mesService.ExecuteDC(PortLotInfo.Port1Lot1, "WF_FMT_P_DATA", "WF_FMT_P_DATA", dataToUpload, PortLotInfo.OperatorID, "Data Upload for " + PortLotInfo.ToolID + " by Factory Automation");
                    MyLog.Information($"MES->ExecuteDC returned string={retString1}");
                }
                else
                    MyLog.Information($"MES->Upload Lot1 is empty, so it was bypassed");

                if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2))
                {
                    MyLog.Information($"MES->ExecuteDC2(Lot2={PortLotInfo.Port1Lot2}, WF_FMT_P_DATA, WF_FMT_P_DATA, {dataToUpload}, {PortLotInfo.OperatorID}, Data Upload for {PortLotInfo.ToolID} by Factory Automation)");
                    string retString2 = _mesService.ExecuteDC(PortLotInfo.Port1Lot2, "WF_FMT_P_DATA", "WF_FMT_P_DATA", dataToUpload, PortLotInfo.OperatorID, "Data Upload for " + PortLotInfo.ToolID + " by Factory Automation");
                    MyLog.Information($"MES->ExecuteDC2 returned string={retString2}");
                }
                else
                    MyLog.Information($"MES->Upload Lot2 is empty, so it was bypassed");
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "ERROR in UploadData())");
                goodUpload = false;
            }
            return goodUpload;
        }

        #endregion

        public ICommand CloseAlarmCmd => new RelayCommand(closeAlarmCmdHandler);
        public ICommand AlarmListingCmd => new RelayCommand(alarmListingCmdHandler);
        public ICommand LogListingCmd => new RelayCommand(logListingCmdHandler);

        public ICommand CamstarCmd => new RelayCommand(camstarCmdHandler);
        public ICommand ResetHostCmd => new RelayCommand(resetHostCmdHandler);
        public ICommand ExitHostCmd => new RelayCommand(exitHostCmdHandler);
        
        public void closeAlarmCmdHandler()
        {
            Messenger.Default.Send(new CloseAlarmMessage());
            CurrentAlarm = "";            
        }
      
     

        private void alarmListingCmdHandler()
        {
            Messenger.Default.Send(new ToggleAlarmViewMessage());
        }

        private void logListingCmdHandler()
        {
            Messenger.Default.Send(new ToggleLogViewMessage());
        }

        private void resetHostCmdHandler()
        {
            var vm = new DialogViewModel("Are you sure you want to Reset Host?", "Yes", "No");
            bool? result = dialogService.ShowDialog(vm);
            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                MyLog.Information("Reset Host called...");
                // 3/3/19 - Per ZH: Took out putting on hold for now
                //if (AreThereWafers)
                //    HoldWafers("ResetHost by Factory Automation for " + PortLotInfo.OperatorID);
                emailViewHandler("Resetting Host");
                Messenger.Default.Send(new ReInitializeSystemMessage(0));
            }
            else
            {

            }
        }


        #region EMAIL HANDLERS

        private string GetEmailAddresses()
        {
            string emails = "";
            foreach (string emailAddress in CurrentToolConfig.PrimaryEmailAddressees)
                emails += emailAddress + ";";
            return emails; 
        }
        private string GetAlarmEmailAddresses()
        {
            string emails = "";
            foreach (string emailAddress in CurrentToolConfig.EmailAddresseesForAlarms)
                emails += emailAddress + ";";
            return emails;
        }
        private void emailViewHandler(string subject)
        {
            string sendTo = GetEmailAddresses();
            string bodyText = $"{DateTime.Now.ToString()} EVENT VALUES: Operator:{PortLotInfo.OperatorID} ToolID:{PortLotInfo.ToolID}" + Environment.NewLine;
            bodyText += $"Lot1:{PortLotInfo.Port1Lot1}";
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2)) bodyText += $" Lot2:{PortLotInfo.Port1Lot2}";

            if (CurrentToolConfig.Dialogs.ShowEmailBox)
            {
                var vm = new EmailViewModel(sendTo, subject, bodyText);
                var view = new EmailView() { DataContext = vm, WindowStartupLocation = WindowStartupLocation.CenterScreen };
                view.ShowDialog();
            }
            else
                Messenger.Default.Send(new CloseAndSendEmailMessage(sendTo, subject, bodyText));
        }
        private void logEmailHandler(EventMessage msg)
        {
            string sendTo = GetEmailAddresses();
            string bodyText = $"{msg.MsgDateTime} LOG ENTRY: Operator:{PortLotInfo.OperatorID} ToolID:{PortLotInfo.ToolID}" + Environment.NewLine;
            bodyText += $"Lot1:{PortLotInfo.Port1Lot1}";
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2)) bodyText += $" Lot2:{PortLotInfo.Port1Lot2}";

            bodyText += Environment.NewLine;
            bodyText += Environment.NewLine;
            bodyText += msg.Message;

            if (CurrentToolConfig.Dialogs.ShowEmailBox)
            {
                var vm = new EmailViewModel(sendTo, "FAS Log Entry", bodyText);
                var view = new EmailView() { DataContext = vm, WindowStartupLocation = WindowStartupLocation.CenterScreen };
                view.ShowDialog();
            }
            else
                Messenger.Default.Send(new CloseAndSendEmailMessage(sendTo, "FAS Log Entry", bodyText));
        }

        private void alarmEmailHandler(DateTime alarmTime,string subject)
        {
            string sendTo = GetAlarmEmailAddresses();
            string bodyText = $"{alarmTime.ToString()} CRITICAL ALARM: Operator: {PortLotInfo.OperatorID} ToolID: {PortLotInfo.ToolID}" + Environment.NewLine;
            bodyText += $"Lot1:{PortLotInfo.Port1Lot1}";
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2)) bodyText += $" Lot2:{PortLotInfo.Port1Lot2}";

            bodyText += Environment.NewLine;
            bodyText += Environment.NewLine;
            bodyText += subject;

            if (CurrentToolConfig.Dialogs.ShowEmailBox)
            {
                var vm = new EmailViewModel(sendTo, subject, bodyText);
                var view = new EmailView() { DataContext = vm, WindowStartupLocation = WindowStartupLocation.CenterScreen };
                view.ShowDialog();
            }
            else
                Messenger.Default.Send(new CloseAndSendEmailMessage(sendTo, subject, bodyText));
        }
        private void errorEmailHandler(string errorText)
        {
            string sendTo = GetEmailAddresses();
            string bodyText = $"{DateTime.Now.ToString()} CRITICAL ERROR: Operator: {PortLotInfo.OperatorID} ToolID: {PortLotInfo.ToolID}" + Environment.NewLine;
            bodyText += $"Lot1:{PortLotInfo.Port1Lot1}";
            if (!string.IsNullOrEmpty(PortLotInfo.Port1Lot2)) bodyText += $" Lot2:{PortLotInfo.Port1Lot2}";

            bodyText += Environment.NewLine;
            bodyText += Environment.NewLine;
            bodyText += errorText;

            if (CurrentToolConfig.Dialogs.ShowEmailBox)
            {
                var vm = new EmailViewModel(sendTo, "CRITICAL ERROR", bodyText);
                var view = new EmailView() { DataContext = vm, WindowStartupLocation = WindowStartupLocation.CenterScreen };
                view.ShowDialog();
            }
            else
                Messenger.Default.Send(new CloseAndSendEmailMessage(sendTo, "CRITICAL ERROR", bodyText));
        }

        private void CloseEmailResponseMsgHandler(CloseAndSendEmailMessage msg)
        {
            if (!string.IsNullOrEmpty(msg.SendTo))
            {
                string fromAddress = CurrentSystemConfig.FromEmailAddress;
                MailMessage message = new MailMessage();
                message.From = new MailAddress(fromAddress);
                message.Subject = msg.Subject;
                message.Body = msg.EmailBody;

                foreach (var address in msg.SendTo.Split(new[] { ";" }, StringSplitOptions.RemoveEmptyEntries))
                {
                    message.To.Add(address);
                }

                SmtpClient client = new SmtpClient(CurrentSystemConfig.EmailServer, CurrentSystemConfig.EmailPort);
                client.Timeout = 100;
                // Credentials are necessary if the server requires the client 
                // to authenticate before it will send e-mail on the client's behalf.
                client.Credentials = CredentialCache.DefaultNetworkCredentials;

                try
                {
#if RELEASE
                    client.Send(message);
#endif
                }
                catch (Exception ex)
                {
                    MyLog.Error(ex, ex.Message);
                }
            }
            else
            {
                var vm = new DialogViewModel("Operator cancelled the sending of email", "", "Ok");
                dialogService.ShowDialog(vm);
            }
        }
#endregion

        private void exitHostCmdHandler()
        {
            var vm = new DialogViewModel("Are you sure you want to Exit Host?", "Yes", "No");
            bool? result = dialogService.ShowDialog(vm);
            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                MyLog.Information($"Exit Host called: EVENT VALUES: Operator:{PortLotInfo.OperatorID} ToolID:{PortLotInfo.ToolID}");
                emailViewHandler("Exiting Host");
                if (Globals.AshlServer != null)
                    AshlServer.requestStopAndJoin();
                if (TheTraceDataCollector != null)
                {
                    TheTraceDataCollector.CloseDataFile();
                    TheTraceDataCollector = null;
                }

                _mesService.CloseConnection();

                Application.Current.Shutdown();
            }
            else
            {

            }
        }

        // Testing as complete
        private void camstarCmdHandler()
        {
            string htmLink = CurrentSystemConfig.CamstarURL;
            
            try
            {
                 System.Diagnostics.Process.Start(htmLink);
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, ex.Message);
            }

        }
    }    
}