using Common;
using FinisarFAS1.ViewModel;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for KoyoMain.xaml
    /// </summary>
    public partial class KoyoMain : Window
    {
        //Found this code on internet to remove the Windows title bar close button.
        //Uses System.Windows.Interop and System.Runtime.Interopservices
        //Another call is made in Window_Loaded()
        private const int GWL_STYLE = -16;
        private const int WS_SYSMENU = 0x80000;
        [DllImport("user32.dll", SetLastError = true)]
        private static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")]
        private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        public KoyoMain()
        {
            //this.Height = (System.Windows.SystemParameters.PrimaryScreenHeight * 0.75);
            //this.Width = (System.Windows.SystemParameters.PrimaryScreenWidth * 0.75);

            InitializeComponent();

            Messenger.Default.Register<ToggleAlarmViewMessage>(this, ShowAlarmViewMsg);
            Messenger.Default.Register<ToggleLogViewMessage>(this, ShowLogViewMsg);
            Messenger.Default.Register<EngineerViewMessage>(this, EngineerViewMsgHandler);
        }

        private void EngineerViewMsgHandler(EngineerViewMessage msg)
        {
            //if (msg.Engineer)
            //    TabEng.IsSelected = true;
            //else
            //    TabPort1.IsSelected = true; 
        }

        private void TextBox_KeyUp(object sender, KeyEventArgs e)
        {
            var uie = e.OriginalSource as UIElement;

            if (e.Key == Key.Enter)
            {
                e.Handled = true;
                uie.MoveFocus(new TraversalRequest(FocusNavigationDirection.Next));
            }
        }

        private void TextBox_GotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {
            var box = sender as TextBox;
            if (box != null)
            {
                //box.Background = Brushes.LightSkyBlue;
                //box.BorderBrush = Brushes.Blue;
                //box.BorderThickness = new Thickness { Left = 3, Right = 3, Top = 3, Bottom = 3 };
                box.SelectAll();
            }
        }

        private void TextBox_LostKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {
            TextBox box = e.Source as TextBox;

            if (box != null)
            {
                // Change the TextBox color when it loses focus.
                //box.Background = Brushes.White;
                //box.BorderBrush = Brushes.Black;
                //box.BorderThickness = new Thickness { Left = 1, Right = 1, Top = 1, Bottom = 1 };
            }
        }


        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            //this.BeginStoryboard((Storyboard)this.Resources["collapseEntry"]);
            this.BeginStoryboard((Storyboard)this.Resources["expandAlarm"]);
            this.BeginStoryboard((Storyboard)this.Resources["collapseAlarm"]);

            //Found this code on internet to remove the Windows title bar close button.
            var hwnd = new WindowInteropHelper(this).Handle;
            SetWindowLong(hwnd, GWL_STYLE, GetWindowLong(hwnd, GWL_STYLE) & ~WS_SYSMENU);
            
            Messenger.Default.Send(new InitializeSystemMessage());

            Button_Click(PortA, null);
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            // Messenger.Default.Send(new CancelTransactionMessage());
        }

        static bool alarmOut = false;
        static bool logOut = false;

        private void ShowAlarmViewMsg(ToggleAlarmViewMessage msg)
        {
            alarmOut = !alarmOut;
            if (alarmOut)
            {
                if (logOut)
                    ShowLogViewMsg(new ToggleLogViewMessage(false));
                alarmPanel.Visibility = Visibility.Visible;
            }
            else
            {
                alarmPanel.Visibility = Visibility.Collapsed;
            }
        }

        private void ShowLogViewMsg(ToggleLogViewMessage msg)
        {
            logOut = !logOut;
            if (logOut)
            {
                if (alarmOut)
                    ShowAlarmViewMsg(new ToggleAlarmViewMessage(false));
                logPanel.Visibility = Visibility.Visible;
            }
            else
            {
                logPanel.Visibility = Visibility.Collapsed;
            }
        }

        private void TextBlock_MouseUp(object sender, MouseButtonEventArgs e)
        {
            FrameworkElement fe = sender as FrameworkElement;
            ((MainViewModel)fe.DataContext).closeAlarmCmdHandler();
        }

        private void TextBox_PreviewGotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
        {           
        }

        Button currentPort = null;
        Brush cpBack, cpFore; 

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            Button port = sender as Button;

            if (port!=null)
            {
                if (currentPort==null)
                {
                    cpBack = port.Background;
                    cpFore = port.Foreground;
                    currentPort = port;
                    currentPort.Background = Brushes.Gray;
                    currentPort.Foreground = Brushes.White;
                }
                else
                if (port!=currentPort)
                {
                    currentPort.Background = cpBack;
                    currentPort.Foreground = cpFore; 
                    currentPort = port;
                    currentPort.Background = Brushes.Gray;
                    currentPort.Foreground = Brushes.White; 
                }
            }

        }
    }
}
