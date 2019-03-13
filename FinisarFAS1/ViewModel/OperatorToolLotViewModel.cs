using Common;
using FinisarFAS1.Utility;
using FinisarFAS1.View;
using GalaSoft.MvvmLight;
using GalaSoft.MvvmLight.Command;
using GalaSoft.MvvmLight.Messaging;
using MESCommunications;
using MESCommunications.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using static Common.Globals; 

namespace FinisarFAS1.ViewModel
{
    public class OperatorToolLotViewModel : ViewModelBase 
    {
        private readonly IDialogService2 dialogService;
        private MESService _mesService;
        private int thisPortNo; 

        private int thisPortWaferCount ; 

        public OperatorToolLotViewModel(int portNo, bool usingMoq)
        {
            IDialogService2 dialogService1 = new MyDialogService(null);
            dialogService1.Register<DialogViewModel, DialogWindow>();
            dialogService = dialogService1;
            thisPortNo = portNo; 

            thisPortWaferCount = 0;

            if (usingMoq)
                _mesService = new MESService(new MoqMESService());
            else
                _mesService = new MESService(new MESDLL());

            Port1Lot1Color = Port1Lot2Color = "White";
            ShowConfirmButtons = true;
            IsRecipeOverridable = false;
            Lot1Enabled = Lot2Enabled = true;
            Engineer = EngineeringRun = false;
            BusyOp = false;

            RegisterForMessages();
        }

        public void RegisterForMessages()
        {
            Messenger.Default.Register<ReInitializeSystemMessage>(this, ReInitializeSystemHandler);
            Messenger.Default.Register<UpdateRecipeAndRunTypeMessage>(this, updateOtherPortLotInfoMsgHandler);

            Messenger.Default.Register<CamstarStatusMessage>(this, UpdateCamstarStatusHandler);
            Messenger.Default.Register<ControlStateChangeMessage>(this, UpdateControlStateHandler);
            Messenger.Default.Register<ProcessStateChangeMessage>(this, UpdateProcessStateHandler);

            //Messenger.Default.Register<WaferCountMessage>(this, waferCountMsgHandler);
            Messenger.Default.Register<MoveInResponseMessage>(this, moveInResponseMsgHandler);
            Messenger.Default.Register<PortStartedMessage>(this, startPortMsgHandler);
            Messenger.Default.Register<OperatorResponseMessage>(this, updateOperatorMsgHandler);

            //Messenger.Default.Register<WafersConfirmedMessage>(this, WafersConfirmedHandler);
            //Messenger.Default.Register<WafersInGridMessage>(this, WafersInGridHandler);

        }

        private bool CamstarUp = false;
        private bool EquipmentReady = false;
        private bool ProcessStateReady = false;  

        private void UpdateCamstarStatusHandler(CamstarStatusMessage msg)
        {
            CamstarUp = msg.IsAvailable;
        }

        private void UpdateControlStateHandler(ControlStateChangeMessage msg)
        {
            EquipmentReady = msg.ControlState == ControlStates.REMOTE; 
        }
        
