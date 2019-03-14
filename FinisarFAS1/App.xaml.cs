using FinisarFAS1.Utility;
using FinisarFAS1.View;
using FinisarFAS1.ViewModel;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using static Common.Globals;

namespace FinisarFAS1
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        private readonly IDialogService2 dialogService;
        protected override void OnStartup(StartupEventArgs e)
        {
            string whichTool = "";
            //EventManager.RegisterClassHandler(typeof(TextBox), TextBox.KeyUpEvent, new KeyEventHandler(TextBox_HandleEnterKey));
            base.OnStartup(e);

            Dispatcher.UnhandledException += OnDispatcherUnhandledException;

            SplashScreen screen = new SplashScreen("Images/FINISAR_splash.png"); screen.Show(true);

            try
            {
                string q = e.Args[0].ToUpper();
                Common.Globals.UsingMoq = q == "MOQ";
                //whichTool = e.Args[1].ToUpper();
            }
            catch { }

            bool goodConfigFile = GetConfigurationValues();
            if (!goodConfigFile)
            {
                Application.Current.Shutdown();
                return;
            }

            var vm = new MainViewModel();
            whichTool = CurrentToolConfig.ToolType.ToUpper();

            if (whichTool == "KOYO")
            {
                var view = new KoyoMain { DataContext = vm };
                view.ShowDialog();
            }
            else 
            {
                var view = new MainWindow { DataContext = vm };
                view.ShowDialog();
            }
        }
        private bool GetConfigurationValues()
        {
            try
            {
                ReadXmlConfigs();
                return true;
            }
            catch (Exception e)
            {
                
                var vm = new DialogViewModel(e.Message + " Error reading config files ", "", "Ok");
                dialogService.ShowDialog(vm);

                return false;
            }

             
        }
        // On KeyDown
        //private void TextBox_HandleEnterKey(object sender, System.Windows.Input.KeyEventArgs e)
        //{
        //    var uie = e.OriginalSource as UIElement;

        //    if (e.Key == Key.Enter)
        //    {
        //        //e.Handled = true;
        //        //uie.MoveFocus(
        //        //    new TraversalRequest(
        //        //    FocusNavigationDirection.Next));
        //    }
        //}

        void OnDispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
        {
            var errorMsg = string.Format("An exception occurred:{0}", e.Exception.Message);
            MessageBox.Show(errorMsg, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            File.WriteAllText(AppDomain.CurrentDomain.BaseDirectory + "\\log.txt", e.Exception.StackTrace);
            e.Handled = true;
        }

        public App()
        {
            IDialogService2 dialogService1 = new MyDialogService(null);
            dialogService1.Register<DialogViewModel, DialogWindow>();
            dialogService = dialogService1;
        }

        //public void DisplayMainWindow()
        //{
        //    var mainVM = new ViewModel.MainViewModel();
        //    string v = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();
        //    var mainWindow = new MainWindow()
        //    {
        //        DataContext = mainVM,
        //        WindowStartupLocation = WindowStartupLocation.CenterScreen,
        //        Title = string.Format("Finisar Factory Automation System - {0}", v)
        //    };
        //    mainWindow.ShowDialog();
        //}
    }
}
