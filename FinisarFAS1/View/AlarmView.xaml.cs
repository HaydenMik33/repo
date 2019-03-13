using Common;
using GalaSoft.MvvmLight.Messaging;
using System;
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;

namespace FinisarFAS1.View
{
    /// <summary>
    /// Interaction logic for UserControl1.xaml
    /// </summary>
    public partial class AlarmView : UserControl
    {
        public ObservableCollection<LogEntry> AlarmEntries { get; set; }

        public AlarmView()
        {
            InitializeComponent();

            DataContext = AlarmEntries = new ObservableCollection<LogEntry>();

            Messenger.Default.Register<EventMessage>(this, AddAlarmEntry);
        }

        private void AddAlarmEntry(EventMessage msg)
        {
            LogEntry alarm = new LogEntry() { EventDateTime = msg.MsgDateTime, EventType = msg.MsgType, Message = msg.Message };
            if (msg.MsgType == "A")
            {
                int len = msg.Message.Length > 80 ? 80 : msg.Message.Length;
                string s = msg.Message.Substring(0, len);
                alarm.Message = "ALARM:" + s;
                Dispatcher.BeginInvoke((Action)(() =>
                {
                    AlarmEntries.Add(alarm);
                    Alarms.UpdateLayout();
                }));
            }
        }

        private void CloseAlarm_Click(object sender, RoutedEventArgs e)
        {
            Messenger.Default.Send(new ToggleAlarmViewMessage(false));
        }

        private void Alarms_IsVisibleChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if((bool)e.NewValue ==true)
            {
                if (Alarms.Items.Count > 0)
                {
                    Alarms.Items.MoveCurrentToLast();
                    Alarms.ScrollIntoView(Alarms.Items.CurrentItem);
                }
            }
        }
    }
}
