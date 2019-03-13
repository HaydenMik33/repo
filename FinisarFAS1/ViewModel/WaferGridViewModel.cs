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
using System.Collections.ObjectModel;
using System.Linq;
using static Common.Globals;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using ToolService;
using System.Windows;
using System.Windows.Threading;

namespace FinisarFAS1.ViewModel
{
    public class WaferGridViewModel : ViewModelBase
    {
        private readonly IDialogService2 dialogService;
        //private MESService _mesService;
        SECSHandler<Tool> currentTool;
        const int MAXROWS = 25;

        DispatcherTimer dispatcherTimer = new DispatcherTimer();
        DispatcherTimer processingTimer = new DispatcherTimer();

        string factoryName = "Wafer";

        private int thisPortNo { get; set; }
        // TODO: Must be cleaned out when reinitialized
        string[] PortLots = new string[2];
        string Lot1 => PortLots[0]; 
        string Lot2 => PortLots[1];

        public WaferGridViewModel(int portNo)
        {
            IDialogService2 dialogService1 = new MyDialogService(null);
            dialogService1.Register<DialogViewModel, DialogWindow>();
            dialogService = dialogService1;
            //_mesService = new MESService();
            thisPortNo = portNo;
            RegisterForMessages();
        }

        public void RegisterForMessages()
        {
            Messenger.Default.Register<InitializeWafersMessage>(this, InitializeWafersHandler);
            Messenger.Default.Register<RenumberWafersMessage>(this, RenumberWafersHandler);
            Messenger.Default.Register<MoveWafersMessage>(this, MoveWafersHandler);

            Messenger.Default.Register<ProcessAbortMessage>(this, ProcessAbortMsgHandler);

            Messenger.Default.Register<ProcessCompletedMessage>(this, ProcessingCompleteMsgHandler);
            Messenger.Default.Register<EventMessage>(this, EventMessageHandler);

            Messenger.Default.Register<SetAllWafersStatusMessage>(this, setAllWafersStatusMsgHandler);
            //Messenger.Default.Register<RecipeOverridableMsg>(this, RecipeOverridableMsgHandler);

            Messenger.Default.Register<CurrentOperatorMessage>(this, updateOperatorMsgHandler);

            Messenger.Default.Register<MoveInResponseMessage>(this, moveInResponseHandler);
        }

        string _operatorID ; 
        AuthorizationLevel _authorizationLevel ; 

        private void updateOperatorMsgHandler(CurrentOperatorMessage msg)
        {
            this._operatorID = msg.OperatorID;
            this._authorizationLevel = msg.AuthLevel;
        }

        private void moveInResponseHandler(MoveInResponseMessage msg)
        {
            // If the lots moved in, then let's start this
            // TODO: 
            MoveInComplete = msg.Result;
            StartTimers(StartTimerSeconds);
        }

        //private void RecipeOverridableMsgHandler(RecipeOverridableMsg msg)
        //{
        //    IsRecipeOverridable = msg.IsRecipeOverridable;
        //}

        private void InitializeWafersHandler(InitializeWafersMessage msg)
        {
            _startTimerSeconds = CurrentToolConfig.StartTimerSeconds;

            RaisePropertyChanged(nameof(AreThereWafers));
            Port1Wafers = CreateEmptyPortRows();
            Started = false;
            IsProcessing = false;
            MoveInComplete = false;
            StartTimerSeconds = CurrentToolConfig.StartTimerSeconds;
            //StartTimerLeft = "";
            IsRecipeOverridable = false;
            ButtonEnabledIfOnline = true;
            PortLots = new string[2] { "", "" };
        }

        //private void WaferStatusMessageHandler(SetWaferStatusMessage msg)
        //{
        //    LotStatusColor = msg.LotStatusColor;
        //    Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, Port1Lot1, msg.WaferStatus));
        //    if (!string.IsNullOrEmpty(Port1Lot2))
        //        Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, Port1Lot2, msg.WaferStatus));
        //}