        private void UpdateProcessStateHandler(ProcessStateChangeMessage msg)
        {
            string tempStatus = msg.Description;
            string tempColor = "White";

            if (msg.PortNo != thisPortNo) return;

            // if (Aborted) return;

            if (msg.ProcessState == ProcessStates.EXECUTING)
            {
                tempColor = "DodgerBlue";
                Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, Port1Lot1, "Executing..."));
                if (!string.IsNullOrEmpty(Port1Lot2))
                    Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, Port1Lot2, "Executing..."));
            }
            else if (msg.ProcessState == ProcessStates.NOTREADY)
                tempColor = "Red";
            else if (msg.ProcessState == ProcessStates.READY)
                tempColor = "Azure";
            else if (msg.ProcessState == ProcessStates.WAIT)
                tempColor = "Yellow";
            else if (msg.ProcessState == ProcessStates.NOTTALKING)
            {
                ProcessState = "NO TOOL";
                tempColor = "Red";
            }

            ProcessStateReady = msg.ProcessState == ProcessStates.READY;
            ProcessState = msg.Description;
            ProcessStateColor = tempColor;
        }

        private string _processState;
        public string ProcessState
        {
            get { return "Process State: " + _processState; }
            set
            {
                _processState = value;
                RaisePropertyChanged(nameof(ProcessState));
            }
        }

        private string _processStateColor;
        public string ProcessStateColor
        {
            get { return _processStateColor; }
            set
            {
                _processStateColor = value;
                RaisePropertyChanged(nameof(ProcessStateColor));
            }
        }

        private void ReInitializeSystemHandler(ReInitializeSystemMessage msg)
        {
            if (msg.fullReset == 0)
            {
                OperatorID = ToolID = "";
                Messenger.Default.Send(new EngineerViewMessage(thisPortNo, false)); 
            }
            Port1Lot1 = Port1Lot2 = "";
            Step = Spec = Status = "";
            CurrentOperation = Recipe = Product = Comments = "";
            Confirmed = false;
            if (msg.fullReset == 0)
                Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
            else
                Messenger.Default.Send(new ReFocusMessage(string.Empty, null));

        }

        private void updateOtherPortLotInfoMsgHandler(UpdateRecipeAndRunTypeMessage msg)
        {
            if (msg.PortNo != thisPortNo) return; 

            if (msg.listWafers!=null && msg.listWafers.Count>0)
            {
                List<Wafer> wafers = msg.listWafers; 
                thisPortWaferCount = wafers.Count;
                if (wafers[0].ContainerType == "T" || wafers[0].ContainerType == "R")
                    EngineeringRun = true;
                else
                    EngineeringRun = false; 
            }
        }     

        private void startPortMsgHandler(PortStartedMessage msg)
        {
            if (msg.PortNo == thisPortNo)
                StartedPort = true; 
        }

        #region UI BINDINGS


        private bool _busyOp;
        public bool BusyOp {
            get { return _busyOp; }
            set { _busyOp = value; RaisePropertyChanged(nameof(BusyOp)); }
        }

        #region OPERATOR TOOL LOT CONFIRM CANCEL RECIPE PROCESSTSTATE

        private void updateOperatorMsgHandler(OperatorResponseMessage msg)
        {
            if (msg.PortNo != thisPortNo) return;
            AuthorizationLevel authLevel = msg.authLevel;
            BusyOp = false;
            OperatorStatus = authLevel == AuthorizationLevel.InvalidUser ? "../Images/CheckBoxRed.png" : "../Images/CheckBoxGreen.png";
            if (authLevel == AuthorizationLevel.InvalidUser)
            {
                if (!string.IsNullOrEmpty(OperatorID))
                {
                    Application.Current.Dispatcher.Invoke((Action)delegate
                    {
                        var vm = new DialogViewModel($"Invalid Operator ID {OperatorID} entered! Please re-enter", "", "Ok");
                        dialogService.ShowDialog(vm);
                        _operatorID = "";
                        Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
                        Engineer = false;
                    });
                }
            }
            else if (authLevel == AuthorizationLevel.Engineer)
            {
                IsRecipeOverridable = true;
                Engineer = true;
                Messenger.Default.Send(new ReFocusMessage("ToolField", null));
                RaisePropertyChanged(nameof(OperatorID));
                RaisePropertyChanged(nameof(OperatorLevel));
            }
            else
            {
                IsRecipeOverridable = false;
                Engineer = false;
                RaisePropertyChanged(nameof(OperatorID));
                RaisePropertyChanged(nameof(OperatorLevel));
            }

            if (authLevel!=AuthorizationLevel.InvalidUser)
            {
                Messenger.Default.Send(new CurrentOperatorMessage(OperatorID, authLevel)); 
            }

            OperatorLevel = authLevel.ToString();
            MyLog.Debug($"MES->ValidateEmployee->UpdateOperatorMsgHandler sets OperatorLevel=({OperatorLevel})");

            //RaisePropertyChanged(nameof(OperatorID));
            //RaisePropertyChanged(nameof(OperatorLevel));

            //if (string.IsNullOrEmpty(_operatorID))
            //    Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
            //else
            //    Messenger.Default.Send(new ReFocusMessage(string.Empty, null));
        }

        private string _operatorID;
        public string OperatorID {
            get { return _operatorID; }
            set {

                _operatorID = value;
                if (!string.IsNullOrEmpty(_operatorID))
                {
                    BusyOp = true;
                    AuthorizationLevel authLevel = AuthorizationLevel.InvalidUser;
                    MyLog.Information($"MES->ValidateEmployee({_operatorID})");
#if DEBUG
                        Task.Delay(1000).ContinueWith(_ =>
	                    {
                            authLevel = _mesService.ValidateEmployee(_operatorID);
                            MyLog.Information($"MES->ValidateEmployee returned ({authLevel.ToString()})");
                            if(authLevel == AuthorizationLevel.InvalidUser)
                            {
                                _operatorID = string.Empty;
                            }
                            Messenger.Default.Send(new OperatorResponseMessage(thisPortNo, authLevel));
                            RaisePropertyChanged(nameof(OperatorID));
                            RaisePropertyChanged(nameof(OperatorColor));
                            RaisePropertyChanged(nameof(IsRecipeOverridable));

                            if (string.IsNullOrEmpty(_operatorID))
                                Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
                            else
                                Messenger.Default.Send(new ReFocusMessage("ToolField", null));
                        });
#else
                    authLevel = _mesService.ValidateEmployee(_operatorID);
                    MyLog.Information($"MES->ValidateEmployee returned ({authLevel.ToString()})");
                    Messenger.Default.Send(new OperatorResponseMessage(thisPortNo, authLevel));

                    RaisePropertyChanged(nameof(OperatorID));
                    RaisePropertyChanged(nameof(OperatorColor));
                    RaisePropertyChanged(nameof(IsRecipeOverridable));

                    if (string.IsNullOrEmpty(OperatorID))
                    {
                        Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
                    }
                    else
                    {
                        Messenger.Default.Send(new ReFocusMessage("ToolField", null));
                    }
#endif
                }
                else
                {
                    OperatorLevel = AuthorizationLevel.InvalidUser.ToString();
                    Engineer = false; 

                    RaisePropertyChanged(nameof(OperatorID));
                    RaisePropertyChanged(nameof(OperatorColor));
                    RaisePropertyChanged(nameof(IsRecipeOverridable));

                    Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
                }

                //RaisePropertyChanged(nameof(OperatorID));
                //RaisePropertyChanged(nameof(OperatorColor));
                //RaisePropertyChanged(nameof(IsRecipeOverridable));

                //if (string.IsNullOrEmpty(OperatorID))
                //{
                //    Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
                //}
            }
        }

        private string _opLevel;
        public string OperatorLevel {
            get { return _opLevel; }
            set { _opLevel = value; RaisePropertyChanged(nameof(OperatorLevel)); }
        }

        private bool engineer;
        public bool Engineer
        {
            get { return engineer; }
            set
            {
                engineer = value;
                RaisePropertyChanged(nameof(Engineer));
                //RaisePropertyChanged(nameof(NotEngineer));
                Messenger.Default.Send(new EngineerViewMessage(thisPortNo, engineer));
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

        //public bool NotEngineer => !Engineer;

        //private string _opColor;
        public string OperatorColor
        {
            get
            {
                if (OperatorStatus == "../Images/CheckBoxRed.png")
                    return "red";
                else
                    return "lime";
            }
        }

        private string _tool;
        public string ToolID {
            get { return _tool; }
            set {
                _tool = value;
                if (string.IsNullOrEmpty(_tool)) {
                    RaisePropertyChanged(nameof(ToolID));
                    ToolStatus = "../Images/CheckBoxRed.png";
                }
                else if (value == CurrentToolConfig.Toolid) {
                    ToolStatus = "../Images/CheckBoxGreen.png";
                    Messenger.Default.Send(new ReFocusMessage("Lot1", null));
                }
                else {
                    MyLog.Debug($"MainVM->ToolID error: {_tool}!={CurrentToolConfig.Toolid}");
                    var vm = new DialogViewModel("Invalid Tool ID entered! Please re-enter", "", "Ok");
                    dialogService.ShowDialog(vm);
                    ToolStatus = "../Images/CheckBoxRed.png";
                    _tool = "";
                    Application.Current.Dispatcher.Invoke(()=>
                        Messenger.Default.Send(new ReFocusMessage("ToolField", null))
                        );
                }
                RaisePropertyChanged(nameof(ToolID));
            }
        }

        private string _operatorStatus;
        public string OperatorStatus {
            get { return _operatorStatus; }
            set {
                _operatorStatus = value;
                RaisePropertyChanged(nameof(OperatorStatus));
            }
        }

        private string _toolStatus;
        public string ToolStatus {
            get { return _toolStatus; }
            set {
                _toolStatus = value;
                RaisePropertyChanged(nameof(ToolStatus));
            }
        }

        private bool _isRecipeOverridable;
        public bool IsRecipeOverridable {
            get { return _isRecipeOverridable; }
            set {
                if (DisabledAfterStart == true)
                    _isRecipeOverridable = false;
                else if (OperatorLevel == AuthorizationLevel.Engineer.ToString() && thisPortWaferCount > 0)
                {
                    // TODO : Change this later
                    if (EngineeringRun)
                        _isRecipeOverridable = true;
                }
                else
                {
                    _isRecipeOverridable = false;
                }
                RaisePropertyChanged(nameof(IsRecipeOverridable));
            }
        }

        // TODO: 
        private bool _started;
        public bool StartedPort {
            get { return _started; }
            set {
                _started = value;
                RaisePropertyChanged(nameof(StartedPort));
                RaisePropertyChanged(nameof(DisabledAfterStart));
                if (value == true)
                    IsRecipeOverridable = false;
            }
        }

        public bool DisabledAfterStart => !StartedPort;

        private bool showConfirmButtons;
        public bool ShowConfirmButtons {
            get { return showConfirmButtons; }
            set { showConfirmButtons = value; RaisePropertyChanged(nameof(ShowConfirmButtons)); }
        }

        private bool _confirmed;
        public bool Confirmed {
            get { return _confirmed; }
            set {
                _confirmed = value;
                RaisePropertyChanged(nameof(Confirmed));
                ShowConfirmButtons = !value;
            }
        }

        #endregion

        #region LOT STUFF

        DataTable dtWafers;

        private string _port1Lot1;
        public string Port1Lot1 {
            get { return _port1Lot1; }
            set {
                //MyLog.Debug("Port1Lot1->Setter start...");
                if (string.IsNullOrEmpty(value))
                {
                    _port1Lot1 = "";
                    Lot1Enabled = true; 
                    RaisePropertyChanged(nameof(Port1Lot1));
                    Messenger.Default.Send(new ReFocusMessage("Lot1", null));
                }
                else
                if (_port1Lot1 != value)
                {
                    // If the value is not empty or equal to what is already there...
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Loading Wafers from Camstar..."));
                    _port1Lot1 = value; 
                    GetWafersLot1A(value);
                }
            }
        }

        private async void GetWafersLot1A(string lotId)
        {
            try
            {
                MyLog.Information($"GetWafersPort1Async->_mesService.GetContainerStatus({lotId})");
                dtWafers = await Task.Run(() => _mesService.GetContainerStatus(lotId));
                if (dtWafers == null)
                    MyLog.Information($"GetWafersPort1Async->_mesService.GetContainerStatus({lotId}) returned no wafers");
                else
                    MyLog.Information($"GetWafersPort1Async->_mesService.GetContainerStatus({lotId}) returned some wafers");

            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "GetWafersLot1Async()");
            }
            finally
            {
                await Task.Delay(1000).ContinueWith(_ =>
                {
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));

                });
                MyLog.Debug("GetWafersLot1Async->Set LoadingWafers=false");
                ConvertAndAddToGrid(dtWafers, lotId); 

                if (string.IsNullOrWhiteSpace(_port1Lot1))
                    Messenger.Default.Send(new ReFocusMessage("Lot1", null));
                else
                    Messenger.Default.Send(new ReFocusMessage("Lot2", null));
            }
        }

        private void ConvertAndAddToGrid(DataTable dtWafers, string lot1Id)
        {
            string errString = string.Empty;
            // string lot1Id = msg.lotID;

            MyLog.Debug($"GetWafersPort1Async->ConvertAndAddToGrid() start...");
            MyLog.Debug($"GetWafersPort1Async->MakeDataTableIntoWaferList()...");
            List<Wafer> wafers = DataHelpers.MakeDataTableIntoWaferList(dtWafers);

            MyLog.Debug($"GetWafersPort1Async->CheckWafers()...");
            bool goodWafers = CheckWafers(ref wafers, ref errString);

            if (goodWafers)
            {
                MyLog.Debug($"GetWafersPort1Async->AddWafersToGrid()...");
                // TODO: 
                // AddWafersToGrid(wafers);
                Messenger.Default.Send(new AddWafersToGridMessage(thisPortNo, wafers)); 
                try
                {
                    CurrentOperation = wafers[0].Operation;
                    Recipe = wafers[0].Recipe;
                    Product = wafers[0].Product;
                    Step = wafers[0].WorkFlowStepName;
                    Spec = wafers[0].SpecName;
                    Status = wafers[0].Status;
                    Comments = wafers[0].SpecialProcessInstructions;
                    _port1Lot1 = lot1Id;
                    RaisePropertyChanged(nameof(Port1Lot1));
                    Messenger.Default.Send(new UpdateRecipeAndRunTypeMessage(thisPortNo, wafers));
                }
                catch (Exception ex)
                {
                    MyLog.Error(ex, "Error in ConvertAndAddToGrid probably by wafers[0] somehow");
                }
            }

            if (dtWafers == null || !string.IsNullOrEmpty(errString))
            {
                if (dtWafers == null)
                {
                    errString = $"MES->GetContainerStatus:Error getting lot #{lot1Id}.";
                    MyLog.Information($"GetWafersPort1Async->_mesService.GetContainerStatus({lot1Id}) returned no wafers: dtWafers==null.");
                }
                MyLog.Information(errString);
                var vm = new DialogViewModel(errString + " Please enter a new lot id", "", "Ok");
                Application.Current.Dispatcher.Invoke((Action)delegate
                {
                    dialogService.ShowDialog(vm);
                });

                _port1Lot1 = "";
                //Messenger.Default.Send(new ReFocusMessage("Lot1" ,null));
            }
            RaisePropertyChanged(nameof(Port1Lot1));
            MyLog.Debug($"GetWafersPort1Async->LoadLot1MsgHandler() end");
            if (string.IsNullOrWhiteSpace(_port1Lot1))
                Messenger.Default.Send(new ReFocusMessage("Lot1", null));
            else
            {
                Messenger.Default.Send(new ReFocusMessage(string.Empty, null));
                Lot1Enabled = false; 
            }
        }

        private bool CheckWafers(ref List<Wafer> wafers, ref string errString)
        {
            bool goodLot = true;
            int numClose = 0;
            List<Wafer> goodWafers = new List<Wafer>();
            string lotNo = "";

            try
            {
                lotNo = wafers[0].ContainerName;

                foreach (Wafer w in wafers)
                {
                    if (w.Status.ToUpper().Equals("ACTIVE"))
                    {
                        goodWafers.Add(w);
                    }
                    else if (w.Status.ToUpper().Equals("CLOSE"))
                    {
                        ++numClose;
                    }
                    else
                    {
                        // Stop at first error
                        if (goodLot)
                        {
                            errString = $"{w.WaferNo} has an invalid status of {w.Status}.";
                            goodLot = false;
                        }
                    }
                }
                wafers = goodWafers;
            }
            catch (Exception ex)
            {
                goodLot = false;
                MyLog.Error(ex, "CheckWafers()");
            }
            return goodLot;
        }

        private string _port1Lot2;
        public string Port1Lot2 {
            get { return _port1Lot2; }
            set {
                //MyLog.Debug("Port1Lot2->Setter start...");
                if (string.IsNullOrEmpty(value))
                {
                    _port1Lot2 = "";
                    Messenger.Default.Send(new ReFocusMessage("Lot2", null));
                    RaisePropertyChanged(nameof(Port1Lot2));
                    RaisePropertyChanged(nameof(IsRecipeOverridable));
                    Lot2Enabled = true;
                }
                else if (Port1Lot1 == value)
                {
                    _port1Lot2 = "";
                    var vm = new DialogViewModel("Cannot enter same lots", "", "Ok");
                    dialogService.ShowDialog(vm);
                    Messenger.Default.Send(new ReFocusMessage("Lot2", null));
                    RaisePropertyChanged(nameof(Port1Lot2));
                }
                else if (_port1Lot2 != value)
                {
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Loading Wafers from Camstar..."));
                    _port1Lot2 = value;
                    GetWafersLot2Async(value);
                }

                if(string.IsNullOrEmpty(_port1Lot2))
                {
                }
            }
        }

        private async void GetWafersLot2Async(string lot2Id)
        {
            string errString = "";

            try
            {
                MyLog.Information($"GetWafersPort2Async->_mesService.GetContainerStatus({lot2Id})");
                DataTable dtWafers = await Task.Run(() => _mesService.GetContainerStatus(lot2Id));

                if (dtWafers == null)
                    MyLog.Information($"GetWafersPort2Async->_mesService.GetContainerStatus({lot2Id}) returned no wafers");
                else
                    MyLog.Information($"GetWafersPort2Async->_mesService.GetContainerStatus({lot2Id}) returned some wafers");
                if (dtWafers != null)
                {
                    var wafers = DataHelpers.MakeDataTableIntoWaferList(dtWafers);
                    // TODO: I think this check is wrong??!?!
                    //if (wafers[0].Recipe != CurrentRecipe)
                    //    errString = "ERROR: Recipe mismatch! Cannot use different recipes between lots!";
                    //else
                    {
                        //_port1Lot2 = lotId;
                        bool goodWafers = CheckWafers(ref wafers, ref errString);
                        if (goodWafers)
                        {
                            // AddWafersToTopGrid(wafers);
                            Messenger.Default.Send(new AddWafersToGridMessage(thisPortNo, wafers));
                            RaisePropertyChanged("Port1Wafers");
                            Lot2Enabled = false;
                            _port1Lot2 = lot2Id;
                        }
                        else
                        {
                            if (!string.IsNullOrEmpty(errString))
                            {
                                var vm = new DialogViewModel(errString, "", "Ok");
                                Application.Current.Dispatcher.Invoke((Action)delegate
                                {
                                    dialogService.ShowDialog(vm);
                                });
                            }
                            Lot2Enabled = true;
                            _port1Lot2 = "";
                            Messenger.Default.Send(new ReFocusMessage("Lot2", null));
                        }
                    }
                }
                // else
                {
                    if (dtWafers == null || !string.IsNullOrEmpty(errString))
                    {
                        Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));
                        if (dtWafers == null)
                            errString = $"MES->GetContainerStatus:Error getting lot #{lot2Id}.";
                        MyLog.Information(errString);
                        var vm = new DialogViewModel(errString, "", "Ok");
                        Application.Current.Dispatcher.Invoke((Action)delegate
                        {
                            dialogService.ShowDialog(vm);
                        });
                        _port1Lot2 = "";
                        Lot2Enabled = true;
                        Port1Lot2Color = "White";
                        Messenger.Default.Send(new ReFocusMessage("Lot2", null));
                    }
                }
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "GetWafersLot2Async()");
                _port1Lot2 = "";
                RaisePropertyChanged(nameof(Port1Lot2));
                Lot2Enabled = true;
                Port1Lot2Color = "White";
            }
            finally
            {
                //await Task.Delay(0).ContinueWith(_ =>
                //{
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));

                //});
                RaisePropertyChanged(nameof(IsRecipeOverridable));
                RaisePropertyChanged(nameof(Port1Lot2));
               // if (string.IsNullOrWhiteSpace(_port1Lot2) || _port1Lot2==_port1Lot1)
               if(!string.IsNullOrEmpty(errString))
                    Messenger.Default.Send(new ReFocusMessage("Lot2", null));
            }
        }

        private string _port1Lot1Color;
        public string Port1Lot1Color {
            get { return _port1Lot1Color; }
            set {
                _port1Lot1Color = value;
                Port1Lot1Error = value.Equals("Red");
                RaisePropertyChanged(nameof(Port1Lot1Color));
            }
        }

        private string _port1Lot2Color;
        public string Port1Lot2Color {
            get { return _port1Lot2Color; }
            set {
                _port1Lot2Color = value;
                Port1Lot2Error = value.Equals("Red");
                RaisePropertyChanged(nameof(Port1Lot2Color));
            }
        }

        private bool _port1Lot1Error;
        public bool Port1Lot1Error {
            get { return _port1Lot1Error; }
            set { _port1Lot1Error = value; RaisePropertyChanged(nameof(Port1Lot1Error)); }
        }

        private bool _port1Lot2Error;
        public bool Port1Lot2Error {
            get { return _port1Lot2Error; }
            set { _port1Lot2Error = value; RaisePropertyChanged(nameof(Port1Lot2Error)); }
        }

        private bool _lot1Enabled;
        public bool Lot1Enabled {
            get {
                if (StartedPort) return false;
                return _lot1Enabled;
            }
            set {
                _lot1Enabled = value;
                RaisePropertyChanged(nameof(Lot1Enabled));
            }
        }

        private bool _lot2Enabled;
        public bool Lot2Enabled {
            get {
                if (StartedPort) return false;
                return _lot2Enabled;
            }
            set { _lot2Enabled = value; RaisePropertyChanged(nameof(Lot2Enabled)); }
        }
        #endregion



        #region OPERATOR VIEW UI BINDINGS
        private string _operation;
        public string CurrentOperation
        {
            get { return _operation; }
            set { _operation = value; RaisePropertyChanged(nameof(CurrentOperation)); }
        }

        private string _recipe;
        public string Recipe
        {
            get { return _recipe; }
            set { _recipe = value; RaisePropertyChanged(nameof(Recipe)); }
        }

        private string _product;
        public string Product
        {
            get { return _product; }
            set { _product = value; RaisePropertyChanged(nameof(Product)); }
        }

        private string _comment;
        public string Comments
        {
            get { return _comment; }
            set { _comment = value; RaisePropertyChanged(nameof(Comments)); }
        }

        private string _step;
        public string Step
        {
            get { return _step; }
            set { _step = value; RaisePropertyChanged(nameof(Step)); }
        }

        private string _spec;
        public string Spec
        {
            get { return _spec; }
            set { _spec = value; RaisePropertyChanged(nameof(Spec)); }
        }

        private string _field6;
        public string Status
        {
            get { return _field6; }
            set { _field6 = value; RaisePropertyChanged(nameof(Status)); }
        }

        #endregion

        #endregion

        #region CMD HANDLERS

        public ICommand ConfirmPort1Cmd => new RelayCommand(confirmPort1CmdHandler);
        public ICommand CancelPort1Cmd => new RelayCommand(cancelPort1CmdHandler);

        public ICommand DeleteLot1Cmd => new RelayCommand(deleteLot1CmdHandler);
        public ICommand DeleteLot2Cmd => new RelayCommand(deleteLot2CmdHandler);


        private void confirmPort1CmdHandler()
        {
            bool? result = true;
            string newline = Environment.NewLine;

            // First check if we can confirm
            string cantConfirm = "";

            if (string.IsNullOrEmpty(OperatorID) ||
                OperatorLevel == null ||
                OperatorLevel.Equals("InvalidUser"))
                cantConfirm = "- Must have a valid Operator " + newline;

            if (ToolStatus == null || ToolStatus == "../Images/CheckBoxRed.png")
                cantConfirm += "- Must have a valid Tool " + newline;

            // TODO: 
            if (string.IsNullOrEmpty(Port1Lot1) && string.IsNullOrEmpty(Port1Lot2))
                cantConfirm += "- Must enter some valid lots " + newline;

            if (!EquipmentReady)
                cantConfirm += "- Control State must be 'REMOTE'";

            if (!ProcessStateReady)
                cantConfirm += "- Process State must be 'READY'";

            if (!string.IsNullOrEmpty(cantConfirm))
            {
                cantConfirm = "Confirmation cannot proceed until errors are fixed: " + newline + cantConfirm;
                var vm = new DialogViewModel(cantConfirm, "", "Ok");
                result = dialogService.ShowDialog(vm);
                return;
            }

            if (CurrentToolConfig.Dialogs.ShowConfirmationBox)
            {
                var vm = new DialogViewModel("Are you sure you want to Confirm this lot?", "Yes", "No");
                result = dialogService.ShowDialog(vm);
            }
            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                // 2/22 Check if equipment is ready first
                // TODO: 
                //if (currentTool.ReadyToStart())
                {
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Moving in wafers in Camstar..."));
                    // TimerText = "Moving in wafers in Camstar...";
                    MoveInAfterConfirmAsync();
                }
            }
        }

        private async void MoveInAfterConfirmAsync()
        {
            try {
                await Task.Run(() => {
                    Messenger.Default.Send(new MoveInWafersMessage(thisPortNo));
                });               
            }
            catch (Exception ex) {
                MyLog.Error(ex, "MoveInWafersAsync()");
            }          
        }

        private async void moveInResponseMsgHandler(MoveInResponseMessage msg)
        {
            try
            {
                if (msg.PortNo != thisPortNo) return;

                if (msg.Result == true)
                {
                    //MoveInComplete = true;
                    Confirmed = true;
                    //StartTimers(StartTimerSeconds);
                    //Messenger.Default.Send(new StartLoadingWafersMessage(thisPortNo, false, ""));
                }
                else
                    Confirmed = false; 
            }
            finally
            {
                await Task.Delay(0).ContinueWith(_ =>
                {
                    Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));
                });
                //Messenger.Default.Send(new PromptToConfirmNextTabMessage(CurrentTab));
            }
        }

        private void cancelPort1CmdHandler()
        {
            if (string.IsNullOrEmpty(Port1Lot1) && string.IsNullOrEmpty(Port1Lot2)) return; 

            var vm = new DialogViewModel("Are you sure you want to Cancel?", "Yes", "No");

            bool? result = dialogService.ShowDialog(vm);
            if (result.HasValue && result == true)
            {                 
                Messenger.Default.Send(new ReInitializeSystemMessage(1));
            }
        }

        private async void deleteLot1CmdHandler()
        {
            Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Processing..."));
            await Task.Delay(2000).ContinueWith(_ =>
            {
                Messenger.Default.Send(new DeleteLotMessage(thisPortNo, Port1Lot1));
                Port1Lot1 = "";
                Port1Lot1Color = "White";
                Lot1Enabled = true;
                Messenger.Default.Send(new ReFocusMessage("Lot1", null));
                Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));
            });            
        }

        private async void deleteLot2CmdHandler()
        {
            Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Processing..."));
            await Task.Delay(2000).ContinueWith(_ =>
            {
                Messenger.Default.Send(new DeleteLotMessage(thisPortNo, Port1Lot2));
                Port1Lot2 = "";
                Port1Lot2Color = "White";
                Lot2Enabled = true;
                Messenger.Default.Send(new ReFocusMessage("Lot2", null));
                Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, false, ""));
            }); 
        }

        #endregion

        public void ReInitailize(int level = 0)
        {
//            if (level == 0)
//            {
//                OperatorID = "";
//                ToolID = "";
//            }
//#if DEBUG
//            // OperatorID = "Mike"; // "zahir.haque";
//            // ToolID = CurrentToolConfig.Toolid;
//#endif

            Port1Lot1 = Port1Lot2 = "";
            Port1Lot1Color = "White";
            Port1Lot2Color = "White";
            Confirmed = false;
            Lot1Enabled = Lot2Enabled = true;

            if (level == 0)
                Messenger.Default.Send(new ReFocusMessage("Reinit", null));
            else
                Messenger.Default.Send(new ReFocusMessage("OperatorField", null));
        }

    }
}
