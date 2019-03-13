using Common;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Collections.ObjectModel;
using System.Windows.Controls;
using System.Windows;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for LogView.xaml
    /// </summary>
    public partial class LogView : UserControl
    {      
        public ObservableCollection<LogEntry> LogEntries { get; set; }

        public LogView()
        {
            InitializeComponent();          

            DataContext = LogEntries = new ObservableCollection<LogEntry>();          

            Messenger.Default.Register<EventMessage>(this, AddLogEntry);
        }

        private void AddLogEntry(EventMessage msg)
        {
            if (msg.MsgType == "A" || msg.MsgType == "L" || msg.MsgType == "E")
            {
                LogEntry logEntry = new LogEntry() { EventDateTime = msg.MsgDateTime, EventType = msg.MsgType, Message = msg.Message };

                if (msg.MsgType == "A")
                    logEntry.Message = "ALARM:" + logEntry.Message;
                else
                if (msg.MsgType == "E")
                    logEntry.Message = "CRITICAL ERROR:" + logEntry.Message;

                Dispatcher.BeginInvoke((Action)(() =>
                {
                    LogEntries.Add(logEntry);

                    Logs.UpdateLayout();
                }));
            }
        }

        private void CloseLog_Click(object sender, RoutedEventArgs e)
        {
            Messenger.Default.Send(new ToggleLogViewMessage(false));
        }

        private void Logs_IsVisibleChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if((bool)e.NewValue == true)
            {
                if (Logs.Items.Count > 0)
                {
                    Logs.Items.MoveCurrentToLast();
                    Logs.ScrollIntoView(Logs.Items.CurrentItem);
                }
            }
        }
    }
}