        private void ProcessAbortMsgHandler(ProcessAbortMessage msg)
        {
            Started = false;
            Aborted = true;
            IsProcessing = false;
            Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, "", "Aborted"));
            // UpdateWaferStatus("Aborted");
        }

        private void ProcessingCompleteMsgHandler(ProcessCompletedMessage msg)
        {
            // UpdateWaferStatus("Completed");
            Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, "", "Completed"));
            LotStatusColor = "Complete";
            Completed = true;            
        }
        private void EventMessageHandler(EventMessage msg)
        {
            if (msg.MsgType == "PM")
            {
                if (msg.Message.Contains("Processing"))
                {
                    //UpdateWaferStatus("In Processing");
                    Messenger.Default.Send(new SetAllWafersStatusMessage(thisPortNo, "", "Processing"));
                    LotStatusColor = "Processing";
                }
            }
        }
        private void MoveWafersHandler(MoveWafersMessage msg)
        {
            bool movedOne = false;
            int idxToMove = MAXROWS - msg.SlotToMove;
            Wafer mtWafer = new Wafer();
            // Remove top 1 if moving up
            int topIdx = 0;
            do
            {
                if (string.IsNullOrEmpty(Port1Wafers[topIdx].ContainerName))
                {
                    Port1Wafers.RemoveAt(topIdx);
                    movedOne = true;
                }
            } while (!movedOne && ++topIdx < idxToMove);
            if (movedOne)
            {
                Port1Wafers.Insert(idxToMove, mtWafer);
                RenumberWafersHandler(null);
                RaisePropertyChanged("Port1Wafers");
            }
        }

        private ObservableCollection<Wafer> CreateEmptyPortRows(int rowCount = MAXROWS)
        {
            ObservableCollection<Wafer> tempList = new ObservableCollection<Wafer>();
            // rowCount = 1; 
            for (int i = rowCount; i > 0; --i)
            {
                tempList.Add(new Wafer() { Slot = i.ToString() });
            }
            return tempList;
        }
        private List<Wafer> GetAscendingListOfWafersBySlot(List<Wafer> selectedWafers)
        {
            List<Wafer> orderedList;
            if (selectedWafers?.Count > 1)
                orderedList = selectedWafers.OrderBy(w => Int32.Parse(w.Slot)).Reverse().ToList();
            else
                orderedList = new List<Wafer>(selectedWafers);
            return orderedList;
        }

        bool doPortCheck = false;

        public int StartTimerSeconds { get; set; }



        #region Icommand+handler

        public ICommand MoveUpCmd => new RelayCommand(moveUpCmdHandler);
        public ICommand MoveDownCmd => new RelayCommand(moveDownCmdHandler);

        public ICommand AddEmptyRowCmd => new RelayCommand(addEmptyRowCmdHandler);
        public ICommand ConfirmPort1Cmd => new RelayCommand(confirmPort1CmdHandler);
        public ICommand CancelPort1Cmd => new RelayCommand(cancelPort1CmdHandler);

        public ICommand GoLocalCmd => new RelayCommand(goLocalCmdHandler);
        public ICommand GoRemoteCmd => new RelayCommand(goRemoteCmdHandler);

        public ICommand StartCmd => new RelayCommand(startCmdHandler);
        public ICommand StopCmd => new RelayCommand(stopCmdHandler);
        public ICommand PauseCmd => new RelayCommand(pauseCmdHandler);
        public ICommand ResumeCmd => new RelayCommand(resumeCmdHandler);
        public ICommand AbortCmd => new RelayCommand(abortCmdHandler);
        public ICommand CompleteCmd => new RelayCommand(completeCmdHandler);

        public ICommand NextCmd => new RelayCommand(nextCmdHandler);
        public ICommand ReloadCmd => new RelayCommand(reloadCmdHandler);

        private void moveUpCmdHandler()
        {
            int? cnt = SelectedWafers?.Count;
            if (cnt == null || cnt <= 0) return;

            // Remove from list 
            List<Wafer> moveWafers = GetAscendingListOfWafersBySlot(SelectedWafers);

            if (moveWafers[0].Slot != "25")
            {
                moveWafers.ForEach(wafer =>
                {
                    Port1Wafers.Remove(wafer);
                    Port1Wafers.Insert(MAXROWS - Int32.Parse(wafer.Slot) - 1, wafer);
                });
                RenumberWafersHandler(null);
                Messenger.Default.Send(new SelectedWafersInGridMessage(moveWafers));
            }
        }
        private void moveDownCmdHandler()
        {
            int? cnt = SelectedWafers?.Count;
            if (cnt == null || cnt <= 0) return;

            // Remove from list 
            List<Wafer> moveWafers = GetAscendingListOfWafersBySlot(SelectedWafers);
            if (moveWafers.Last().Slot == "1")
                return;

            moveWafers.Reverse();
            moveWafers.ForEach(wafer =>
            {
                Port1Wafers.Remove(wafer);
                Port1Wafers.Insert(MAXROWS - Int32.Parse(wafer.Slot) + 1, wafer);
            });


            RenumberWafersHandler(null);
            Messenger.Default.Send(new SelectedWafersInGridMessage(moveWafers));
        }
        private void addEmptyRowCmdHandler()
        {
            int? cnt = SelectedWafers?.Count;
            if (cnt == null || cnt <= 0) return;

            // Remove from list 
            List<Wafer> moveWafers = GetAscendingListOfWafersBySlot(SelectedWafers);

            if (moveWafers[0].Slot != "25")
            {
                moveWafers.ForEach(wafer =>
                {

                    Messenger.Default.Send(new MoveWafersMessage(wafer));
                });
            }
        }
        private void cancelPort1CmdHandler()
        {
            var vm = new DialogViewModel("Are you sure you want to Cancel?", "Yes", "No");

            bool? result = dialogService.ShowDialog(vm);
            if (result.HasValue && result == true)
            {
                Messenger.Default.Send(new ReInitializeSystemMessage(1));
            }
        }

        public void completeCmdHandler()
        {
            Messenger.Default.Send(new ReInitializeSystemMessage(0));
        }

        private void stopCmdHandler()
        {
            StopTimer();
            MyLog.Information($"SECS->SendSECSStop()");
            currentTool.SendSECSStop();
            Started = false;
            IsProcessing = false;
            // TODO: Same as abort or not? 
            // Aborted = true; 
            //HoldWafers("Aborted by: " + OperatorID);
            //UpdateWaferStatus("Aborted");
        }
        private void confirmPort1CmdHandler()
        {
            bool? result = true;
            if (CurrentToolConfig.Dialogs.ShowConfirmationBox)
            {
                var vm = new DialogViewModel("Are you sure you want to Confirm these lots?", "Yes", "No");
                result = dialogService.ShowDialog(vm);
            }

            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                // TODO: MoveIn
                // Change to MoveInMessage w/ Response 
                if (true) //MoveInWafers())
                {
                    MoveInComplete = true;
                    Confirmed = true;
                    StartTimers(StartTimerSeconds);
                }
                //else
                //    Messenger.Default.Send(new ReFocusMessage("Lot1", null));
            }
            else
            {

            }
        }
        private void startTimerExpiredHandler()
        {
            StopTimer();
            var vm = new DialogViewModel("The timer has expired to press Start. This lot will be placed onHold in Camstar now.", "", "Ok");
            bool? result = dialogService.ShowDialog(vm);
            // HoldWafers("Start Timer ran out by: "+ OperatorID);

            //emailViewHandler("Start Timer expired");
            Messenger.Default.Send(new ReInitializeSystemMessage(0));
        }

        private void startCmdHandler()
        {
            // Can use something like idx = CurrentTab (prob s/b CurrentTabIndex)
            string port = CurrentToolConfig.Loadports[0];
            string startMessage = "Do you want to start the other port as well?";

            StopTimer();
            bool? result = true;

            //if (!string.IsNullOrEmpty(CurrentToolConfig.Dialogs.PostStartmessage))
            if (!string.IsNullOrEmpty(startMessage))
            {
                var vm = new DialogViewModel(startMessage, "Yes", "No");
                result = dialogService.ShowDialog(vm);
            }

            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                string[] lotIds;

                if (!string.IsNullOrEmpty(Lot2))
                    lotIds = new string[] { Lot1, Lot2 };
                else
                    lotIds = new string[] { Lot1 };

                // TODO: 
                LoadingWafers = ToolBusy = true;
                TimerText = "Starting PreProcessing for Equipment...";
#if TIMERALL
                Task.Delay(5000).ContinueWith(_ =>
                {
                    ToolBusy = false;
                    Started = true;
                    IsProcessing = true; 
                });
#endif
                StartToolAsync(port, lotIds);
            }
            else
            {

            }
#if DEBUG1
            processingTimer.Tick += new EventHandler(newStageEvent);
            processingTimer.Interval = new TimeSpan(0, 0, 0, 10, 200);
            nextStep = 0;
            processingTimer.Start();
#endif
        }

        private bool toolBusy;
        public bool ToolBusy {
            get { return toolBusy; }
            set { toolBusy = value; RaisePropertyChanged(nameof(ToolBusy)); }
        }

        private string timerText;
        public string TimerText {
            get { return timerText; }
            set { timerText = value; RaisePropertyChanged(nameof(TimerText)); }
        }


        private void pauseCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSPause()");
            currentTool.SendSECSPause();
            Paused = true;
            //Started = false;
            IsProcessing = false;
        }
        private void resumeCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSResume()");
            currentTool.SendSECSResume();
            Paused = false;
            //Started = true;
            IsProcessing = true;
        }
        private void nextCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSNext()", true);
            currentTool.SendSECSNext();
            Paused = false;
            IsProcessing = true;
        }
        private void reloadCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSReload()", true);
            currentTool.SendSECSReload();
            Paused = false;
            IsProcessing = true;
        }
        private void abortCmdHandler()
        {
            StopTimer();
            var vm = new DialogViewModel("Are you sure you want to Abort?", "Yes", "No");
            bool? result = dialogService.ShowDialog(vm);
            if (result.HasValue && result.GetValueOrDefault() == true)
            {
                MyLog.Information($"SECS->SendSECSAbort()");
                currentTool.SendSECSAbort();
                // TODO: Review with Zahir if this os ok
                //Aborted = true;
                //Started = false;
                //IsProcessing = false;
                // HoldWafers("Aborted by: " + portLotInfo.OperatorID);
                // UpdateWaferStatus("Aborted");
                //ReInitializeSystem();
            }
            else
            {

            }
        }

        private void goLocalCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSGoLocal()");
            currentTool.SendSECSGoLocal();
            //Started = false;
            //IsProcessing = false;
            LocalMode = true;
            // Not setting awaiting equip status update ProcessState = "Local ONLY";
        }
        private void goRemoteCmdHandler()
        {
            MyLog.Information($"SECS->SendSECSGoRemote()");
            currentTool.SendSECSGoRemote();
            //Started = false;
            //IsProcessing = false; 
            LocalMode = false;
            // Not setting awaiting equip status update from tool ProcessState = "Remote Online";
        }

        private async void StartToolAsync(string port, string[] lotIds)
        {
            try
            {
                bool result = await Task.Run(() => StartToolProcessing(port, lotIds));
                if (result == true)
                {
                    Started = true;
                    IsProcessing = true;
                }
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "StartToolAsync()");
            }
            finally
            {
                LoadingWafers = ToolBusy = false;
            }
        }


        private bool StartToolProcessing(string port, string[] lotIds)
        {
            bool success = false;
            bool? result = true;
            string errMessage = "";
            bool yesRetry = false;
            int numTry = 1;

            MyLog.Information($"START TOOL PROCESSING for Port:{port}");
            if (lotIds.Length == 1)
                MyLog.Information($"START TOOL PROCESSING for Lot Id:{lotIds[0]}");
            else
                MyLog.Information($"START TOOL PROCESSING for Lot Id:{lotIds[0]} AND Lot Id:{lotIds[1]}");

            do
            {
                MyLog.Information($"SECS->DoPreProcessing #{numTry}");
                success = currentTool.DoPreprocessing();
                MyLog.Information($"SECS->DoPreProcessing returned {success}");
            } while (!success && ++numTry < 4);

            // System.Threading.Thread.Sleep(2000);

            numTry = 1;
            TimerText = "Sending RecipeSelection to Equipment...";
            do
            {
                MyLog.Information($"SECS->DoRecipeSelection({port}, Lot1:{Lot1} and Lot2:{Lot2}, {CurrentRecipe}, {_operatorID})", true);
                success = currentTool.DoRecipeSelection(port, lotIds, CurrentRecipe, _operatorID, out errMessage);
                MyLog.Information($"SECS->DoRecipeSelection returned {success}:errMessage={errMessage}");
                if (!success)
                {
                    yesRetry = false;
                    var vm = new DialogViewModel($"Error in DoRecipeSelection(). {errMessage}.", "Retry", "Cancel");
                    result = dialogService.ShowDialog(vm);
                    if (result.HasValue)
                        yesRetry = result.GetValueOrDefault();
                }
            } while (!success && ++numTry < 4 && yesRetry == true);

            if (success)
            {
                numTry = 1;
                TimerText = "Sending StartProcessing to Equipment...";
                do
                {
                    MyLog.Information($"SECS->DoStartProcessing({port}, Lot1:{Lot1} and Lot2:{Lot2}, {CurrentRecipe}, {_operatorID})", true);
                    success = currentTool.DoStartProcessing(port, lotIds, CurrentRecipe, _operatorID, out errMessage);
                    MyLog.Information($"SECS->DoStartProcessing returned {success}:errMessage={errMessage}");
                    if (!success)
                    {
                        yesRetry = false;
                        var vm = new DialogViewModel($"Error in DoStartProcessing(). {errMessage}.", "Retry", "Cancel");
                        result = dialogService.ShowDialog(vm);
                        if (result.HasValue)
                            yesRetry = result.GetValueOrDefault();
                    }
                } while (!success && ++numTry < 4 && yesRetry == true);
            }
            return success;
        }



        #endregion

        #region Timer
        private int startTimerLeft;
        private string _startTimerLeft = "";
        public string StartTimerLeftText {
            get {
                if (!string.IsNullOrWhiteSpace(_startTimerLeft))
                    return "(" + _startTimerLeft + ")";
                else
                    return "";
            }
            set { _startTimerLeft = value; RaisePropertyChanged(nameof(StartTimerLeftText)); }
        }
        public string StartTimerLeft {
            get {
                if (!string.IsNullOrWhiteSpace(_startTimerLeft))
                    return "(" + _startTimerLeft + ")";
                else
                    return "";
            }
            set { _startTimerLeft = value; RaisePropertyChanged(nameof(StartTimerLeft)); }
        }
        private void StopTimer()
        {
            dispatcherTimer.Stop();
            dispatcherTimer.Tick -= new EventHandler(startTimer_Tick);
            StartTimerLeft = "";
        }
        private void startTimer_Tick(object sender, EventArgs e)
        {
            --startTimerLeft;
            if (startTimerLeft <= 0)
            {
                StopTimer();
                startTimerExpiredHandler();
            }
            else
            {
                StartTimerLeft = startTimerLeft.ToString();
            }
        }
        private void StartTimers(int seconds)
        {
            if (seconds > 0)
            {
                dispatcherTimer.Tick += new EventHandler(startTimer_Tick);
                dispatcherTimer.Interval = new TimeSpan(0, 0, 1);
                startTimerLeft = seconds;
                StartTimerLeft = seconds.ToString();
                dispatcherTimer.Start();
            }
        }
        private int _startTimerSeconds;
        #endregion

        #region UI BINDINGS

        private bool _timeToProcess;
        public bool MoveInComplete {
            get { return _timeToProcess; }
            set {
                _timeToProcess = value;
                RaisePropertyChanged(nameof(MoveInComplete));
                Messenger.Default.Send(new WafersConfirmedMessage(value && AreThereWafers));
            }
        }

        private bool _confirmed;
        public bool Confirmed {
            get { return _confirmed; }
            set {
                _confirmed = value;
                RaisePropertyChanged(nameof(Confirmed));
                // RaisePropertyChanged(nameof(IsStoppable));
            }
        }

        private bool _started;
        public bool Started {
            get { return _started; }
            set {
                _started = value;
                RaisePropertyChanged(nameof(Started));
                RaisePropertyChanged(nameof(IsStoppable));
            }
        }

        private bool _paused;
        public bool Paused {
            get { return _paused; }
            set {
                _paused = value;
                RaisePropertyChanged(nameof(Paused));
                RaisePropertyChanged(nameof(IsStoppable));
            }
        }

        private bool _aborted;
        public bool Aborted {
            get { return _aborted; }
            set {
                _aborted = value;
                RaisePropertyChanged(nameof(Aborted));
                // RaisePropertyChanged(nameof(IsStoppable));
            }
        }

        private bool _completed;
        public bool Completed {
            get { return _completed; }
            set { _completed = value; RaisePropertyChanged(nameof(Completed)); }
        }

        private bool _isProcessing;
        public bool IsProcessing {
            get { return _isProcessing; }
            set {
                _isProcessing = value;
                RaisePropertyChanged(nameof(IsProcessing));
                // RaisePropertyChanged(nameof(IsStoppable));
            }
        }

        private bool _ButtonEnabledIfOnline;
        public bool ButtonEnabledIfOnline {
            get { return _ButtonEnabledIfOnline; }
            set {
                _ButtonEnabledIfOnline = value;
                RaisePropertyChanged(nameof(ButtonEnabledIfOnline));
            }
        }

        private bool _localMode;
        public bool LocalMode {
            get { return _localMode; }
            set {
                _localMode = value;
                RaisePropertyChanged(nameof(LocalMode));
                RaisePropertyChanged(nameof(IsLocal));
                ButtonEnabledIfOnline = !value;
                RaisePropertyChanged(nameof(ButtonEnabledIfOnline));
            }
        }

        private bool _isRecipeOverridable;
        public bool IsRecipeOverridable {
            get { return _isRecipeOverridable; }
            set {
                _isRecipeOverridable = value;
                RaisePropertyChanged(nameof(IsRecipeOverridable));
            }
        }

        public bool IsLocal => LocalMode;
        public bool IsStoppable => Started;
        public bool AreThereWafers {
            get {
                if (Port1Wafers == null || Port1Wafers.Count == 0)
                {
                    return false;
                }
                else
                {
                    for (int i = 0; i < MAXROWS; ++i)
                    {
                        if (!string.IsNullOrEmpty(port1Wafers[i].WaferNo))
                        {
                            return true;
                        }
                    }
                }
                return false;
            }
        }

        //private bool CheckWafers(List<Wafer> wafers, ref string errstring)
        //{
        //    bool readywafers = true;

        //    return readywafers;
        //}

        public List<Wafer> SelectedWafers { get; set; }

        private ObservableCollection<Wafer> port1Wafers;
        public ObservableCollection<Wafer> Port1Wafers {
            get { return port1Wafers; }
            set {
                port1Wafers = value;
                RaisePropertyChanged(nameof(Port1Wafers));
            }
        }        
     

        private bool _loadingWafers;
        public bool LoadingWafers {
            get { return _loadingWafers; }
            set { _loadingWafers = value; RaisePropertyChanged(nameof(LoadingWafers)); }
        }
        #endregion

        #region GRID MANIPULATION
        //  GRID MANIPULATION
        private void AddWafersToTopGrid(List<Wafer> wafers)
        {
            ObservableCollection<Wafer> currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
            ObservableCollection<Wafer> goodList = new ObservableCollection<Wafer>();
            ObservableCollection<Wafer> bottomList = new ObservableCollection<Wafer>();
            int slotNo = 0;

            // Find first top index
            int topIdx = 0;
            for (int i = 0; i < MAXROWS; ++i)
            {
                if (!string.IsNullOrEmpty(currentWafers[i].WaferNo))
                {
                    topIdx = i;
                    break;
                }
            }

            // Copy good rows to goodList
            if (topIdx > 0)
            {
                for (int i = topIdx; i < MAXROWS; ++i)
                {
                    bottomList.Add(currentWafers[i]);
                }
            }

            int newListCount = wafers.Count;

            if (topIdx - newListCount < 0)
            {
                var vm = new DialogViewModel("There are too many new wafers to add to current list. Continue?", "Yes", "No");

                bool? result = dialogService.ShowDialog(vm);
                if (result.HasValue && result.GetValueOrDefault() == true)
                {
                }
                Port1Wafers = currentWafers;
                RenumberWafersHandler(null);
                Port1Lot2 = "";
                return;
            }

            // Set currentWafers to goodList and
            Port1Wafers = new ObservableCollection<Wafer>(wafers);

            // Add currentwafers to bottom then add in empty then renumber slots
            foreach (var tempwafer in bottomList)
            {
                Port1Wafers.Add(tempwafer);
            }

            // Add in empty slots at top
            slotNo = Port1Wafers.Count;
            for (int i = MAXROWS - slotNo; i > 0; --i)
            {
                Port1Wafers.Insert(0, new Wafer());
            }

            RenumberWafersHandler(null);
        }

        

        private void AddWafersToGridMsgHandler(AddWafersToGridMessage msg)
        {
            List<Wafer> wafersToBeAdded = msg.listWafers;
            ObservableCollection<Wafer> currentWafers;
            int slotNo = 0;

            if (msg.PortNo != thisPortNo) return;

            try
            {
                currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
                var goodList = currentWafers.ToList().Where(w => !string.IsNullOrEmpty(w.WaferNo));
                currentWafers = new ObservableCollection<Wafer>(goodList);

                Port1Wafers = new ObservableCollection<Wafer>(wafersToBeAdded);

                // Add currentwafers to bottom then add in empty then renumber slots
                foreach (var tempwafer in currentWafers)
                {
                    Port1Wafers.Add(tempwafer);
                }

                // Add in empty slots at top
                slotNo = Port1Wafers.Count;
                for (int i = MAXROWS - slotNo; i > 0; --i)
                {
                    Port1Wafers.Insert(0, new Wafer());
                }

                RaisePropertyChanged(nameof(AreThereWafers));
                RenumberWafersHandler(null);
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "AddWafersToGrid()");
            }
        }

        private void RenumberWafersHandler(RenumberWafersMessage msg)
        {
            ObservableCollection<Wafer> currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
            for (int i = MAXROWS - 1, idx = 0; i >= 0; --i, ++idx)
            {
                string newSlot = (i + 1).ToString();
                currentWafers[idx].Slot = newSlot;
            }
            Port1Wafers = new ObservableCollection<Wafer>(currentWafers);
        }

        private string _port1Lot1;
        public string Port1Lot1 {
            get { return _port1Lot1; }
            set {
                _port1Lot1 = value;
                RaisePropertyChanged(nameof(Port1Lot1));
            }
        }

        private string _port1Lot2;
        public string Port1Lot2 {
            get { return _port1Lot2; }
            set {
                _port1Lot2 = value;
                RaisePropertyChanged(nameof(Port1Lot2));
            }
        }
   
        //private void setAllWafersStatusMsgHandler(SetAllWafersStatusMessage msg)
        //{
        //    if (doPortCheck && msg.Port != thisPortNo) return;
        private void SetAllWafersRecipe(string newRecipe)
        {
            ObservableCollection<Wafer> currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
            for (int i = 0; i < currentWafers.Count; ++i)
            {
                var cw = currentWafers[i];
                if (!string.IsNullOrEmpty(cw.ContainerName))
                    cw.Recipe = newRecipe;
            }
            Port1Wafers = new ObservableCollection<Wafer>(currentWafers);
        }

        private void setAllWafersStatusMsgHandler(SetAllWafersStatusMessage msg)
        {
            if (doPortCheck && msg.Port != thisPortNo) return;

            bool setOne = false;
            string lotId = msg.LotId;
            string newWaferStatus = msg.WaferStatus;

            ObservableCollection<Wafer> currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
            for (int i = 0; i < currentWafers.Count; ++i)
            {
                var cw = currentWafers[i];
                if (!string.IsNullOrEmpty(cw.WaferNo) &&
                        !string.IsNullOrEmpty(cw.ContainerName) &&
                        !cw.Status.Contains("Completed"))
                {
                    if (  string.IsNullOrEmpty(lotId) ||
                        (!string.IsNullOrEmpty(lotId) && cw.ContainerName.Equals(lotId)))
                    {
                        cw.Status = newWaferStatus;
                        setOne = true;
                    }
                }
            }
            // TODO: 
            if (setOne)
            {
              //   TabProcessingColor = waferStatus;
            }
            Port1Wafers = new ObservableCollection<Wafer>(currentWafers);
            LotStatusColor = newWaferStatus;
        }

        //private void UpdateWaferStatus(string newStatus)
        //{
        //    string testStatus = newStatus.ToUpper();
        //    ObservableCollection<Wafer> currentWafers = new ObservableCollection<Wafer>(Port1Wafers);
        //    for (int i = 0; i < currentWafers.Count; ++i)
        //    {
        //        if (!string.IsNullOrEmpty(currentWafers[i].WaferNo) && !currentWafers[i].Status.Contains("Completed"))
        //        {
        //            if (testStatus.Contains("ABORT"))
        //                currentWafers[i].Status += "-" + newStatus;
        //            else
        //                currentWafers[i].Status = newStatus;
        //        }
        //    }
        //    Port1Wafers = new ObservableCollection<Wafer>(currentWafers);
        //}

        private void deleteLotMsgHandler(DeleteLotMessage msg)
        {
            if (doPortCheck && msg.PortNo != thisPortNo) return;

            var goodLotList = Port1Wafers.Where(w => !string.IsNullOrEmpty(w.ContainerName) && !w.ContainerName.Equals(msg.LotToDelete)).ToList();
            Port1Wafers = new ObservableCollection<Wafer>();
            AddWafersToGridMsgHandler(new AddWafersToGridMessage(msg.PortNo, goodLotList.ToList()));
        }

        #endregion

        private string _lotStatusColor;
        public string LotStatusColor {
            get { return _lotStatusColor; }
            set {
                string processingStep = value;
                _lotStatusColor = Globals.GetColor(processingStep);
                RaisePropertyChanged(nameof(LotStatusColor));
            }
        }

        #region OPERATOR VIEW 
        private string _operation;
        public string CurrentOperation {
            get { return _operation; }
            set { _operation = value; RaisePropertyChanged(nameof(CurrentOperation)); }
        }

        private string _currentRecipe;
        public string CurrentRecipe {
            get { return _currentRecipe; }
            set {
                if (_currentRecipe != value)
                {
                    // Change recipe no matter what
                    _currentRecipe = value;
                    // TODO: Is this correct?
                    // Only change wafer recipes if the length is > 3
                    if (!string.IsNullOrEmpty(value) && value.Length > 3)
                    {
                        SetAllWafersRecipe(value);
                    }
                    else
                    {
                        // TODO: Bad recipe dialog?
                    }
                }
                RaisePropertyChanged("CurrentRecipe");
            }
        }

        private string _recipe;
        public string Recipe {
            get { return _recipe; }
            set { _recipe = value; RaisePropertyChanged(nameof(Recipe)); }
        }

        private string _product;
        public string Product {
            get { return _product; }
            set { _product = value; RaisePropertyChanged(nameof(Product)); }
        }

        private string _comment;
        public string Comments {
            get { return _comment; }
            set { _comment = value; RaisePropertyChanged(nameof(Comments)); }
        }

        private string _step;
        public string Step {
            get { return _step; }
            set { _step = value; RaisePropertyChanged(nameof(Step)); }
        }

        private string _spec;
        public string Spec {
            get { return _spec; }
            set { _spec = value; RaisePropertyChanged(nameof(Spec)); }
        }

        private string _field6;
        public string Field6 {
            get { return _field6; }
            set { _field6 = value; RaisePropertyChanged(nameof(Field6)); }
        }

        #endregion

        private async void ReInitializeSystemHandler(ReInitializeSystemMessage msg)
        {
            Messenger.Default.Send(new LoadingWafersMessage(thisPortNo, true, "Processing..."));
            //await Task.Run(() =>
            await Task.Delay(2000).ContinueWith(_ =>
            {
                Port1Wafers = CreateEmptyPortRows();

                MoveInComplete = false;
                if (dispatcherTimer.IsEnabled)
                    StopTimer();
                StartTimerLeftText = "";
                Completed = false;
                Aborted = Paused = Started = false;

                CurrentRecipe = "";

                RaisePropertyChanged(nameof(AreThereWafers));
                LoadingWafers = false;

            });
        }
    }

}
